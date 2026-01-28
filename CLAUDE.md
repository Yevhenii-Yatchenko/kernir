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
# ROS catkin workspace (inside ROS container)
./docker.sh shell
cd /root/catkin_ws && catkin_make

# Running FAST-LIVO2
roslaunch fast_livo mapping_avia.launch

# Running Gazebo world
roslaunch gazebo_ros empty_world.launch world_name:=/root/catkin_ws/src/ardupilot_gazebo/worlds/baylands_rover.world

# ArduPilot SITL (inside ArduPilot container)
python Tools/autotest/sim_vehicle.py -v Rover -f gazebo-rover --console
```

## Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                    Docker Compose                            │
├──────────────────────────┬──────────────────────────────────┤
│   ros-noetic container   │    ardupilot-sitl container      │
│   ├─ Gazebo 11           │    ├─ ArduPilot Rover SITL       │
│   ├─ ROS Noetic          │    └─ MAVProxy                   │
│   ├─ FAST-LIVO2          │                                  │
│   └─ Velodyne plugins    │    Communicates via UDP:         │
│                          │    - FDM: ports 9002/9003        │
│   GPU: NVIDIA runtime    │    - MAVLink: port 14550         │
└──────────────────────────┴──────────────────────────────────┘
```

**Data Flow:**
1. Gazebo spawns `rover_ardupilot_vlp16` model with IMU + VLP-16 LiDAR
2. ArduPilot SITL receives IMU/FDM data, sends motor commands
3. FAST-LIVO2 subscribes to `/velodyne_points` for odometry/mapping

## Workspace Structure

```
workspace/                      # ROS catkin src (mounted at /root/catkin_ws/src)
├── FAST-LIVO2/                # LiDAR-Inertial-Visual Odometry
│   ├── src/                   # Core algorithms (vio.cpp, LIVMapper.cpp)
│   ├── launch/                # ROS launch files per sensor config
│   └── config/                # Sensor calibration YAML files
├── ardupilot_gazebo/          # Gazebo plugins for ArduPilot
│   ├── src/                   # ArduPilotPlugin.cc, sensors
│   ├── models/                # Vehicle models (rover_ardupilot_vlp16)
│   ├── worlds/                # Simulation worlds (baylands_rover.world)
│   └── models_gazebo/         # 210+ reusable Gazebo models
└── velodyne_simulator/        # VLP-16/HDL-32E sensor simulation
```

## Key Configuration

- **Default world:** `baylands_rover.world` (set in `entrypoint-ros.sh`)
- **ArduPilot vehicle:** Rover with gazebo-rover frame
- **LiDAR config:** VLP-16 publishing to `/velodyne_points`

## Git Submodules

Initialize all submodules before first use:
```bash
git submodule update --init --recursive
```

Submodules: FAST-LIVO2, ardupilot_gazebo, velodyne_simulator, gazebo-classic, PX4-SITL_gazebo-classic
