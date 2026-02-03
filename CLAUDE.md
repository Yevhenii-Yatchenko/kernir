# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

Robotics simulation project for autonomous rover development with LiDAR-Inertial-Visual odometry. Integrates ArduPilot SITL with Gazebo simulation and FAST-LIVO2 perception.

**Core Stack:** ROS Noetic, Gazebo 11, ArduPilot SITL, FAST-LIVO2, Docker

## Common Commands

All development uses Docker containers. Use the helper script:

```bash
./docker.sh start              # Start containers (Gazebo + ArduPilot)
./docker.sh stop               # Stop all containers
./docker.sh ardupilot          # Run ArduPilot with MAVProxy console
./docker.sh shell              # Bash into ROS container
./docker.sh shell-ardupilot    # Bash into ArduPilot container
./docker.sh logs               # Follow all container logs
./docker.sh status             # Show container status
```

### Building Inside Containers

```bash
# FAST-LIVO2 builds automatically on first start
# To rebuild manually:
docker exec -it fast_livo bash
cd /root/catkin_ws && catkin_make

# FAST-LIVO2 launches automatically via docker-compose
# To run manually:
docker exec -it fast_livo roslaunch fast_livo mapping_gazebo_vlp16.launch

# ArduPilot SITL (inside ArduPilot container)
python Tools/autotest/sim_vehicle.py -v Rover -f gazebo-rover --console
```

## Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                      Docker Compose                          │
├───────────────────┬───────────────────┬─────────────────────┤
│  ros-gazebo       │  ardupilot-sitl   │  fast-livo          │
│  ├─ Gazebo 11     │  ├─ Rover SITL    │  ├─ FAST-LIVO2      │
│  ├─ ROS Noetic    │  └─ MAVProxy      │  └─ pose_to_odom    │
│  └─ Velodyne      │                   │                     │
│                   │  UDP:             │  Subscribes:        │
│  GPU: NVIDIA      │  - FDM: 9002/9003 │  - /velodyne_points │
│                   │  - MAVLink: 14550 │  - /imu/data        │
│                   │                   │  Publishes:         │
│                   │                   │  - /Odometry        │
└───────────────────┴───────────────────┴─────────────────────┘
```

**Data Flow:**
1. Gazebo spawns `rover_ardupilot_vlp16` model with IMU + VLP-16 LiDAR + Camera
2. ArduPilot SITL receives IMU/FDM data, sends motor commands
3. FAST-LIVO2 subscribes to `/velodyne_points`, `/imu/data`, `/camera/image_raw` for odometry/mapping
4. Web viewer connects to `/Odometry` via rosbridge

## Docker Data Structure

```
docker_data/
├── fast-livo/                 # FAST-LIVO2 container data
│   ├── config/                # Custom configs (override defaults)
│   │   ├── gazebo_vlp16.yaml
│   │   ├── camera_gazebo.yaml
│   │   ├── mapping_gazebo_vlp16.launch
│   │   └── pose_to_odom.py    # PoseStamped -> Odometry converter
│   ├── repos/                 # Cached git repos (auto-cloned)
│   └── entrypoint.sh
├── ros_gazebo/                # Gazebo container data
└── ardupilot_sitl/            # ArduPilot container data
```

## Key Configuration

- **Default world:** `baylands_rover.world` (set in `entrypoint-gazebo.sh`)
- **ArduPilot vehicle:** Rover with gazebo-rover frame
- **LiDAR config:** VLP-16 publishing to `/velodyne_points`
- **FAST-LIVO2 config:** `docker_data/fast-livo/config/`
