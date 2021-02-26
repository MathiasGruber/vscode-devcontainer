# Note: You can use any Debian/Ubuntu based image you want.
FROM mcr.microsoft.com/vscode/devcontainers/base:buster

# [Option] Install zsh
ARG INSTALL_ZSH="true"
# [Option] Upgrade OS packages to their latest versions
ARG UPGRADE_PACKAGES="false"
# [Option] Enable non-root Docker access in container
ARG ENABLE_NONROOT_DOCKER="true"

# Install needed packages and setup non-root user. Use a separate RUN statement to add your own dependencies.
ARG SOURCE_SOCKET=/var/run/docker-host.sock
ARG TARGET_SOCKET=/var/run/docker.sock
ARG USERNAME=vscode
ARG USER_UID=1000
ARG USER_GID=$USER_UID
COPY library-scripts/*.sh /tmp/library-scripts/
RUN apt-get update \
    && /bin/bash /tmp/library-scripts/common-debian.sh "${INSTALL_ZSH}" "${USERNAME}" "${USER_UID}" "${USER_GID}" "${UPGRADE_PACKAGES}" \
    # Use Docker script from script library to set things up
    && /bin/bash /tmp/library-scripts/docker-debian.sh "${ENABLE_NONROOT_DOCKER}" "${SOURCE_SOCKET}" "${TARGET_SOCKET}" "${USERNAME}" \
    # Clean up
    && apt-get autoremove -y && apt-get clean -y && rm -rf /var/lib/apt/lists/* /tmp/library-scripts/

# Install Node.js, see: https://github.com/nodesource/distributions/blob/master/README.md#debinstall
RUN curl -sL https://deb.nodesource.com/setup_14.x | bash - \
    && apt-get install -y nodejs --no-install-recommends

# Install yarn, see: https://classic.yarnpkg.com/en/docs/install/#debian-stable
RUN curl -sS https://dl.yarnpkg.com/debian/pubkey.gpg | apt-key add - \
    && echo "deb https://dl.yarnpkg.com/debian/ stable main" | tee /etc/apt/sources.list.d/yarn.list \
    && apt-get update && apt install -y yarn --no-install-recommends

# Install Azure CLI dependencies
RUN curl -sL https://aka.ms/InstallAzureCLIDeb | sudo bash
RUN az extension add -n azure-devops

# Install AWS CLI
RUN curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
RUN unzip awscliv2.zip
RUN ./aws/install

# Install terraform
RUN curl -fsSL https://apt.releases.hashicorp.com/gpg | apt-key add - \
    # Link up to repository before installing
    && apt-get update \
    && apt-get install -y software-properties-common --no-install-recommends \
    && apt-add-repository "deb [arch=amd64] https://apt.releases.hashicorp.com $(lsb_release -cs) main" \
    && apt-get update \
    && apt-get -y --no-install-recommends install terraform g++ gcc libc6-dev libffi-dev libgmp-dev make xz-utils zlib1g-dev git gnupg netbase \
    # Clean up
    && apt-get autoremove -y \
    && apt-get clean -y \
    && rm -rf /var/lib/apt/lists/*

# Git update alias
RUN git config --global alias.update '!git pull --rebase && git submodule update --init --recursive'

# Terraform linting (taken from https://github.com/antonbabenko/pre-commit-terraform)
RUN curl https://raw.githubusercontent.com/terraform-linters/tflint/master/install_linux.sh | bash

# Install hadolint
RUN curl -sSL https://get.haskellstack.org/ | sh
RUN stack upgrade && git clone https://github.com/hadolint/hadolint && cd hadolint && stack install

# Get golang installed. See: https://stackoverflow.com/questions/52056387/how-to-install-go-in-alpine-linux
ARG GOLANG_VERSION=1.16
RUN wget https://golang.org/dl/go$GOLANG_VERSION.linux-amd64.tar.gz
RUN tar -C /usr/local -xzf go$GOLANG_VERSION.linux-amd64.tar.gz
ENV PATH=$PATH:/usr/local/go/bin
RUN go version

# Install tfdocs
RUN go get github.com/terraform-docs/terraform-docs@v0.11.2
RUN TFDOCS=$(go env GOPATH)/bin
ENV PATH=$PATH:$TFDOCS

# [Optional] Uncomment this section to install additional OS packages.
# RUN apt-get update && export DEBIAN_FRONTEND=noninteractive \
#     && apt-get -y install --no-install-recommends <your-package-list-here>

# Setting the ENTRYPOINT to docker-init.sh will configure non-root access to
# the Docker socket if "overrideCommand": false is set in devcontainer.json.
# The script will also execute CMD if you need to alter startup behaviors.
ENTRYPOINT [ "/usr/local/share/docker-init.sh" ]
CMD [ "sleep", "infinity" ]

# Things to be installed when python is setup
# RUN pip install azure-cli
# RUN az extension add -n azure-devops
# RUN pip install yapf pylint pylint_django