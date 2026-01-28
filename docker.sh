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
    up)
        # Build images and create containers
        xhost +local:docker
        ARDUPILOT_HEADLESS=1 $COMPOSE_CMD up -d --build
        echo ""
        echo "Gazebo + ArduPilot SITL starting..."
        echo ""
        echo "Commands:"
        echo "  ./docker.sh logs        - Show all logs"
        echo "  ./docker.sh ardupilot   - Restart ArduPilot with interactive console"
        echo "  ./docker.sh shell       - Open Gazebo container shell"
        ;;
    down)
        # Stop and remove containers
        $COMPOSE_CMD down
        echo "All containers stopped and removed."
        ;;
    stop)
        # Pause containers (keep state)
        $COMPOSE_CMD stop
        echo "Containers paused. Use './docker.sh start' to resume."
        ;;
    start)
        # Resume paused containers
        xhost +local:docker
        $COMPOSE_CMD start
        echo "Containers resumed."
        ;;
    restart)
        # Restart without rebuild
        $COMPOSE_CMD stop
        xhost +local:docker
        $COMPOSE_CMD start
        echo "Containers restarted."
        ;;
    rebuild)
        # Full rebuild from scratch
        $COMPOSE_CMD down
        xhost +local:docker
        ARDUPILOT_HEADLESS=1 $COMPOSE_CMD up -d --build
        echo ""
        echo "Containers rebuilt and started."
        ;;
    ardupilot)
        # Run ArduPilot interactively (with MAVProxy console)
        # First stop any existing ardupilot container
        $COMPOSE_CMD stop ardupilot 2>/dev/null
        $COMPOSE_CMD rm -f ardupilot 2>/dev/null
        xhost +local:docker
        echo "Starting ArduPilot with interactive console..."
        echo "Press Ctrl+C to stop"
        echo ""
        ARDUPILOT_HEADLESS=0 $COMPOSE_CMD run --rm ardupilot
        ;;
    shell)
        # Open bash shell in Gazebo container
        $COMPOSE_CMD exec ros-noetic /entrypoint.sh bash
        ;;
    shell-ardupilot)
        # Open bash shell in ArduPilot container
        $COMPOSE_CMD exec ardupilot bash
        ;;
    logs)
        # Show all container logs
        $COMPOSE_CMD logs -f
        ;;
    logs-gazebo)
        # Show Gazebo logs only
        $COMPOSE_CMD logs -f ros-noetic
        ;;
    logs-ardupilot)
        # Show ArduPilot logs only
        $COMPOSE_CMD logs -f ardupilot
        ;;
    status)
        # Show container status
        $COMPOSE_CMD ps
        ;;
    *)
        echo "Usage: $0 {up|down|stop|start|restart|rebuild|ardupilot|shell|logs|status}"
        echo ""
        echo "Lifecycle (destructive):"
        echo "  up              - Build images and create containers"
        echo "  down            - Stop and remove containers"
        echo "  rebuild         - Full rebuild from scratch (down + up)"
        echo ""
        echo "Lifecycle (preserves state):"
        echo "  stop            - Pause containers (keep state)"
        echo "  start           - Resume paused containers"
        echo "  restart         - Restart without rebuild"
        echo ""
        echo "Interactive:"
        echo "  ardupilot       - Run ArduPilot with interactive MAVProxy console"
        echo "  shell           - Open bash shell in Gazebo container"
        echo "  shell-ardupilot - Open bash shell in ArduPilot container"
        echo ""
        echo "Monitoring:"
        echo "  logs            - Show all logs"
        echo "  logs-gazebo     - Show Gazebo logs only"
        echo "  logs-ardupilot  - Show ArduPilot logs only"
        echo "  status          - Show container status"
        exit 1
        ;;
esac
