#!/bin/bash

# Configuration variables
DELAY=120
DATA_DIR="/root/.config/moontrader-data/data"
IMAGE_NAME="mtcore-wd"

# Profiles to process
declare -A PROFILES=(
    ["profile1"]="18.176.43.181"
    ["profile2"]="18.176.43.182"
    ["profile3"]="18.176.43.183"
    ["profile4"]="18.176.43.184"
    ["profile5"]="18.176.43.185"
)

# Cleanup configuration
FILES_TO_REMOVE=(
    "algorithms.config"
    "core.conf.bak"
    "mtdb035.fdb5"
    "mtdb035.fdb5.dat"
)

# Function declarations
check_docker() {
    if ! command -v docker &> /dev/null; then
        echo "Docker not found, installing..."
        curl -fsSL https://get.docker.com -o get-docker.sh
        sh get-docker.sh
        rm get-docker.sh
        echo "Docker installed successfully"
    else
        echo "Docker already installed"
    fi
}

build_image() {
    if docker image inspect "${IMAGE_NAME}" >/dev/null 2>&1; then
        echo "Docker image ${IMAGE_NAME} already exists"
        return 0
    fi

    echo "Building Docker image: ${IMAGE_NAME}"
    if ! docker build -t "${IMAGE_NAME}" .; then
        echo "Failed to build Docker image"
        exit 1
    fi
    echo "Docker image built successfully"
}

configure_profile() {
    local PROFILE=$1
    local PROFILE_DIR="$(pwd)/profiles/${PROFILE}"
    local IP_ADDRESS=${PROFILES[$PROFILE]}

    for file in "${FILES_TO_REMOVE[@]}"; do
        [ -f "$PROFILE_DIR/$file" ] && rm "$PROFILE_DIR/$file"
    done

    sed -i "s/^address:.*/address:${IP_ADDRESS}/" "$PROFILE_DIR/client.conf"
    echo "Updated client.conf with address: ${IP_ADDRESS}"
}

# Main script execution
check_docker
build_image

for PROFILE in "${!PROFILES[@]}"; do
    CONTAINER_NAME="wd-${PROFILE}"
    echo "Processing container for profile: $PROFILE"

    configure_profile "$PROFILE"

    if docker ps --format '{{.Names}}' | grep -q "^${CONTAINER_NAME}$"; then
        echo "Container already running: ${CONTAINER_NAME}, skipping..."
        continue
    elif docker ps -a --format '{{.Names}}' | grep -q "^${CONTAINER_NAME}$"; then
        echo "Container exists but stopped, starting: ${CONTAINER_NAME}"
        docker start "${CONTAINER_NAME}"
    else
        echo "Creating new container: ${CONTAINER_NAME}"
        docker run -d \
            --name "${CONTAINER_NAME}" \
            --restart no \
            -v "$(pwd)/profiles/${PROFILE}:${DATA_DIR}/${PROFILE}" \
            -e PROFILE="${PROFILE}" \
            ${IMAGE_NAME}
    fi

    echo "Waiting ${DELAY}s before next container..."
    sleep $DELAY
done

echo "All containers processed"