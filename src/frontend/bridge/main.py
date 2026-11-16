import base64
import binascii
import hashlib
import hmac
import json
import logging
import os
import re
import time
from contextlib import asynccontextmanager
from urllib.parse import urlsplit

import httpx
from azure.core.exceptions import AzureError
from azure.identity.aio import AzureCliCredential, ManagedIdentityCredential
from fastapi import FastAPI, Request
from fastapi.responses import JSONResponse
from pydantic import BaseModel, ConfigDict, Field

LOG = logging.getLogger("ski_school.bridge")
SCOPE = "https://ai.azure.com/.default"
COOKIE = "__Host-ski-session"
LIFETIME = 24 * 60 * 60
CONVERSATION_ID = re.compile(r"^[A-Za-z0-9_-]{1,256}$")


def setting(name: str) -> str:
    value = os.environ.get(name, "")
    if not value or value != value.strip():
        raise ValueError(f"{name} must be set without surrounding whitespace")
    return value


def decode(value: str) -> bytes:
    return base64.urlsafe_b64decode(value + "=" * (-len(value) % 4))


def encode(value: bytes) -> str:
    return base64.urlsafe_b64encode(value).rstrip(b"=").decode("ascii")


def session_cookie(conversation_id: str, key: bytes) -> str:
    payload = encode(json.dumps(
        {"conversation": conversation_id, "activity": int(time.time())},
        separators=(",", ":"),
    ).encode())
    signature = encode(hmac.digest(key, payload.encode(), hashlib.sha256))
    return f"{payload}.{signature}"


def read_session(value: str | None, key: bytes) -> str | None:
    if not value:
        return None
    try:
        payload, signature = value.split(".")
        if not hmac.compare_digest(decode(signature), hmac.digest(key, payload.encode(), hashlib.sha256)):
            raise ValueError("invalid signature")
        data = json.loads(decode(payload))
        conversation_id = data["conversation"]
        activity = data["activity"]
        if (
            not isinstance(conversation_id, str)
            or not CONVERSATION_ID.fullmatch(conversation_id)
            or type(activity) is not int
            or not 0 <= time.time() - activity < LIFETIME
        ):
            raise ValueError("invalid session")
        return conversation_id
    except (ValueError, KeyError, TypeError, binascii.Error, UnicodeError, json.JSONDecodeError):
        raise SessionError from None


class SessionError(Exception):
    pass


class UpstreamError(Exception):
    pass


class Message(BaseModel):
    model_config = ConfigDict(extra="forbid")
    message: str = Field(min_length=1, max_length=2000)


@asynccontextmanager
async def lifespan(app: FastAPI):
    endpoint = setting("FOUNDRY_AGENT_BASE_URL")
    parsed = urlsplit(endpoint)
    if (
        parsed.scheme != "https"
        or not parsed.hostname
        or parsed.username is not None
        or parsed.password is not None
        or parsed.query
        or parsed.fragment
        or not parsed.path.rstrip("/").endswith("/endpoint/protocols/openai")
    ):
        raise ValueError("FOUNDRY_AGENT_BASE_URL must be an HTTPS agent OpenAI endpoint")
    try:
        key = decode(setting("SESSION_SIGNING_KEY"))
    except (ValueError, binascii.Error):
        raise ValueError("SESSION_SIGNING_KEY must be URL-safe base64") from None
    if len(key) < 32:
        raise ValueError("SESSION_SIGNING_KEY must decode to at least 32 bytes")
    mode = os.environ.get("BRIDGE_AUTH_MODE", "managed_identity")
    if mode == "managed_identity":
        credential = ManagedIdentityCredential()
    elif mode == "azure_cli" and not os.environ.get("CONTAINER_APP_NAME"):
        credential = AzureCliCredential()
    else:
        raise ValueError("BRIDGE_AUTH_MODE must be managed_identity or azure_cli")
    app.state.key = key
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


def response(data: dict, status: int = 200, conversation_id: str | None = None) -> JSONResponse:
    result = JSONResponse(data, status_code=status, headers={"Cache-Control": "no-store"})
    if conversation_id is not None:
        result.set_cookie(
            COOKIE, session_cookie(conversation_id, app.state.key),
            secure=True, httponly=True, samesite="strict", path="/",
        )
    return result


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


