#!/usr/bin/env bash

# StepSecurity subscription check
UPSTREAM="addnab/docker-run-action"
DOCS_URL="https://docs.stepsecurity.io/actions/stepsecurity-maintained-actions"
ACTION_REPO="${GITHUB_ACTION_REPOSITORY:-}"

REPO_PRIVATE=""
if [ -n "$GITHUB_EVENT_PATH" ] && [ -f "$GITHUB_EVENT_PATH" ]; then
  REPO_PRIVATE=$(jq -r '.repository.private' "$GITHUB_EVENT_PATH" 2>/dev/null || true)
fi

echo ""
printf '\033[1;36mStepSecurity Maintained Action\033[0m\n'
echo "Secure drop-in replacement for $UPSTREAM"
if [ "$REPO_PRIVATE" = "false" ]; then
  printf '\033[32m✓ Free for public repositories\033[0m\n'
fi
printf '\033[36mLearn more:\033[0m %s\n' "$DOCS_URL"
echo ""

if [ "$REPO_PRIVATE" != "false" ]; then
  SERVER_URL="${GITHUB_SERVER_URL:-https://github.com}"

  if [ "$SERVER_URL" != "https://github.com" ]; then
    BODY=$(printf '{"action":"%s","ghes_server":"%s"}' "$ACTION_REPO" "$SERVER_URL")
  else
    BODY=$(printf '{"action":"%s"}' "$ACTION_REPO")
  fi

  API_URL="https://agent.api.stepsecurity.io/v1/github/$GITHUB_REPOSITORY/actions/maintained-actions-subscription"

  RESPONSE=$(curl --max-time 3 -s -w "%{http_code}" \
    -X POST \
    -H "Content-Type: application/json" \
    -d "$BODY" \
    "$API_URL" -o /dev/null) && CURL_EXIT_CODE=0 || CURL_EXIT_CODE=$?

  if [ "$CURL_EXIT_CODE" -ne 0 ]; then
    echo "Timeout or API not reachable. Continuing to next step."
  elif [ "$RESPONSE" = "403" ]; then
    printf '::error::\033[1;31mThis action requires a StepSecurity subscription for private repositories.\033[0m\n'
    printf '::error::\033[31mLearn how to enable a subscription: %s\033[0m\n' "$DOCS_URL"
    exit 1
  fi
fi

if [ -n "$INPUT_USERNAME" ]; then
  echo "$INPUT_PASSWORD" | docker login "$INPUT_REGISTRY" -u "$INPUT_USERNAME" --password-stdin
fi

DOCKER_ARGS=(-v "/var/run/docker.sock:/var/run/docker.sock")

if [ -n "${INPUT_OPTIONS:-}" ]; then
  read -ra _USER_OPTS <<< "$INPUT_OPTIONS"
  DOCKER_ARGS+=("${_USER_OPTS[@]}")
fi

if [ -n "${INPUT_DOCKER_NETWORK:-}" ]; then
  DOCKER_ARGS+=(--network "$INPUT_DOCKER_NETWORK")
fi

DOCKER_ARGS+=(--entrypoint="$INPUT_SHELL" "$INPUT_IMAGE" -c "${INPUT_RUN//$'\n'/;}")

exec docker run "${DOCKER_ARGS[@]}"
