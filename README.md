# vscode-devcontainer

Docker image for default vscode devcontainer image with node.js, terraform, etc. installed. Based upon the MS maintained `docker-from-docker` container:
https://github.com/microsoft/vscode-dev-containers/tree/master/containers/docker-from-docker

# Use in docker-compose

Typically I use this image in docker-compose as follows

```yaml
services:
  app:
    build:
      context: .
      dockerfile: Dockerfile
    image: devcontainer
    init: true
    volumes:
      # Forwards the local Docker socket to the container.
      - /var/run/docker.sock:/var/run/docker-host.sock
      # Update this to wherever you want VS Code to mount the folder of your project
      - ..:/workspace:cached
      # One-way volume to use node_modules from inside image
      - /frontend/node_modules
      # Do not set up git each time
      - ~/.gitconfig:/root/.gitconfig

    # Overrides default command so things don't shut down after the process ends.
    entrypoint: /usr/local/share/docker-init.sh
    command: sleep infinity
```

With the `Dockerfile` as follows:

```dockerfile
# Note: You can use any Debian/Ubuntu based image you want.
FROM nanomathias/vscode-devcontainer:latest

# [Optional] Uncomment this section to install additional OS packages.
# RUN apt-get update && export DEBIAN_FRONTEND=noninteractive \
#     && apt-get -y install --no-install-recommends <your-package-list-here>
```

# Build locally

```bash
# Setup docker builder
docker buildx create --name mybuilder --driver-opt network=host --use

# Build docker image (multi-arch version)
docker buildx build \
    --push \
    --tag nanomathias/vscode-devcontainer:release-1.2.3 \
    --platform linux/amd64,linux/arm64 .

# Run docker image to test insides
docker run -it --rm --privileged nanomathias/vscode-devcontainer:release-1.2.3
docker exec -it localdevcontainer bash
```
