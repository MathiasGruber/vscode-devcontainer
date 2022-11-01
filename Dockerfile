# Note: You can use any Debian/Ubuntu based image you want. 
FROM mcr.microsoft.com/vscode/devcontainers/base:bullseye

# [Option] Install zsh
ARG INSTALL_ZSH="true"
# [Option] Upgrade OS packages to their latest versions
ARG UPGRADE_PACKAGES="false"
# [Option] Enable non-root Docker access in container
ARG ENABLE_NONROOT_DOCKER="true"
# [Option] Use the OSS Moby CLI instead of the licensed Docker CLI
ARG USE_MOBY="true"

# Enable new "BUILDKIT" mode for Docker CLI
ENV DOCKER_BUILDKIT=1

# Install needed packages and setup non-root user. Use a separate RUN statement to add your
# own dependencies. A user of "automatic" attempts to reuse an user ID if one already exists.
ARG USERNAME=automatic
ARG USER_UID=1000
ARG USER_GID=$USER_UID
COPY library-scripts/*.sh /tmp/library-scripts/
RUN apt-get update \
    && /bin/bash /tmp/library-scripts/common-debian.sh "${INSTALL_ZSH}" "${USERNAME}" "${USER_UID}" "${USER_GID}" "${UPGRADE_PACKAGES}" "true" "true" \
    # Use Docker script from script library to set things up
    && /bin/bash /tmp/library-scripts/docker-debian.sh "${ENABLE_NONROOT_DOCKER}" "/var/run/docker-host.sock" "/var/run/docker.sock" "${USERNAME}" \
    # Clean up
    && apt-get autoremove -y && apt-get clean -y && rm -rf /var/lib/apt/lists/* /tmp/library-scripts/

# Install Node.js, see: https://github.com/nodesource/distributions/blob/master/README.md#debinstall
RUN curl -sL https://deb.nodesource.com/setup_16.x | bash - \
    && apt-get install -y nodejs --no-install-recommends

# Install yarn, see: https://classic.yarnpkg.com/en/docs/install/#debian-stable
RUN curl -sS https://dl.yarnpkg.com/debian/pubkey.gpg | apt-key add - \
    && echo "deb https://dl.yarnpkg.com/debian/ stable main" | tee /etc/apt/sources.list.d/yarn.list \
    && apt-get update && apt install -y yarn --no-install-recommends

# Install Azure CLI dependencies
RUN curl -sL https://aka.ms/InstallAzureCLIDeb | sudo bash

# Install AWS CLI
RUN curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
RUN unzip awscliv2.zip
RUN ./aws/install

# Install other small packages
RUN apt-get update \
    # Install additional small packages at the end
    && apt-get -y --no-install-recommends install -y exa ffmpeg libsm6 libxext6 golang libpq-dev gcc build-essential \
    # Clean up
    && apt-get autoremove -y \
    && apt-get clean -y \
    && rm -rf /var/lib/apt/lists/*

# Git update alias
RUN git config --global alias.update '!git pull --rebase && git submodule update --init --recursive'

# Terraform linting (taken from https://github.com/antonbabenko/pre-commit-terraform)
# RUN curl -L https://raw.githubusercontent.com/terraform-linters/tflint/master/install_linux.sh | bash
# RUN which tflint && tflint --version

# Install python 3.10
RUN curl -L -O "https://github.com/conda-forge/miniforge/releases/latest/download/Mambaforge-$(uname)-$(uname -m).sh"
RUN bash Mambaforge-$(uname)-$(uname -m).sh -b -p /opt/conda/
ENV PATH /opt/conda/bin:$PATH
RUN conda install python=3.10 && conda clean -afy

# Install needed libraries
RUN pip install --no-cache-dir \
    pylint==2.15.5 \
    pylint_django==2.5.3 \
    pre-commit==2.20.0 \
    prospector[with_mypy,with_bandit]==1.7.7 \
    hiredis==2.0.0 \
    flake8==4.0.1 \
    types-requests==2.28.11.2 \
    isort==5.10.1 \
    black==22.10.0

# Install kubectl
RUN curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
RUN install -o root -g root -m 0755 kubectl /usr/local/bin/kubectl
RUN which kubectl && kubectl version --client

# Install helm
RUN curl -fsSLk -o get_helm.sh https://raw.githubusercontent.com/helm/helm/master/scripts/get-helm-3
RUN chmod 700 get_helm.sh && ./get_helm.sh
RUN which helm && helm version

# Install source to image (s2i)
RUN mkdir /tmp/s2i/ && cd /tmp/s2i/  && \
    curl -sk https://api.github.com/repos/openshift/source-to-image/releases/latest \
    | grep browser_download_url \
    | grep linux-amd64 \
    | cut -d '"' -f 4 \
    | wget -qi - && \
    tar xvf source-to-image*.gz && \
    sudo mv s2i /usr/local/bin && \
    rm -rf /tmp/s2i/

# Install dotenv and keyring for interacting more easily with Azure DevOps PyPi
RUN wget https://dot.net/v1/dotnet-install.sh
RUN bash dotnet-install.sh -c 6.0
RUN pip install artifacts-keyring

# Install hadolint (Currently not supporting ARM - https://github.com/hadolint/hadolint/issues/411)
# ENV PATH=$PATH:/root/.local/bin
# RUN curl -sSLk https://get.haskellstack.org/ | sh
# RUN stack upgrade && git clone https://github.com/hadolint/hadolint && cd hadolint && stack install
# RUN cp /root/.local/bin/hadolint /usr/local/bin/
# RUN which hadolint && hadolint --version

# Install tfdocs 
# RUN go install github.com/terraform-docs/terraform-docs@v0.15.0
# RUN which terraform-docs && terraform-docs --version

# Install tfsec
# RUN go install github.com/aquasecurity/tfsec/cmd/tfsec@latest
# RUN which tfsec && tfsec --version

# Copy go installs to vscode user
#ENV PATH=$PATH:/home/vscode/go/bin/
#RUN mkdir -p /home/vscode/go/bin/ && cp -r root/go/bin/* /home/vscode/go/bin/

# Install direnv
# RUN curl -sfLk https://direnv.net/install.sh | bash

# Setting the ENTRYPOINT to docker-init.sh will configure non-root access to
# the Docker socket if "overrideCommand": false is set in devcontainer.json.
# The script will also execute CMD if you need to alter startup behaviors.
ENTRYPOINT [ "/usr/local/share/docker-init.sh" ]
CMD [ "sleep", "infinity" ]