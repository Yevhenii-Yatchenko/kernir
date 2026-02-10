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

### Clean Rebuild

```bash
docker compose down
docker rmi ros-gazebo ardupilot-sitl fast-livo2 qgroundcontrol
docker compose build --no-cache
```

## Architecture

```
┌──────────────────────────────────────────────────────────────────┐
│                    Docker Compose (host network)                  │
├────────────────────┬────────────────────┬────────────────────────┤
│  ros-gazebo        │  ardupilot-sitl    │  fast-livo             │
│  ├─ Gazebo 11      │  ├─ Rover SITL     │  ├─ FAST-LIVO2         │
│  ├─ ROS Noetic     │  └─ MAVProxy       │  └─ pose_to_odom.py    │
│  ├─ Velodyne VLP16 │                    │                        │
│  └─ rosbridge:9090 │  UDP 9002/9003     │  Publishes:            │
│                    │  MAVLink:14550     │  ├─ /Odometry          │
│  GPU: NVIDIA       │                    │  ├─ /path              │
│                    │                    │  └─ /Laser_map         │
└────────────────────┴────────────────────┴────────────────────────┘
                              ▲
                              │ WebSocket :9090
                    ┌─────────┴─────────┐
                    │  Web Viewer       │
                    │  (index.html)     │
                    └───────────────────┘
```

**Data Flow:**
1. Gazebo spawns rover model with IMU + VLP-16 LiDAR + Camera
2. ArduPilot SITL receives FDM data via UDP, sends motor commands
3. FAST-LIVO2 subscribes to sensor topics for odometry/mapping
4. Web viewer connects via rosbridge WebSocket

## ROS Topics

### Sensor Topics (from Gazebo)

| Topic | Type | Rate | Description |
|-------|------|------|-------------|
| `/velodyne_points` | `sensor_msgs/PointCloud2` | 10Hz | VLP-16 LiDAR point cloud |
| `/imu/data` | `sensor_msgs/Imu` | 200Hz | IMU orientation & acceleration |
| `/camera/image_raw` | `sensor_msgs/Image` | 30Hz | Forward camera (640x480) |
| `/camera/camera_info` | `sensor_msgs/CameraInfo` | 30Hz | Camera intrinsics |

### FAST-LIVO2 Output Topics

| Topic | Type | Rate | Description |
|-------|------|------|-------------|
| `/Odometry` | `nav_msgs/Odometry` | 10Hz | Robot odometry (converted) |
| `/mavros/vision_pose/pose` | `geometry_msgs/PoseStamped` | 10Hz | Raw pose from FAST-LIVO2 |
| `/path` | `nav_msgs/Path` | 10Hz | Trajectory history |
| `/Laser_map` | `sensor_msgs/PointCloud2` | 1Hz | Accumulated point cloud map |
| `/cloud_registered` | `sensor_msgs/PointCloud2` | 10Hz | Current registered cloud |

## Network Ports

| Port | Protocol | Service | Description |
|------|----------|---------|-------------|
| 9002 | UDP | ArduPilot FDM | Flight dynamics input from Gazebo |
| 9003 | UDP | ArduPilot FDM | Flight dynamics output to Gazebo |
| 9090 | WebSocket | rosbridge | ROS bridge for web clients |
| 11311 | TCP | ROS Master | ROS core communication |
| 14550 | UDP | MAVLink | GCS connection (QGroundControl) |

## Environment Variables

### ArduPilot Container

| Variable | Default | Description |
|----------|---------|-------------|
| `ARDUPILOT_VEHICLE` | `Rover` | Vehicle type |
| `ARDUPILOT_FRAME` | `gazebo-rover` | Frame type |
| `ARDUPILOT_HEADLESS` | `0` | `1` = no console GUI |
| `ARDUPILOT_PARAMS` | `/params/arcade_4wd.parm` | Parameter file path |

### Gazebo Container

| Variable | Default | Description |
|----------|---------|-------------|
| `ROS_MASTER_URI` | `http://localhost:11311` | ROS master address |
| `NVIDIA_VISIBLE_DEVICES` | `all` | GPU access |

## Directory Structure

```
kernir/
├── Dockerfiles/               # Container definitions
│   ├── Dockerfile.gazebo
│   ├── Dockerfile.ardupilot
│   ├── Dockerfile.fastlivo
│   └── Dockerfile.qgroundcontrol
├── docker_data/
│   ├── fast-livo/
│   │   ├── config/            # FAST-LIVO2 configs
│   │   │   ├── gazebo_vlp16.yaml      # LiDAR/IMU params, extrinsics
│   │   │   ├── camera_gazebo.yaml     # Camera intrinsics
│   │   │   ├── mapping_gazebo_vlp16.launch
│   │   │   └── pose_to_odom.py        # PoseStamped -> Odometry
│   │   ├── repos/             # Cached git repos (auto-cloned)
│   │   └── entrypoint.sh
│   ├── ros_gazebo/
│   │   ├── models/            # Gazebo models (simple_rover)
│   │   ├── worlds/            # World files (baylands_rover.world)
│   │   └── entrypoint-gazebo.sh
│   ├── ardupilot_sitl/
│   │   ├── params/            # ArduPilot parameter files
│   │   │   ├── arcade_4wd.parm        # Skid steering (default)
│   │   │   └── ackermann.parm         # Ackermann steering
│   │   ├── sitl_data/         # Persisted SITL state
│   │   └── entrypoint-ardupilot.sh
│   └── qgroundcontrol/
│       └── entrypoint.sh
├── docker-compose.yml
├── docker.sh                  # Helper script
└── index.html                 # Web viewer
```

