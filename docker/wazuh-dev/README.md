# Wazuh Manager Development Container

This directory contains configuration files for a Docker-based Wazuh manager development environment.
The setup is designed to be flexible and work with different source code locations and user environments.

## Prerequisites

- Docker
- Docker Compose
- Bash (for the helper script)

## Getting Started

### Environment Setup

1. Set up the development environment:
   ```
   ./wazuh_dev_helper.sh setup
   ```

2. Choose one of these options to get the Wazuh source code:

   - Use an existing local source directory:
   ```
   ./wazuh_dev_helper.sh use /path/to/your/local/wazuh
   ```

   - Create an empty source directory:
   ```
   ./wazuh_dev_helper.sh use create
   ```

   - Copy from an existing directory:
   ```
   ./wazuh_dev_helper.sh copy /path/to/your/local/wazuh
   ```

   - Clone from GitHub:
   ```
   ./wazuh_dev_helper.sh clone v4.3.10
   ```

3. Start the development container:
   ```
   ./wazuh_dev_helper.sh start
   ```

4. Build Wazuh inside the container:
   ```
   # Inside the container:
   cd /wazuh-source
   make -j$(nproc) TARGET=server
   ```

   Or use the helper script:
   ```
   ./wazuh_dev_helper.sh build server
   ```

5. When finished, stop the container:
   ```
   ./wazuh_dev_helper.sh stop
   ```

## Advanced Usage

### Build Options

You can specify build options as parameters:

```bash
./wazuh_dev_helper.sh build [type] [debug] [test]
```

Examples:
```bash
# Build server with debug symbols
./wazuh_dev_helper.sh build server debug

# Build agent with test enabled
./wazuh_dev_helper.sh build agent debug test

# Build local binary
./wazuh_dev_helper.sh build local
```

### Execute Commands in Container

```bash
./wazuh_dev_helper.sh exec [command]
```

Example:
```bash
# Run unit tests
./wazuh_dev_helper.sh exec "cd /wazuh-source && ./run_tests.sh"
```

### Customizing the Environment

You can edit the `.env` file created by the setup command to customize the environment:

```
# Wazuh development environment configuration
HOST_UID=1000
HOST_GID=1000
WAZUH_SOURCE_DIR=/path/to/wazuh/source
SSH_KEY_DIR=~/.ssh
GIT_CONFIG=~/.gitconfig
CUSTOM_TOOLS_DIR=./tools
NETWORK_MODE=bridge
```

## Development Workflow

The container setup creates a seamless development experience:

1. Source files are mounted from your host system
2. Changes made on the host are immediately visible in the container
3. Build artifacts are available on both host and container
4. SSH keys and Git configuration are shared for source control operations

### Common Development Commands

#### Building Wazuh Manager

```bash
cd /wazuh-source
make -j$(nproc) TARGET=server
```

#### Building with Debug Symbols

```bash
make -j$(nproc) TARGET=server DEBUG=yes
```

#### Running Tests

```bash
make -j$(nproc) TARGET=server TEST=1
```

#### Installing Wazuh Manager

```bash
cd /wazuh-source
sudo ./install.sh
```

## Additional Development Tools

The container includes several tools to assist with development:
- GDB: For debugging
- Valgrind: For memory leak detection
- CMake: For building
- Git: For version control
- CMocka: For unit testing

## Note

This container is intended for development purposes only, not for production use.
