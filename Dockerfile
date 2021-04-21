# Note: You can use any Debian/Ubuntu based image you want.
FROM mcr.microsoft.com/vscode/devcontainers/base:buster

# [Option] Install zsh
ARG INSTALL_ZSH="true"
# [Option] Upgrade OS packages to their latest versions
ARG UPGRADE_PACKAGES="false"
# [Option] Enable non-root Docker access in container
ARG ENABLE_NONROOT_DOCKER="true"
# [Option] Use the OSS Moby CLI instead of the licensed Docker CLI
ARG USE_MOBY="true"

# Install needed packages and setup non-root user. Use a separate RUN statement to add your
# own dependencies. A user of "automatic" attempts to reuse an user ID if one already exists.
ARG USERNAME=automatic
ARG USER_UID=1000
ARG USER_GID=$USER_UID
COPY library-scripts/*.sh /tmp/library-scripts/
RUN apt-get update \
    && /bin/bash /tmp/library-scripts/common-debian.sh "${INSTALL_ZSH}" "${USERNAME}" "${USER_UID}" "${USER_GID}" "${UPGRADE_PACKAGES}" "true" "true" \
    # Use Docker script from script library to set things up
    && /bin/bash /tmp/library-scripts/docker-debian.sh "${ENABLE_NONROOT_DOCKER}" "/var/run/docker-host.sock" "/var/run/docker.sock" "${USERNAME}" "${USE_MOBY}" \
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
ENV PATH=$PATH:"/root/go/bin"

# Install other small packages
RUN apt-get update \
    # Install additional small packages at the end
    && apt-get -y --no-install-recommends install -y exa \
    # Clean up
    && apt-get autoremove -y \
    && apt-get clean -y \
    && rm -rf /var/lib/apt/lists/*

# Install kubectl
RUN curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
RUN install -o root -g root -m 0755 kubectl /usr/local/bin/kubectl
RUN kubectl version --client

# Install helm
RUN curl -fsSL -o get_helm.sh https://raw.githubusercontent.com/helm/helm/master/scripts/get-helm-3
RUN chmod 700 get_helm.sh && ./get_helm.sh

# Install source to image (s2i)
RUN mkdir /tmp/s2i/ && cd /tmp/s2i/  && \
  curl -s https://api.github.com/repos/openshift/source-to-image/releases/latest \
  | grep browser_download_url \
  | grep linux-amd64 \
  | cut -d '"' -f 4 \
  | wget -qi - && \
  tar xvf source-to-image*.gz && \
  sudo mv s2i /usr/local/bin && \
  rm -rf /tmp/s2i/

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