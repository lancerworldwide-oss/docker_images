# .devcontainer/Dockerfile.prebuilt
# based on https://github.com/zephyrproject-rtos/docker-image 
# Prebuilt Zephyr environment template for MCX-based firmware development
# to build and push the base image perform the following:
# az login
# az acr login --name lancer
# docker build -f .devcontainer/Dockerfile -t lancer.azurecr.io/zephyr-mcxa156-prebuilt:latest .
# docker push lancer.azurecr.io/zephyr-mcxa156-prebuilt:latest

FROM ghcr.io/zephyrproject-rtos/zephyr-build:v0.28.7

# Directory where the Zephyr tree will live in the image
ENV ZEPHYR_WORKSPACE=/opt/zephyrproject

WORKDIR ${ZEPHYR_WORKSPACE}

USER root

RUN <<EOF
    apt-get update 
    apt-get install -y libjson-xs-perl git curl ca-certificates wget gnupg apt-transport-https python3-pip python3 python-is-python3
    mkdir -p /etc/apt/keyrings
    curl -fsSL https://deb.nodesource.com/gpgkey/nodesource-repo.gpg.key | gpg --dearmor -o /etc/apt/keyrings/nodesource.gpg
    echo "deb [signed-by=/etc/apt/keyrings/nodesource.gpg] https://deb.nodesource.com/node_20.x nodistro main" > /etc/apt/sources.list.d/nodesource.list
    apt-get update
    apt-get install -y nodejs
    apt-get clean
    rm -rf /var/lib/apt/lists/*
EOF

# NOTE: We are using the version of dts2repl that is associated with the base image's renode version
# to avoid compatibility issues.
# If you update renode in the base image, please update the dts2repl commit hash accordingly.
# you can get the git hash by inspecting the git repo and branch of the renode build in the base image
RUN python3 -m pip install git+https://github.com/antmicro/dts2repl.git@c281274

USER user

WORKDIR ${ZEPHYR_WORKSPACE}

RUN west init -m https://github.com/zephyrproject-rtos/zephyr --mr v4.3-branch .

RUN west update --fetch=smart --narrow -o=--depth=1

USER root

RUN <<EOF
    . /etc/os-release
    wget -qO /tmp/packages-microsoft-prod.deb https://packages.microsoft.com/config/ubuntu/${VERSION_ID}/packages-microsoft-prod.deb
    dpkg -i /tmp/packages-microsoft-prod.deb
    rm /tmp/packages-microsoft-prod.deb
EOF

# Add jammy repo for gtk-sharp2 (not available in noble)
RUN <<EOF
    printf "deb http://archive.ubuntu.com/ubuntu jammy main universe multiverse\n" > /etc/apt/sources.list.d/jammy.list
    printf "deb http://archive.ubuntu.com/ubuntu jammy-updates main universe multiverse\n" >> /etc/apt/sources.list.d/jammy.list
    printf "deb http://security.ubuntu.com/ubuntu jammy-security main universe multiverse\n" >> /etc/apt/sources.list.d/jammy.list
EOF

RUN <<EOF
    apt-get update
    apt-get install -y \
        automake \
        build-essential \
        clang-tools \
        clang-format \
        clang-tidy \
        cmake \
        cppcheck \
        cpplint \
        coreutils \
        dotnet-sdk-10.0 \
        doxygen \
        graphviz \
        mscgen \
        plantuml \
        gcc \
        gtk-sharp3 \
        gtk-sharp2 \
        htop \
        libgtk2.0-dev \
        libc6-dev \
        libtool \
        libffi-dev \
        libglib2.0-dev \
        libgdk-pixbuf2.0-dev \
        libpango1.0-dev \
        libatk1.0-dev \
        libgtk-3-dev \
        libicu-dev \
        libssl-dev \
        libxml2-dev \
        minicom \
        mono-complete \
        nano \
        pkg-config \
        policykit-1 \
        screen \
        tmux \
        uml-utilities \
        zlib1g-dev
    apt-get clean
    rm -rf /var/lib/apt/lists/*
EOF

# Set ZEPHYR_BASE so west builds are ready out-of-the-box
ENV ZEPHYR_BASE=${ZEPHYR_WORKSPACE}/zephyr

# Optionally set default toolchain variant if not already set by base image
# ENV ZEPHYR_TOOLCHAIN_VARIANT=gnuarmemb