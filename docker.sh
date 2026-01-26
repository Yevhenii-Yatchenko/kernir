#!/bin/bash

# Detect docker compose command
if command -v docker-compose &> /dev/null; then
    COMPOSE_CMD="docker-compose"
elif docker compose version &> /dev/null; then
    COMPOSE_CMD="docker compose"
else
    echo "Error: Neither docker-compose nor docker compose is available"
    exit 1
fi

case "$1" in
    start)
        # Grant X11 access for GUI apps (Gazebo, RViz)
        xhost +local:docker
        $COMPOSE_CMD up -d --build
        echo ""
        echo "Gazebo starting with forest world..."
        echo "To open a shell: ./docker.sh shell"
        ;;
    stop)
        $COMPOSE_CMD down
        echo "Container stopped."
        ;;
    restart)
        $COMPOSE_CMD down
        xhost +local:docker
        $COMPOSE_CMD up -d --build
        echo ""
        echo "Gazebo restarting with forest world..."
        echo "To open a shell: ./docker.sh shell"
        ;;
    shell)
        # Open bash shell in running container
        $COMPOSE_CMD exec ros-noetic /entrypoint.sh bash
        ;;
    logs)
        # Show container logs
        $COMPOSE_CMD logs -f ros-noetic
        ;;
    *)
        echo "Usage: $0 {start|stop|restart|shell|logs}"
        echo ""
        echo "  start   - Start Gazebo with forest world"
        echo "  stop    - Stop the container"
        echo "  restart - Restart the container"
        echo "  shell   - Open bash shell in container"
        echo "  logs    - Show container logs"
        exit 1
        ;;
esac
