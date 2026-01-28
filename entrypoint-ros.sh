#!/bin/bash
set -e

# Source ROS
source /opt/ros/noetic/setup.bash

# Source Gazebo setup (sets proper GAZEBO_RESOURCE_PATH with shaders)
source /usr/share/gazebo/setup.bash

# Append project paths to Gazebo
export GAZEBO_MODEL_PATH=/root/catkin_ws/src/ardupilot_gazebo/models:/root/catkin_ws/src/ardupilot_gazebo/models_gazebo:/root/catkin_ws/src/PX4-SITL_gazebo-classic/models:$GAZEBO_MODEL_PATH
export GAZEBO_RESOURCE_PATH=/root/catkin_ws/src/ardupilot_gazebo:/root/catkin_ws/src/PX4-SITL_gazebo-classic:$GAZEBO_RESOURCE_PATH
export GAZEBO_PLUGIN_PATH=/root/catkin_ws/src/ardupilot_gazebo/build:$GAZEBO_PLUGIN_PATH

# Default world
WORLD=${GAZEBO_WORLD:-/root/catkin_ws/src/PX4-SITL_gazebo-classic/worlds/baylands.world}

# If first argument is "bash", open shell
if [ "$1" = "bash" ]; then
    exec bash
# If first argument is "gazebo", start Gazebo with optional world
elif [ "$1" = "gazebo" ]; then
    shift
    WORLD=${1:-$WORLD}
    echo "Starting Gazebo with world: $WORLD"
    exec roslaunch gazebo_ros empty_world.launch world_name:=$WORLD verbose:=true
# Default: just run whatever command was passed
else
    exec "$@"
fi
