import os
from urllib.parse import urlsplit
from agent_framework import Agent
from agent_framework.openai import OpenAIChatClient
from agent_framework_foundry_hosting import ResponsesHostServer
from azure.identity.aio import (
    AzureCliCredential,
    ManagedIdentityCredential,
    get_bearer_token_provider,
)
from openai import AsyncOpenAI
GATEWAY_TOKEN_SCOPE = "https://azure-api.net/aigateway/.default"
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
    gateway = AsyncOpenAI(
        base_url=base_url.rstrip("/") + "/",
        api_key=token_provider,
        timeout=60.0,
        max_retries=2,
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
    server = ResponsesHostServer(agent=create_agent, history_source="agent_server")
    @server.shutdown_handler
    async def close_clients() -> None:
        await gateway.close()
        await credential.close()
    return server
if __name__ == "__main__":
    create_server().run()