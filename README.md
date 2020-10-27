# vscode-devcontainer

Docker image for default vscode devcontainer image with node.js, terraform, etc. installed

# Use in docker-compose

Typically I use this image in docker-compose as follows

```yaml
services:
  app:
    build:
      context: .
      dockerfile: Dockerfile
      args:
        # On Linux, you may need to update USER_UID and USER_GID below if not your local UID is not 1000.
        USER_UID: 1000
        USER_GID: 1000
    image: devcontainer
    init: true
    volumes:
      # Forwards the local Docker socket to the container.
      - /var/run/docker.sock:/var/run/docker-host.sock
      # Update this to wherever you want VS Code to mount the folder of your project
      - ..:/workspace:cached
      # One-way volume to use node_modules from inside image
      - /frontend/node_modules

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
# Build docker image
docker build --tag vscode-devcontainer .
```
