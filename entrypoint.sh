#!/usr/bin/env bash
set -eEuo pipefail

# Start Docker daemon in background (requires --privileged)
dockerd &>/var/log/dockerd.log &
for i in $(seq 1 30); do
  if docker info &>/dev/null 2>&1; then
    echo "Docker daemon ready"
    break
  fi
  if [ "$i" = "30" ]; then
    echo "Warning: Docker daemon failed to start (container may need --privileged flag)"
    break
  fi
  sleep 1
done

if [ -z "${TOKEN:-}" ]
then
  echo "TOKEN is required"
  exit 1
fi

if [ -n "${ORG:-}" ]
then
  API_PATH=orgs/${ORG}
  CONFIG_PATH=${ORG}
elif [ -n "${OWNER:-}" ] && [ -n "${REPO:-}" ]
then
  API_PATH=repos/${OWNER}/${REPO}
  CONFIG_PATH=${OWNER}/${REPO}
else
  echo "[ORG] or [OWNER and REPO] is required"
  exit 1
fi

RUNNER_TOKEN=$(curl -s -X POST -H "authorization: token ${TOKEN}" "https://api.github.com/${API_PATH}/actions/runners/registration-token" | jq -r .token)

cleanup() {
  gosu actions ./config.sh remove --token "${RUNNER_TOKEN}"
}

gosu actions ./config.sh \
  --url "https://github.com/${CONFIG_PATH}" \
  --token "${RUNNER_TOKEN}" \
  --name "${NAME:-$(hostname)}" \
  --unattended

trap 'cleanup' SIGTERM

gosu actions ./run.sh "$@" &

wait $!
