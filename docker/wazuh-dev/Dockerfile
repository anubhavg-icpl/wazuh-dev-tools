FROM ubuntu:22.04

ARG DEBIAN_FRONTEND="noninteractive"
ARG USERNAME=wazuh
ARG USER_UID=1000
ARG USER_GID=$USER_UID

# Install development dependencies
RUN apt-get update && \
    apt-get install -y \
    python3 python3-pip \
    gcc g++ make libc6-dev \
    curl policycoreutils \
    automake autoconf libtool \
    libssl-dev procps \
    git cmake libc6-dev-i386 \
    gdb valgrind strace \
    libcmocka-dev lcov \
    nano vim \
    rsync \
    wget sudo && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

# Create a non-root user with the same UID/GID as the host user
RUN groupadd --gid $USER_GID $USERNAME && \
    useradd --uid $USER_UID --gid $USER_GID -m $USERNAME -s /bin/bash && \
    echo $USERNAME ALL=\(root\) NOPASSWD:ALL > /etc/sudoers.d/$USERNAME && \
    chmod 0440 /etc/sudoers.d/$USERNAME

# Create development workspace
RUN mkdir -p /wazuh-source && chown $USERNAME:$USERNAME /wazuh-source

# Switch to non-root user
USER $USERNAME
WORKDIR /wazuh-source

# Set up bash environment
RUN echo "export PS1='\[\033[01;32m\]wazuh-dev\[\033[00m\]:\[\033[01;34m\]\w\[\033[00m\]\$ '" >> ~/.bashrc && \
    echo "alias ls='ls --color=auto'" >> ~/.bashrc && \
    echo "alias ll='ls -la'" >> ~/.bashrc

# Set up git configuration
RUN git config --global core.editor "nano" && \
    git config --global color.ui true

CMD ["/bin/bash"]
