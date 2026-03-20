FROM ubuntu:24.04

ENV DEBIAN_FRONTEND=noninteractive

RUN useradd -m actions

# Install base dependencies and GitHub runner toolset packages
RUN apt-get update \
    && apt-get install -y --no-install-recommends \
        apt-transport-https ca-certificates curl jq software-properties-common wget \
    && toolset="$(curl -sL https://raw.githubusercontent.com/actions/runner-images/refs/heads/main/images/ubuntu/toolsets/toolset-2404.json)" \
    && common_packages=$(echo "$toolset" | jq -r '.apt.common_packages[]') \
    && cmd_packages=$(echo "$toolset" | jq -r '.apt.cmd_packages[]') \
    && for package in $common_packages $cmd_packages; do \
        apt-get install -y --no-install-recommends "$package"; \
    done \
    && rm -rf /var/lib/apt/lists/*

# Install Docker CLI
RUN curl -fsSL https://download.docker.com/linux/ubuntu/gpg | gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg \
    && echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/ubuntu $(. /etc/os-release && echo "$VERSION_CODENAME") stable" \
        > /etc/apt/sources.list.d/docker.list \
    && apt-get update \
    && apt-get install -y --no-install-recommends \
        docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin \
    && rm -rf /var/lib/apt/lists/*

# Install Git from PPA and build-essential
RUN add-apt-repository ppa:git-core/ppa -y \
    && apt-get update \
    && apt-get install -y --no-install-recommends build-essential git \
    && rm -rf /var/lib/apt/lists/*

# Install GitHub Actions Runner (latest)
RUN RUNNER_VERSION="$(curl -s https://api.github.com/repos/actions/runner/releases/latest | jq -r '.tag_name|ltrimstr("v")')" \
    && ARCH="$(dpkg --print-architecture)" \
    && [ "$ARCH" = "amd64" ] && RUNNER_ARCH="x64" || RUNNER_ARCH="$ARCH" \
    && cd /home/actions && mkdir actions-runner && cd actions-runner \
    && wget -q "https://github.com/actions/runner/releases/download/v${RUNNER_VERSION}/actions-runner-linux-${RUNNER_ARCH}-${RUNNER_VERSION}.tar.gz" -O runner.tar.gz \
    && tar xzf runner.tar.gz \
    && rm -f runner.tar.gz \
    && ./bin/installdependencies.sh \
    && rm -rf /var/lib/apt/lists/* \
    && chown -R actions ~actions

# Install LTS Node.js and global build tools
RUN curl -fsSL https://raw.githubusercontent.com/mklement0/n-install/stable/bin/n-install | bash -s -- -ny - \
    && ~/n/bin/n lts \
    && npm install -g grunt gulp n parcel typescript newman webpack webpack-cli \
    && rm -rf ~/n

WORKDIR /home/actions/actions-runner

USER actions
COPY --chown=actions:actions entrypoint.sh .
RUN chmod u+x ./entrypoint.sh
ENTRYPOINT ["./entrypoint.sh"]
