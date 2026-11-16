import argparse
import re
import time
from urllib.parse import quote, urlsplit
import httpx
from azure.identity import AzureCliCredential, get_bearer_token_provider
def positive_integer(value: str) -> int:
    number = int(value)
    if number <= 0:
        raise argparse.ArgumentTypeError("Must be a positive integer.")
    return number
def main() -> None:
    parser = argparse.ArgumentParser(
        description="Read-only readiness check for one exact Foundry agent version and image."
    )
    parser.add_argument("--project-endpoint", required=True)
    parser.add_argument("--agent-name", required=True)
    parser.add_argument("--agent-version", required=True)
    parser.add_argument("--expected-image", required=True)
    parser.add_argument("--timeout-seconds", type=positive_integer, default=600)
    parser.add_argument("--poll-interval-seconds", type=positive_integer, default=5)
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
    url = (
        f"{args.project_endpoint.rstrip('/')}/agents/{quote(args.agent_name, safe='')}"
        f"/versions/{args.agent_version}?api-version=v1"
    )
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
                    print(
                        f"Agent version {args.agent_version} is active with the expected image. "
                        "Gateway inference, telemetry and guardrails still require verification."
                    )
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