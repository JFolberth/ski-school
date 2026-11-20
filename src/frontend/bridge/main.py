import logging
import os
import re
from contextlib import asynccontextmanager
from urllib.parse import urlsplit

import httpx
from azure.core.exceptions import AzureError
from azure.identity.aio import AzureCliCredential, ManagedIdentityCredential
from fastapi import FastAPI, Request
from fastapi.responses import JSONResponse
from pydantic import BaseModel, ConfigDict, Field, ValidationError

LOG = logging.getLogger("ski_school.bridge")
SCOPE = "https://ai.azure.com/.default"
MAX_REQUEST_BYTES = 24 * 1024
MODEL_METADATA_KEY = "ski_school_served_model"


class UpstreamError(Exception):
    pass


def responding_model(result: dict) -> str | None:
    metadata = result.get("metadata")
    if metadata is None:
        return None
    if not isinstance(metadata, dict):
        raise UpstreamError
    model = metadata.get(MODEL_METADATA_KEY)
    if model is None:
        return None
    if (
        not isinstance(model, str)
        or not 1 <= len(model) <= 512
        or not model.isascii()
        or any(character.isspace() or not character.isprintable() for character in model)
    ):
        raise UpstreamError
    return model


class Exchange(BaseModel):
    model_config = ConfigDict(extra="forbid", strict=True, str_strip_whitespace=True)
    user: str = Field(min_length=1, max_length=2000)
    assistant: str = Field(min_length=1)


class Message(BaseModel):
    model_config = ConfigDict(extra="forbid", strict=True, str_strip_whitespace=True)
    message: str = Field(min_length=1, max_length=2000)
    history: list[Exchange] = Field(default_factory=list, max_length=5)


@asynccontextmanager
async def lifespan(app: FastAPI):
    endpoint = os.environ.get("FOUNDRY_AGENT_BASE_URL", "")
    parsed = urlsplit(endpoint)
    if (
        endpoint != endpoint.strip()
        or parsed.scheme != "https"
        or not parsed.hostname
        or parsed.username is not None
        or parsed.password is not None
        or parsed.query
        or parsed.fragment
        or not parsed.path.rstrip("/").endswith("/endpoint/protocols/openai")
    ):
        raise ValueError("FOUNDRY_AGENT_BASE_URL must be an HTTPS agent OpenAI endpoint")
    mode = os.environ.get("BRIDGE_AUTH_MODE", "managed_identity")
    if mode == "managed_identity":
        credential = ManagedIdentityCredential()
    elif mode == "azure_cli" and not os.environ.get("CONTAINER_APP_NAME"):
        credential = AzureCliCredential()
    else:
        raise ValueError("BRIDGE_AUTH_MODE must be managed_identity or azure_cli")
    app.state.local = mode == "azure_cli"
    app.state.credential = credential
    app.state.client = httpx.AsyncClient(
        base_url=endpoint.rstrip("/") + "/",
        params={"api-version": "v1"},
        timeout=300.0,
    )
    try:
        yield
    finally:
        await app.state.client.aclose()
        await credential.close()


app = FastAPI(
    lifespan=lifespan,
    docs_url=None,
    redoc_url=None,
    openapi_url=None,
    telemetry={"tracing": False, "metrics": False, "logs": False, "auto_configure": False},
)


def response(data: dict, status: int = 200) -> JSONResponse:
    return JSONResponse(data, status_code=status, headers={"Cache-Control": "no-store"})


def check_origin(request: Request) -> bool:
    origin = request.headers.get("origin", "")
    try:
        parsed = urlsplit(origin)
        hostname = parsed.hostname
    except ValueError:
        return False
    return (
        (parsed.scheme == "https" or (
            app.state.local and parsed.scheme == "http" and hostname in ("localhost", "127.0.0.1")
        ))
        and parsed.netloc == request.headers.get("host")
        and not parsed.path
        and not parsed.query
        and not parsed.fragment
    )


async def generate(messages: list[dict[str, str]]) -> tuple[str, str | None]:
    result = None
    try:
        token = await app.state.credential.get_token(SCOPE)
        result = await app.state.client.post(
            "responses",
            headers={"Authorization": f"Bearer {token.token}"},
            json={"input": messages, "stream": False, "store": False},
        )
        result.raise_for_status()
        payload = result.json()
        if (
            not isinstance(payload, dict)
            or payload.get("status") != "completed"
            or not isinstance(payload.get("output"), list)
        ):
            raise UpstreamError
        parts = []
        for item in payload["output"]:
            if not isinstance(item, dict):
                raise UpstreamError
            if item.get("type") != "message":
                continue
            content = item.get("content")
            if not isinstance(content, list):
                raise UpstreamError
            parts.extend(part["text"] for part in content if isinstance(part, dict)
                         and part.get("type") == "output_text" and isinstance(part.get("text"), str))
        reply = "\n".join(parts)
        if not reply.strip():
            raise UpstreamError
        return reply, responding_model(payload)
    except (AzureError, httpx.HTTPError, ValueError, UpstreamError) as error:
        request_id = None
        if result is not None:
            for name in ("x-ms-request-id", "x-request-id", "apim-request-id"):
                candidate = result.headers.get(name, "")
                if re.fullmatch(r"[A-Za-z0-9_-]{1,128}", candidate):
                    request_id = candidate
                    break
        LOG.warning(
            "Foundry POST responses failed: status=%s request_id=%s error=%s",
            result.status_code if result is not None else None, request_id, type(error).__name__,
        )
        raise UpstreamError from None


@app.get("/healthz")
async def health():
    return {"status": "ok"}


@app.post("/api/messages")
async def send(request: Request):
    if not check_origin(request):
        return response({"error": "Request origin is not allowed."}, 403)
    if request.headers.get("content-type", "").split(";", 1)[0].strip().lower() != "application/json":
        return response({"error": "Send the message as JSON."}, 415)
    body = bytearray()
    async for chunk in request.stream():
        if len(body) + len(chunk) > MAX_REQUEST_BYTES:
            return response({"error": "The chat request is too large."}, 413)
        body.extend(chunk)
    try:
        message = Message.model_validate_json(body)
    except ValidationError:
        return response({"error": "The message or chat history is invalid."}, 422)

    messages = []
    for exchange in message.history:
        messages.extend((
            {"role": "user", "content": exchange.user},
            {"role": "assistant", "content": exchange.assistant},
        ))
    messages.append({"role": "user", "content": message.message})
    try:
        reply, model = await generate(messages)
    except UpstreamError:
        return response({"error": "The ski assistant is unavailable. Please try again."}, 503)
    return response({"reply": reply, "model": model})
