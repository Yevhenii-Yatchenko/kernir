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
        # Grant X11 access for GUI apps (Gazebo, MAVProxy)
        xhost +local:docker
        # Start Gazebo first, then ArduPilot headless
        ARDUPILOT_HEADLESS=1 $COMPOSE_CMD up -d --build
        echo ""
        echo "Gazebo + ArduPilot SITL starting..."
        echo ""
        echo "Commands:"
        echo "  ./docker.sh logs        - Show all logs"
        echo "  ./docker.sh ardupilot   - Restart ArduPilot with interactive console"
        echo "  ./docker.sh shell       - Open Gazebo container shell"
        ;;
    stop)
        $COMPOSE_CMD down
        echo "All containers stopped."
        ;;
    restart)
        $COMPOSE_CMD down
        xhost +local:docker
        ARDUPILOT_HEADLESS=1 $COMPOSE_CMD up -d --build
        echo ""
        echo "Gazebo + ArduPilot SITL restarting..."
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
        echo "Usage: $0 {start|stop|restart|ardupilot|shell|logs|status}"
        echo ""
        echo "  start           - Start Gazebo + ArduPilot (headless)"
        echo "  stop            - Stop all containers"
        echo "  restart         - Restart all containers"
        echo "  ardupilot       - Run ArduPilot with interactive MAVProxy console"
        echo "  shell           - Open bash shell in Gazebo container"
        echo "  shell-ardupilot - Open bash shell in ArduPilot container"
        echo "  logs            - Show all logs"
        echo "  logs-gazebo     - Show Gazebo logs only"
        echo "  logs-ardupilot  - Show ArduPilot logs only"
        echo "  status          - Show container status"
        exit 1
        ;;
esac