## Configuration

### Switching Steering Mode

```bash
# In docker-compose.yml, change ARDUPILOT_PARAMS:
ARDUPILOT_PARAMS=/params/ackermann.parm   # Ackermann steering
ARDUPILOT_PARAMS=/params/arcade_4wd.parm  # Skid steering (default)
```

### Changing World

Edit `docker_data/ros_gazebo/entrypoint-gazebo.sh`:
```bash
WORLD=/root/gazebo_worlds/your_world.world
```

### FAST-LIVO2 Tuning

Edit files in `docker_data/fast-livo/config/`:
- `gazebo_vlp16.yaml` - Topic names, extrinsics, algorithm params (fully commented)
- `camera_gazebo.yaml` - Camera intrinsics (focal length, distortion)

### FAST-LIVO2 Modes

Mode is determined automatically by `img_en` and `imu_en` in `gazebo_vlp16.yaml`:

| `img_en` | `lidar_en` | `imu_en` | Mode | Description |
|----------|------------|----------|------|-------------|
| 0 | 1 | true | ONLY_LIO | LiDAR + IMU (default, recommended) |
| 1 | 1 | true | LIVO | LiDAR + IMU + Camera (requires correct extrinsics) |
| 0 | 1 | false | ONLY_LO | LiDAR only (no IMU, less robust) |

**LIVO mode note:** `/cloud_registered` only publishes points that project into the camera FOV (~90° forward). The rest are discarded. With wrong camera-LiDAR extrinsics, zero points get published. Use ONLY_LIO for full 360° clouds.

**`/Laser_map` topic:** Advertised but never published in current FAST-LIVO2 code — it's a dead topic. Use `/cloud_registered` with browser accumulation instead.

### Sensor Placement & Extrinsics

IMU and LiDAR are co-located in the rover model (`model.sdf`) at the same position (`z=0.1877`) with no rotation offset. This allows identity extrinsics in FAST-LIVO2 config.

**Critical:** The IMU sensor in `model.sdf` must NOT have a rotation (e.g., `<pose>0 0 0 3.141593 0 0</pose>` would flip Y/Z axes). FAST-LIVO2 expects Z-up (ENU frame). A flipped IMU causes severe map distortion because gravity initialization points the wrong way.

Sensor positions in `model.sdf` (relative to `base_link`):

| Sensor | Link | Position (x, y, z) | Notes |
|--------|------|---------------------|-------|
| IMU | `imu_link` | 0, 0, 0.1877 | Co-located with LiDAR |
| LiDAR | `velodyne` | 0, 0, 0.1877 | 360° VLP-16 scan head |
| Camera | `camera_link` | 0.32, 0, 0.12 | Forward-facing, 90° FOV |

Extrinsics in `gazebo_vlp16.yaml`:

| Parameter | Value | Meaning |
|-----------|-------|---------|
| `extrinsic_T` | `[0, 0, 0]` | LiDAR-to-IMU translation (co-located) |
| `extrinsic_R` | `[1,0,0, 0,1,0, 0,0,1]` | LiDAR-to-IMU rotation (identity) |
| `Pcl` | `[0.32, 0, -0.0677]` | Camera-to-LiDAR translation |
| `Rcl` | `[1,0,0, 0,1,0, 0,0,1]` | Camera-to-LiDAR rotation (identity) |

If you move sensors apart, recalculate extrinsics: `extrinsic_T = LiDAR_pos - IMU_pos` (in IMU frame), `extrinsic_R` = rotation from LiDAR frame to IMU frame.

### LiDAR Tuning (model.sdf)

VLP-16 parameters in `model.sdf` under `<sensor type="gpu_ray">`:

| Parameter | Default | Description |
|-----------|---------|-------------|
| `update_rate` | 20 | Scan frequency (Hz). Real VLP-16: 5/10/20 |
| `horizontal/samples` | 1875 | Points per ring (360° sweep) |
| `vertical/samples` | 16 | Number of beams. 16=VLP-16, 32/64 for denser |
| `vertical/min_angle` | -0.261799 | Lower FOV bound (rad). -15° for VLP-16 |
| `vertical/max_angle` | 0.261799 | Upper FOV bound (rad). +15° for VLP-16 |
| `range/min` | 0.3 | Minimum range (m) |
| `range/max` | 131.0 | Maximum range (m) |
| `noise/stddev` | 0 | Range noise (m). Real VLP-16: ~0.003-0.008 |
| `plugin/min_range` | 0.9 | Plugin min range — should match `range/min` |
| `plugin/gaussianNoise` | 0 | Additional plugin noise (avoid double-noising) |

**Note:** `vertical/samples` must match `scan_line` in `gazebo_vlp16.yaml`.

## Key Configuration Files

| File | Purpose |
|------|---------|
| `docker_data/fast-livo/config/gazebo_vlp16.yaml` | FAST-LIVO2 sensor config, extrinsics, algorithm params |
| `docker_data/fast-livo/config/camera_gazebo.yaml` | Camera intrinsics for LIVO mode |
| `docker_data/ardupilot_sitl/params/*.parm` | ArduPilot vehicle parameters |
| `docker_data/ros_gazebo/models/simple_rover/model.sdf` | Robot model, sensors, physics |
| `docker_data/ros_gazebo/worlds/baylands_rover.world` | Simulation environment |
| `monitor_topics.py` | Live topic monitor (run from host, uses `.venv`) |
