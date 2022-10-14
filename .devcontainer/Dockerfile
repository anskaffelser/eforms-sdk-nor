# See here for image contents: https://github.com/microsoft/vscode-dev-containers/tree/v0.245.0/containers/ruby/.devcontainer/base.Dockerfile

# [Choice] Ruby version (use -bullseye variants on local arm64/Apple Silicon): 3, 3.1, 3.0, 2, 2.7, 3-bullseye, 3.1-bullseye, 3.0-bullseye, 2-bullseye, 2.7-bullseye, 3-buster, 3.1-buster, 3.0-buster, 2-buster, 2.7-buster
ARG VARIANT="3.1-bullseye"
FROM mcr.microsoft.com/vscode/devcontainers/ruby:0-${VARIANT}

# [Optional] Uncomment this section to install additional OS packages.
# RUN apt-get update && export DEBIAN_FRONTEND=noninteractive \
#     && apt-get -y install --no-install-recommends <your-package-list-here>

# [Optional] Uncomment this line to install additional gems.
# RUN gem install <your-gem-names-here>

RUN apt update \
 && apt install gettext-base