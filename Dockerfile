# Configure a generic CI Server that installs common things

FROM ubuntu:18.04

# To make it easier for build and release pipelines to run apt-get,
# configure apt to not require confirmation (assume the -y argument by default)
ENV DEBIAN_FRONTEND=noninteractive
RUN echo "APT::Get::Assume-Yes \"true\";" > /etc/apt/apt.conf.d/90assumeyes

# Install common CLI tools
RUN apt-get update \
 && apt-get install -y --no-install-recommends \
        software-properties-common \
 && apt-add-repository ppa:git-core/ppa \
 && apt-get update \
 && apt-get install -y --no-install-recommends \
        apt-utils \
        curl \
        git \
        jq \
        libcurl4 \
        libicu60 \
        libunwind8 \
        locales \
        netcat \
        openssh-client \
        sudo \
        unzip \
        wget \
        zip \
 && curl -s https://packagecloud.io/install/repositories/github/git-lfs/script.deb.sh | bash \
 && apt-get install -y --no-install-recommends git-lfs \
 && rm -rf /var/lib/apt/lists/* \
 && rm -rf /etc/apt/sources.list.d/*

# Setup the locale
ENV LANGUAGE en_US:en
ENV LANG en_US.UTF-8
ENV LC_ALL $LANG
RUN locale-gen $LANG \
 && update-locale

# Replace shell with bash so we can source files
RUN rm /bin/sh && ln -s /bin/bash /bin/sh

# Install common build dependencies
RUN apt-get update \
 && apt-get install -y --no-install-recommends \
    apt-transport-https \
    build-essential \
    ca-certificates \
    cmake \
    git \
    gnupg\
    gnupg-agent \
    libsqlite3-0 \
    libsqlite3-dev \
    libssl-dev \
    libudev-dev \
    software-properties-common \
 && rm -rf /var/lib/apt/lists/*

# Install Azure CLI (instructions taken from https://docs.microsoft.com/en-us/cli/azure/install-azure-cli)
RUN echo "deb [arch=amd64] https://packages.microsoft.com/repos/azure-cli/ $(lsb_release -cs) main" \
  | tee /etc/apt/sources.list.d/azure-cli.list \
 && curl -L https://packages.microsoft.com/keys/microsoft.asc | apt-key add - \
 && apt-get update \
 && apt-get install -y --no-install-recommends \
    apt-transport-https \
    azure-cli \
 && rm -rf /var/lib/apt/lists/* \
 && rm -rf /etc/apt/sources.list.d/* \
 && az --version

# Install CMake
RUN curl -sL https://cmake.org/files/v3.10/cmake-3.10.2-Linux-x86_64.sh -o cmake.sh \
 && chmod +x cmake.sh \
 && ./cmake.sh --prefix=/usr/local --exclude-subdir \
 && rm cmake.sh

# Install Docker
RUN curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo apt-key add -

RUN add-apt-repository \
   "deb [arch=amd64] https://download.docker.com/linux/ubuntu \
   $(lsb_release -cs) \
   stable"

RUN apt-get update \
 && apt-get install -y --no-install-recommends \
    docker-ce \
    docker-ce-cli \
    containerd.io

RUN usermod -aG docker $(whoami)

# Install Go
RUN curl -sL https://dl.google.com/go/go1.11.9.linux-amd64.tar.gz -o go1.11.9.linux-amd64.tar.gz \
 && mkdir -p /usr/local/go1.11.9 \
 && tar -C /usr/local/go1.11.9 -xzf go1.11.9.linux-amd64.tar.gz --strip-components=1 go \
 && rm go1.11.9.linux-amd64.tar.gz

RUN curl -sL https://dl.google.com/go/go1.12.4.linux-amd64.tar.gz -o go1.12.4.linux-amd64.tar.gz \
 && mkdir -p /usr/local/go1.12.4 \
 && tar -C /usr/local/go1.12.4 -xzf go1.12.4.linux-amd64.tar.gz --strip-components=1 go \
 && rm go1.12.4.linux-amd64.tar.gz

ENV GOROOT_1_11_X64=/usr/local/go1.11.9 \
    GOROOT_1_12_X64=/usr/local/go1.12.4 \
    GOROOT=/usr/local/go1.12.4
ENV PATH $PATH:$GOROOT/bin

WORKDIR /root/go
RUN mkdir bin
ENV GOPATH=/root/go
ENV GOBIN=$GOPATH/bin
ENV PATH "$PATH:$GOBIN"

# Add Go Libraries
RUN go get github.com/tazjin/kontemplate
RUN go install github.com/tazjin/kontemplate

WORKDIR /

# Install Helm
RUN curl https://raw.githubusercontent.com/kubernetes/helm/master/scripts/get | bash

# Install kubectl
RUN curl -LO https://storage.googleapis.com/kubernetes-release/release/$(curl -s https://storage.googleapis.com/kubernetes-release/release/stable.txt)/bin/linux/amd64/kubectl \
 && chmod +x ./kubectl \
 && mv ./kubectl /usr/local/bin/kubectl

# Install Mono
RUN apt-key adv --keyserver hkp://keyserver.ubuntu.com:80 --recv-keys 3FA7E0328081BFF6A14DA29AA6A19B38D3D831EF \
 && echo "deb https://download.mono-project.com/repo/ubuntu stable-bionic main" | tee /etc/apt/sources.list.d/mono-official-stable.list \
 && apt-get update \
 && apt-get install -y --no-install-recommends \
 mono-complete \
 && rm -rf /var/lib/apt/lists/* \
 && rm -rf /etc/apt/sources.list.d/*

# Install .NET Core SDK and initialize package cache
RUN curl https://packages.microsoft.com/config/ubuntu/18.04/packages-microsoft-prod.deb > packages-microsoft-prod.deb \
 && dpkg -i packages-microsoft-prod.deb \
 && rm packages-microsoft-prod.deb \
 && apt-get update \
 && apt-get install -y --no-install-recommends \
    dotnet-sdk-2.2 \
 && rm -rf /var/lib/apt/lists/* \
 && rm -rf /etc/apt/sources.list.d/*
ENV dotnet=/usr/bin/dotnet

# Install AzCopy (depends on .NET Core)
RUN curl -sL https://aka.ms/downloadazcopy-v10-linux -o azcopy_linux_amd64_10.1.2.tar.gz \
 && mkdir -p /usr/local/azcopy10.1.2 \
 && tar -C /usr/local/azcopy10.1.2 -xzf azcopy_linux_amd64_10.1.2.tar.gz \
 && rm azcopy_linux_amd64_10.1.2.tar.gz

ENV PATH $PATH:/usr/local/azcopy10.1.2

# https://feedback.azure.com/forums/217298-storage/suggestions/34689574-update-azcopy-packages-for-ubuntu-bionic-18-04
# https://github.com/MicrosoftDocs/azure-docs/issues/14182
# RUN apt-key adv --keyserver packages.microsoft.com --recv-keys EB3E94ADBE1229CF \
#  && echo "deb [arch=amd64] https://packages.microsoft.com/repos/microsoft-ubuntu-bionic-prod/ bionic main" | tee /etc/apt/sources.list.d/azure.list \
#  && apt-get update \
#  && apt-get install -y --no-install-recommends azcopy \
#  && rm -rf /var/lib/apt/lists/* \
#  && rm -rf /etc/apt/sources.list.d/*

# Install nvm with node and npm
ENV NVM_DIR /usr/local/nvm
ENV NODE_VERSION 10.15.3

WORKDIR $NVM_DIR

RUN curl https://raw.githubusercontent.com/creationix/nvm/v0.34.0/install.sh | bash \
    && . $NVM_DIR/nvm.sh \
    && nvm install $NODE_VERSION \
    && nvm alias default $NODE_VERSION \
    && nvm use default

ENV NODE_PATH $NVM_DIR/versions/node/v$NODE_VERSION/lib/node_modules
ENV PATH      $NVM_DIR/versions/node/v$NODE_VERSION/bin:$PATH

WORKDIR /

# Install global node packages
RUN npm install -g bower \
    && npm install -g grunt \
    && npm install -g gulp \
    && npm install -g webpack webpack-cli --save-dev \
    && npm install -g parcel-bundler

ENV bower=/usr/local/bin/bower \
    grunt=/usr/local/bin/grunt

# Install Powershell Core
RUN curl https://packages.microsoft.com/keys/microsoft.asc | apt-key add - \
 && curl https://packages.microsoft.com/config/ubuntu/18.04/prod.list | tee /etc/apt/sources.list.d/microsoft.list \
 && apt-get update \
 && apt-get install -y --no-install-recommends \
    powershell \
 && rm -rf /var/lib/apt/lists/* \
 && rm -rf /etc/apt/sources.list.d/*

# Install Python
RUN apt-get update \
 && apt-get install -y --no-install-recommends \
    python \
    python-pip \
    python3 \
    python3-pip \
 && rm -rf /var/lib/apt/lists/*

# Install Terraform
RUN TERRAFORM_VERSION=$(curl -s https://checkpoint-api.hashicorp.com/v1/check/terraform | jq -r .current_version) \
 && curl -LO https://releases.hashicorp.com/terraform/${TERRAFORM_VERSION}/terraform_${TERRAFORM_VERSION}_linux_amd64.zip \
 && unzip terraform_${TERRAFORM_VERSION}_linux_amd64.zip -d /usr/local/bin \
 && rm -f terraform_${TERRAFORM_VERSION}_linux_amd64.zip

# Install yarn
RUN curl -sS https://dl.yarnpkg.com/debian/pubkey.gpg | apt-key add - \
 && echo "deb https://dl.yarnpkg.com/debian/ stable main" | tee /etc/apt/sources.list.d/yarn.list \
 && apt-get update \
 && apt-get install -y --no-install-recommends yarn \
 && rm -rf /var/lib/apt/lists/* \
 && rm -rf /etc/apt/sources.list.d/*

# Clean the system
RUN apt-get clean \
 && rm -rf /var/lib/apt/lists/* \
 && rm -rf /etc/apt/sources.list.d/*
