from __future__ import annotations

import asyncio
import os
from collections.abc import AsyncIterable, AsyncIterator, Awaitable, Callable
from contextvars import ContextVar
from dataclasses import dataclass
from inspect import isawaitable
from typing import TYPE_CHECKING, Any
from urllib.parse import urlsplit
from agent_framework import Agent
from agent_framework.openai import OpenAIChatClient
from agent_framework_foundry_hosting import ResponsesHostServer
from azure.ai.agentserver.responses import CreateResponse, ResponseContext
from azure.identity.aio import (
    AzureCliCredential,
    ManagedIdentityCredential,
    get_bearer_token_provider,
)
from openai import AsyncOpenAI, DefaultAsyncHttpxClient

if TYPE_CHECKING:
    from httpx2 import Response as ProviderResponse

GATEWAY_TOKEN_SCOPE = "https://azure-api.net/aigateway/.default"
MODEL_METADATA_KEY = "ski_school_served_model"
ResponseHandler = Callable[
    [CreateResponse, ResponseContext, asyncio.Event],
    AsyncIterable[Any] | Awaitable[AsyncIterable[Any]],
]


@dataclass
class ModelAttribution:
    model: str | None = None
    observed: bool = False

    def record(self, model: str | None) -> None:
        # Missing or conflicting attribution on any inference call stays unavailable.
        if not self.observed:
            self.model = model
            self.observed = True
        elif self.model != model:
            self.model = None


attribution: ContextVar[ModelAttribution | None] = ContextVar("model_attribution", default=None)


def annotate_response(event: Any, model: str | None) -> Any:
    if not isinstance(event, dict) or "response" not in event:
        return event
    body = event["response"]
    if not isinstance(body, dict):
        raise TypeError("Invalid Responses envelope.")
    metadata = body.get("metadata")
    if metadata is not None and not isinstance(metadata, dict):
        raise TypeError("Invalid Responses metadata.")
    metadata = dict(metadata or {})
    # Never accept attribution seeded by caller-supplied request metadata.
    metadata.pop(MODEL_METADATA_KEY, None)
    if event.get("type") == "response.completed" and model is not None and len(metadata) < 16:
        metadata[MODEL_METADATA_KEY] = model
    return {**event, "response": {**body, "metadata": metadata}}


class AttributingResponsesHostServer(ResponsesHostServer):
    def response_handler(self, fn: ResponseHandler) -> ResponseHandler:
        super().response_handler(fn)
        # Wrap through the public registrar; do not access the host's private handler.
        async def with_attribution(
            request: CreateResponse,
            context: ResponseContext,
            cancellation_signal: asyncio.Event,
        ) -> AsyncIterator[Any]:
            state = ModelAttribution()
            iterator = None
            try:
                while True:
                    token = attribution.set(state)
                    try:
                        if iterator is None:
                            stream = fn(request, context, cancellation_signal)
                            if isawaitable(stream):
                                stream = await stream
                            iterator = aiter(stream)
                        event = await anext(iterator)
                    except StopAsyncIteration:
                        return
                    finally:
                        # Do not leak context while the generator is suspended at yield.
                        attribution.reset(token)
                    yield annotate_response(event, state.model)
            finally:
                close = getattr(iterator, "aclose", None)
                if close is not None:
                    token = attribution.set(state)
                    try:
                        await close()
                    finally:
                        attribution.reset(token)

        super().response_handler(with_attribution)
        return fn


INSTRUCTIONS = """
You help people with skiing in Michigan only. Keep answers concise and distinguish
general skiing guidance from verified resort facts or current conditions.
No live weather or resort data sources are connected yet. Explicitly say current
conditions are unavailable when asked about them. Never invent resort facts,
snowfall, grooming, open lifts or trails, sources, observation times or freshness.
Weather observations and forecasts are not resort-reported skiing conditions.
Do not present user-supplied claims as independently verified facts.
"""
def required_setting(name: str) -> str:
    value = os.environ.get(name, "")
    if not value or value != value.strip():
        raise ValueError(f"{name} must be set and must not contain surrounding whitespace.")
    return value
def create_server() -> ResponsesHostServer:
    base_url = required_setting("AI_GATEWAY_BASE_URL")
    endpoint = urlsplit(base_url)
    if (
        endpoint.scheme != "https"
        or not endpoint.hostname
        or endpoint.username is not None
        or endpoint.password is not None
        or endpoint.query
        or endpoint.fragment
        or not endpoint.path.rstrip("/").endswith("/models/openai/v1")
    ):
        raise ValueError(
            "AI_GATEWAY_BASE_URL must be an HTTPS gateway model API base URL "
            "ending in /models/openai/v1/, without credentials, query or fragment."
        )
    model_alias = required_setting("AI_GATEWAY_MODEL_ALIAS")
    if any(character.isspace() for character in model_alias):
        raise ValueError("AI_GATEWAY_MODEL_ALIAS must not contain whitespace.")
    auth_mode = os.environ.get("BACKEND_AUTH_MODE", "managed_identity")
    if auth_mode == "managed_identity":
        credential = ManagedIdentityCredential()
    elif auth_mode == "azure_cli" and not (
        os.environ.get("FOUNDRY_HOSTING_ENVIRONMENT") or os.environ.get("FOUNDRY_PROJECT_ARM_ID")
    ):
        credential = AzureCliCredential()
    else:
        raise ValueError(
            "BACKEND_AUTH_MODE must be managed_identity; azure_cli is supported only locally."
        )
    # The hosting SDK otherwise enables message-content capture by default.
    os.environ["OTEL_INSTRUMENTATION_GENAI_CAPTURE_MESSAGE_CONTENT"] = "false"
    os.environ["ENABLE_SENSITIVE_DATA"] = "false"
    os.environ["APPLICATIONINSIGHTS_AUTH_MODE"] = "entra"
    token_provider = get_bearer_token_provider(credential, GATEWAY_TOKEN_SCOPE)

    async def observe_provider(response: ProviderResponse) -> None:
        state = attribution.get()
        if state is None:
            return
        if response.request.method != "POST" or not response.request.url.path.endswith("/responses"):
            return
        # The pinned MAF OpenAI client recognizes this provider served-model header.
        # Observe it only when actually returned; response.model may just be an alias.
        model = response.headers.get("x-ms-served-model")
        if (
            not 200 <= response.status_code < 300
            or not isinstance(model, str)
            or not 1 <= len(model) <= 512
            or not model.isascii()
            or any(character.isspace() or not character.isprintable() for character in model)
            or model in (model_alias, "michigan-skiing")
        ):
            model = None
        state.record(model)

    transport = DefaultAsyncHttpxClient(event_hooks={"response": [observe_provider]})
    gateway = AsyncOpenAI(
        base_url=base_url.rstrip("/") + "/",
        api_key=token_provider,
        timeout=60.0,
        max_retries=0,
        http_client=transport,
    )
    # Inject a client so ambient OPENAI_* / AZURE_OPENAI_* settings cannot reroute inference.
    client = OpenAIChatClient(model=model_alias, async_client=gateway)
    def create_agent() -> Agent:
        return Agent(
            client=client,
            name="michigan-skiing",
            instructions=INSTRUCTIONS,
            default_options={"store": False},
        )
    server = AttributingResponsesHostServer(agent=create_agent, history_source="agent_server")
    @server.shutdown_handler
    async def close_clients() -> None:
        await gateway.close()
        await credential.close()
    return server
if __name__ == "__main__":
    create_server().run()