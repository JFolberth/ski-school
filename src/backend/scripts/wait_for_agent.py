import argparse
import re
import time
from collections.abc import Callable
from urllib.parse import quote, urlsplit

import httpx
from azure.identity import AzureCliCredential, get_bearer_token_provider


def smoke_test(
    client: httpx.Client, endpoint: str, version: str, token: Callable[[], str]
) -> None:
    # Pin a fresh session so a passing check cannot accidentally exercise the default version.
    session = client.post(
        f"{endpoint}/sessions?api-version=v1",
        headers={"Authorization": f"Bearer {token()}"},
        json={"version_indicator": {"type": "version_ref", "agent_version": version}},
        timeout=120,
    )
    session.raise_for_status()
    session_id = session.json().get("agent_session_id")
    if not isinstance(session_id, str) or not session_id:
        raise RuntimeError("Foundry did not return a pinned session ID.")
    response = client.post(
        f"{endpoint}/protocols/openai/responses?api-version=v1",
        headers={"Authorization": f"Bearer {token()}"},
        json={
            "agent_session_id": session_id,
            "input": "Name one ski resort in Michigan.",
            "stream": False,
        },
        timeout=120,
    )
    response.raise_for_status()
    result = response.json()
    if result.get("status") != "completed" or not any(
        part.get("type") == "output_text" and bool((part.get("text") or "").strip())
        for item in result.get("output", [])
        if item.get("type") == "message"
        for part in item.get("content", [])
    ):
        raise RuntimeError("The pinned agent did not complete with a text response.")
    print(f"Foundry smoke test passed for version {version}.")


def positive_integer(value: str) -> int:
    number = int(value)
    if number <= 0:
        raise argparse.ArgumentTypeError("Must be a positive integer.")
    return number
def main() -> None:
    parser = argparse.ArgumentParser(
        description="Check one exact Foundry agent version and image, with optional invocation."
    )
    parser.add_argument("--project-endpoint", required=True)
    parser.add_argument("--agent-name", required=True)
    parser.add_argument("--agent-version", required=True)
    parser.add_argument("--expected-image", required=True)
    parser.add_argument("--timeout-seconds", type=positive_integer, default=600)
    parser.add_argument("--poll-interval-seconds", type=positive_integer, default=5)
    parser.add_argument("--smoke-test", action="store_true", help="Invoke a session pinned to the checked version.")
    args = parser.parse_args()
    endpoint = urlsplit(args.project_endpoint)
    if (
        endpoint.scheme != "https"
        or not endpoint.hostname
        or endpoint.username is not None
        or endpoint.password is not None
        or endpoint.query
        or endpoint.fragment
        or not re.fullmatch(r"/api/projects/[^/]+/?", endpoint.path)
    ):
        parser.error("--project-endpoint must be a reviewed HTTPS Foundry project endpoint.")
    if not re.fullmatch(r"[1-9][0-9]*", args.agent_version):
        parser.error("--agent-version must be an exact numeric version, not latest.")
    if not re.fullmatch(r"[^/@\s]+/[^@\s]+@sha256:[0-9a-f]{64}", args.expected_image):
        parser.error("--expected-image must be a full immutable registry image URI.")
    if not args.agent_name.strip():
        parser.error("--agent-name must not be empty.")
    agent_url = f"{args.project_endpoint.rstrip('/')}/agents/{quote(args.agent_name, safe='')}"
    url = f"{agent_url}/versions/{args.agent_version}?api-version=v1"
    deadline = time.monotonic() + args.timeout_seconds
    with AzureCliCredential(process_timeout=min(10, args.timeout_seconds)) as credential:
        token = get_bearer_token_provider(credential, "https://ai.azure.com/.default")
        with httpx.Client(follow_redirects=False) as client:
            while time.monotonic() < deadline:
                authorization = f"Bearer {token()}"
                remaining = deadline - time.monotonic()
                if remaining <= 0:
                    break
                response = client.get(
                    url,
                    headers={"Authorization": authorization},
                    timeout=min(30, remaining),
                )
                response.raise_for_status()
                version = response.json()
                if version.get("version") != args.agent_version:
                    raise RuntimeError("Foundry returned a different candidate version.")
                image = version.get("definition", {}).get("container_configuration", {}).get("image")
                if image != args.expected_image:
                    raise RuntimeError("Candidate image differs from the expected immutable image.")
                status = version.get("status")
                if status == "active":
                    print(f"Agent version {args.agent_version} is active with the expected image.")
                    if args.smoke_test:
                        smoke_test(client, f"{agent_url}/endpoint", args.agent_version, token)
                    return
                if status != "creating":
                    raise RuntimeError(
                        f"Candidate has unexpected or terminal status {status!r}; "
                        "inspect its error details in Foundry."
                    )
                remaining = deadline - time.monotonic()
                if remaining > 0:
                    time.sleep(min(args.poll_interval_seconds, remaining))
    raise TimeoutError("Timed out waiting for the specified candidate version to become active.")
if __name__ == "__main__":
    main()