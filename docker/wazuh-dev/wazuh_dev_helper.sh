#!/bin/bash

# Helper script for working with the Wazuh development container
# Make this script executable with: chmod +x ./wazuh_dev_helper.sh

# Default configuration - can be overridden with environment variables
WAZUH_SOURCE_DIR="./wazuh-source"
CONTAINER_NAME="wazuh-dev"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ENV_FILE="${SCRIPT_DIR}/.env"

# Create .env file if it doesn't exist
touch "$ENV_FILE"

# Load existing environment variables from .env
if [ -f "$ENV_FILE" ]; then
    source "$ENV_FILE"
fi

# Set current user ID and group ID for container
export HOST_UID=$(id -u)
export HOST_GID=$(id -g)

# Functions
function setup_environment() {
    echo "Setting up environment..."

    # Create a local .env file with current settings
    cat > "$ENV_FILE" <<EOL
# Wazuh development environment configuration
HOST_UID=${HOST_UID}
HOST_GID=${HOST_GID}
WAZUH_SOURCE_DIR=${WAZUH_SOURCE_DIR}
SSH_KEY_DIR=${SSH_KEY_DIR:-~/.ssh}
GIT_CONFIG=${GIT_CONFIG:-~/.gitconfig}
CUSTOM_TOOLS_DIR=${CUSTOM_TOOLS_DIR:-./tools}
NETWORK_MODE=${NETWORK_MODE:-bridge}
EOL

    echo "Environment setup complete. Configuration saved to $ENV_FILE"
}

function use_source() {
    # Either point to existing source or set up empty directory
    if [ -n "$1" ] && [ -d "$1" ]; then
        # Use absolute path
        WAZUH_SOURCE_DIR=$(cd "$1" && pwd)
        echo "WAZUH_SOURCE_DIR=$WAZUH_SOURCE_DIR" >> "$ENV_FILE"
        echo "Using existing Wazuh source at $WAZUH_SOURCE_DIR"
    elif [ "$1" = "create" ]; then
        WAZUH_SOURCE_DIR="${SCRIPT_DIR}/wazuh-source"
        mkdir -p "$WAZUH_SOURCE_DIR"
        echo "WAZUH_SOURCE_DIR=$WAZUH_SOURCE_DIR" >> "$ENV_FILE"
        echo "Created empty source directory at $WAZUH_SOURCE_DIR"
    else
        echo "ERROR: Directory '$1' not found."
        echo "Usage: $0 use /path/to/wazuh/source"
        echo "   or: $0 use create (to create an empty directory)"
        exit 1
    fi
}

function copy_source() {
    local source_path=$1

    # Check if source path exists
    if [ ! -d "$source_path" ]; then
        echo "ERROR: Local source directory '$source_path' does not exist!"
        echo "Usage: $0 copy /path/to/your/local/wazuh"
        exit 1
    fi

    # Create destination directory if it doesn't exist
    local dest_dir="${SCRIPT_DIR}/wazuh-source"
    mkdir -p "$dest_dir"

    echo "Copying Wazuh source from $source_path to $dest_dir..."
    rsync -av --exclude '.git/objects' --exclude 'build' --exclude '*.o' "$source_path/" "$dest_dir/"

    # Update environment variable
    WAZUH_SOURCE_DIR="$dest_dir"
    echo "WAZUH_SOURCE_DIR=$WAZUH_SOURCE_DIR" >> "$ENV_FILE"

    echo "Source code copied successfully."
}

function clone_source() {
    local branch=${1:-master}
    local dest_dir="${SCRIPT_DIR}/wazuh-source"

    mkdir -p "$dest_dir"

    echo "Cloning Wazuh repository (branch: $branch)..."
    git clone https://github.com/wazuh/wazuh.git --depth 1 --branch "$branch" "$dest_dir"

    # Update environment variable
    WAZUH_SOURCE_DIR="$dest_dir"
    echo "WAZUH_SOURCE_DIR=$WAZUH_SOURCE_DIR" >> "$ENV_FILE"

    echo "Wazuh repository cloned successfully."
}

function start_container() {
    # Check if source directory exists
    if [ ! -d "$WAZUH_SOURCE_DIR" ]; then
        echo "WARNING: Source directory does not exist. Creating empty directory."
        mkdir -p "$WAZUH_SOURCE_DIR"
    fi

    # Create custom tools directory if it doesn't exist
    local tools_dir="${CUSTOM_TOOLS_DIR:-${SCRIPT_DIR}/tools}"
    mkdir -p "$tools_dir"

    # Start the development container
    echo "Starting Wazuh development container..."
    cd "$SCRIPT_DIR" && docker-compose up -d

    # Attach to the container
    echo "Attaching to container..."
    docker-compose exec wazuh-dev bash
}

function build_wazuh() {
    local build_type=${1:-server}
    local debug=${2:-no}
    local test=${3:-0}

    local debug_flag=""
    local test_flag=""

    if [ "$debug" = "debug" ]; then
        debug_flag="DEBUG=yes"
    fi

    if [ "$test" = "test" ]; then
        test_flag="TEST=1"
    fi

    echo "Building Wazuh $build_type (Debug: $debug, Test: $test)..."
    docker-compose exec wazuh-dev bash -c "cd /wazuh-source && make -j\$(nproc) TARGET=$build_type $debug_flag $test_flag"
}

function exec_command() {
    docker-compose exec wazuh-dev bash -c "$*"
}

function stop_container() {
    echo "Stopping Wazuh development container..."
    cd "$SCRIPT_DIR" && docker-compose down
}

function print_usage() {
    echo "Wazuh Development Helper"
    echo "Usage: $0 [command]"
    echo ""
    echo "Environment Setup:"
    echo "  setup              Setup environment variables"
    echo "  use [path|create]  Use existing source directory or create empty one"
    echo ""
    echo "Container Management:"
    echo "  start              Start the development container and attach to it"
    echo "  stop               Stop the development container"
    echo ""
    echo "Source Code Management:"
    echo "  copy [path]        Copy Wazuh source from local path"
    echo "  clone [branch]     Clone Wazuh repository (default branch: master)"
    echo ""
    echo "Build Commands:"
    echo "  build [type] [debug] [test]  Build Wazuh (default: server)"
    echo "                               - type: server, agent, local, winagent"
    echo "                               - debug: debug to enable debug mode"
    echo "                               - test: test to enable test mode"
    echo ""
    echo "Other Commands:"
    echo "  exec [command]     Execute command in container"
    echo "  help               Show this help message"
    echo ""
    echo "Examples:"
    echo "  $0 setup              # Configure environment variables"
    echo "  $0 use /path/to/wazuh # Use existing source code"
    echo "  $0 clone v4.3.10      # Clone specific version"
    echo "  $0 build server debug # Build server with debug symbols"
}

# Process command line arguments
case "$1" in
    setup)
        setup_environment
        ;;
    use)
        use_source "$2"
        ;;
    copy)
        copy_source "$2"
        ;;
    clone)
        clone_source "$2"
        ;;
    start)
        start_container
        ;;
    build)
        build_wazuh "$2" "$3" "$4"
        ;;
    exec)
        shift
        exec_command "$@"
        ;;
    stop)
        stop_container
        ;;
    help|*)
        print_usage
        ;;
esac