async def upstream(method: str, path: str, **kwargs) -> dict:
    try:
        token = await app.state.credential.get_token(SCOPE)
        result = await app.state.client.request(
            method, path, headers={"Authorization": f"Bearer {token.token}"}, **kwargs
        )
        result.raise_for_status()
        payload = result.json()
        if not isinstance(payload, dict):
            raise UpstreamError
        return payload
    except (AzureError, httpx.HTTPError, ValueError, UpstreamError) as error:
        LOG.warning("Foundry request failed (%s)", type(error).__name__)
        raise UpstreamError from None


@app.get("/healthz")
async def health():
    return {"status": "ok"}


@app.get("/api/conversation")
async def history(request: Request):
    try:
        conversation_id = read_session(request.cookies.get(COOKIE), app.state.key)
        if not conversation_id:
            return response({"messages": []})
        items = []
        cursor = None
        for _ in range(20):
            params = {"order": "asc", "limit": 100}
            if cursor:
                params["after"] = cursor
            page = await upstream("GET", f"conversations/{conversation_id}/items", params=params)
            data = page.get("data")
            if not isinstance(data, list) or not isinstance(page.get("has_more"), bool):
                raise UpstreamError
            for item in data:
                if not isinstance(item, dict):
                    raise UpstreamError
                if item.get("type") not in ("message", "output_message") or item.get("role") not in ("user", "assistant"):
                    continue
                content = item.get("content")
                if not isinstance(content, list):
                    raise UpstreamError
                parts = [part["text"] for part in content if isinstance(part, dict) and part.get("type") in ("input_text", "output_text") and isinstance(part.get("text"), str)]
                if parts:
                    items.append({"role": item["role"], "text": "\n".join(parts)})
            if not page["has_more"]:
                return response({"messages": items}, conversation_id=conversation_id)
            cursor = page.get("last_id")
            if not isinstance(cursor, str) or not cursor:
                raise UpstreamError
        return response({"error": "Conversation history exceeds the display limit."}, 413)
    except SessionError:
        return response({"error": "Your chat session expired or is invalid. Start a new chat."}, 401)
    except UpstreamError:
        return response({"error": "Conversation history is unavailable. Please try again."}, 503)


@app.post("/api/messages")
async def send(request: Request, message: Message):
    if not check_origin(request):
        return response({"error": "Request origin is not allowed."}, 403)
    text = message.message.strip()
    if not text:
        return response({"error": "Enter a message."}, 400)
    conversation_id = None
    try:
        conversation_id = read_session(request.cookies.get(COOKIE), app.state.key)
        if not conversation_id:
            created = await upstream("POST", "conversations", json={})
            new_id = created.get("id")
            if not isinstance(new_id, str) or not CONVERSATION_ID.fullmatch(new_id):
                raise UpstreamError
            conversation_id = new_id
        result = await upstream("POST", "responses", json={
            "input": text, "conversation": conversation_id, "stream": False,
        })
        if result.get("status") != "completed" or not isinstance(result.get("output"), list):
            raise UpstreamError
        parts = []
        for item in result["output"]:
            if not isinstance(item, dict):
                raise UpstreamError
            if item.get("type") != "message":
                continue
            content = item.get("content")
            if not isinstance(content, list):
                raise UpstreamError
            parts.extend(part["text"] for part in content if isinstance(part, dict)
                         and part.get("type") == "output_text" and isinstance(part.get("text"), str))
        if not parts:
            raise UpstreamError
        return response({"reply": "\n".join(parts)}, conversation_id=conversation_id)
    except SessionError:
        return response({"error": "Your chat session expired or is invalid. Start a new chat."}, 401)
    except UpstreamError:
        return response({"error": "The ski assistant is unavailable. Please try again."}, 503, conversation_id)


@app.post("/api/reset")
async def reset(request: Request):
    if not check_origin(request):
        return response({"error": "Request origin is not allowed."}, 403)
    try:
        conversation_id = read_session(request.cookies.get(COOKIE), app.state.key)
        if conversation_id:
            deleted = await upstream("DELETE", f"conversations/{conversation_id}")
            if deleted.get("deleted") is not True:
                raise UpstreamError
        result = response({"ok": True})
        result.delete_cookie(COOKIE, secure=True, httponly=True, samesite="strict", path="/")
        return result
    except SessionError:
        result = response({"ok": True})
        result.delete_cookie(COOKIE, secure=True, httponly=True, samesite="strict", path="/")
        return result
    except UpstreamError:
        return response({"error": "Could not delete the previous conversation. Please try again."}, 503)
