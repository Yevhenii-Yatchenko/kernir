#!/bin/bash
set -e

# Source ROS
source /opt/ros/noetic/setup.bash

# Source Gazebo setup (sets proper GAZEBO_RESOURCE_PATH with shaders)
source /usr/share/gazebo/setup.bash

# Custom models and worlds (mounted from host)
export GAZEBO_MODEL_PATH=/root/gazebo_models:$GAZEBO_MODEL_PATH
export GAZEBO_RESOURCE_PATH=/root/gazebo_worlds:$GAZEBO_RESOURCE_PATH
# Plugin is installed to system path during docker build

# Default world
WORLD=/root/gazebo_worlds/urban_rover.world

# If first argument is "bash", open shell
if [ "$1" = "bash" ]; then
    exec bash
# If first argument is "gazebo", start Gazebo with optional world
elif [ "$1" = "gazebo" ]; then
    shift
    WORLD=${1:-$WORLD}
    echo "Starting gzserver with world: $WORLD"
    # Launch gzserver only — physics runs at full speed, never throttled by GUI
    roslaunch gazebo_ros empty_world.launch world_name:=$WORLD verbose:=true gui:=false &
    GZSERVER_PID=$!
    # Wait for ROS master to be ready
    echo "Waiting for ROS master..."
    until rostopic list > /dev/null 2>&1; do sleep 1; done
    echo "ROS master ready"
    # Launch gzclient as a separate process — can lag/lose focus without affecting physics
    echo "Starting gzclient (separate process, won't affect physics)"
    gzclient &
    # Launch rosbridge WebSocket server (port 9090) in background
    roslaunch rosbridge_server rosbridge_websocket.launch &
    # Launch camera viewer in background
    rosrun image_view image_view image:=/camera/image_raw &
    # Wait for gzserver to exit
    wait $GZSERVER_PID
# Default: just run whatever command was passed
else
    exec "$@"
fi
