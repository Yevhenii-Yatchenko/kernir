#!/bin/bash
set -e

# Source ROS
source /opt/ros/noetic/setup.bash

CACHE_DIR="/cache/repos"
CATKIN_SRC="/root/catkin_ws/src"

# Clone or use cached FAST-LIVO2
if [ ! -d "$CACHE_DIR/FAST-LIVO2" ]; then
    echo "Cloning FAST-LIVO2..."
    git clone --depth 1 https://github.com/hku-mars/FAST-LIVO2.git "$CACHE_DIR/FAST-LIVO2"
else
    echo "Using cached FAST-LIVO2"
fi

# Clone or use cached rpg_vikit (FAST-LIVO2 fork with OpenCV4 support)
if [ ! -d "$CACHE_DIR/rpg_vikit" ]; then
    echo "Cloning rpg_vikit (FAST-LIVO2 fork)..."
    git clone --depth 1 https://github.com/xuankuzcr/rpg_vikit.git "$CACHE_DIR/rpg_vikit"
else
    echo "Using cached rpg_vikit"
fi

# Symlink repos to catkin workspace (-n prevents following existing symlinks)
ln -sfn "$CACHE_DIR/FAST-LIVO2" "$CATKIN_SRC/FAST-LIVO2"
ln -sfn "$CACHE_DIR/rpg_vikit" "$CATKIN_SRC/rpg_vikit"

# Copy custom configs if they exist (overrides defaults)
if [ -d "/config" ] && [ "$(ls -A /config 2>/dev/null)" ]; then
    echo "Copying custom configs..."
    cp -f /config/*.yaml "$CACHE_DIR/FAST-LIVO2/config/" 2>/dev/null || true
    cp -f /config/*.launch "$CACHE_DIR/FAST-LIVO2/launch/" 2>/dev/null || true
fi

# Build catkin workspace if not already built (check for actual binary)
if [ ! -f "/root/catkin_ws/devel/lib/fast_livo/fastlivo_mapping" ]; then
    echo "Building catkin workspace..."
    rm -rf /root/catkin_ws/devel /root/catkin_ws/build
    cd /root/catkin_ws
    catkin_make -j$(nproc)
fi

# Source catkin workspace
if [ -f /root/catkin_ws/devel/setup.bash ]; then
    source /root/catkin_ws/devel/setup.bash
fi

# Start LiDAR timestamp fix relay (Gazebo instantaneous scan -> proper timestamps)
if [ -f "/config/lidar_timestamp_fix.py" ]; then
    echo "Starting lidar_timestamp_fix relay..."
    python3 /config/lidar_timestamp_fix.py &
fi

# Start pose->odometry converter in background (if script exists)
if [ -f "/config/pose_to_odom.py" ]; then
    echo "Starting pose_to_odom converter..."
    python3 /config/pose_to_odom.py &
fi

exec "$@"
