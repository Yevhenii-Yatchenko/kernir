# FAST-LIVO2 Container

## Overview

FAST-LIVO2 (Fast LiDAR-Inertial-Visual Odometry) provides real-time localization and mapping by fusing LiDAR, IMU, and camera data.

**Container:** `fast_livo`
**Image:** `fast-livo2`

## Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                    fast_livo container                       │
├─────────────────────────────────────────────────────────────┤
│  Inputs (from Gazebo):          Outputs:                    │
│  ├─ /velodyne_points            ├─ /Odometry                │
│  ├─ /imu/data                   ├─ /mavros/vision_pose/pose │
│  └─ /camera/image_raw           ├─ /path                    │
│                                 ├─ /Laser_map               │
│  Components:                    ├─ /cloud_registered        │
│  ├─ fastlivo_mapping node       └─ /rgb_img                 │
│  └─ pose_to_odom converter                                  │
└─────────────────────────────────────────────────────────────┘
```

## Input Topics (Subscribed)

| Topic | Message Type | Source | Description |
|-------|--------------|--------|-------------|
| `/velodyne_points` | `sensor_msgs/PointCloud2` | Gazebo | VLP-16 LiDAR point cloud |
| `/imu/data` | `sensor_msgs/Imu` | Gazebo | IMU orientation and acceleration |
| `/camera/image_raw` | `sensor_msgs/Image` | Gazebo | Forward camera feed |

## Output Topics (Published)

| Topic | Message Type | Rate | Description |
|-------|--------------|------|-------------|
| `/Odometry` | `nav_msgs/Odometry` | ~10Hz | Converted odometry (for web viewer) |
| `/mavros/vision_pose/pose` | `geometry_msgs/PoseStamped` | ~10Hz | Raw pose output |
| `/path` | `nav_msgs/Path` | ~10Hz | Trajectory history |
| `/Laser_map` | `sensor_msgs/PointCloud2` | ~1Hz | Accumulated point cloud map |
| `/cloud_registered` | `sensor_msgs/PointCloud2` | ~10Hz | Current registered cloud |

## Testing Commands

Run these inside the FAST-LIVO container:

```bash
docker exec -it fast_livo bash
```

### Check Container Status

```bash
# From host
docker ps --filter name=fast_livo
docker compose logs fast-livo --tail 20
```

### Check Input Topics

```bash
# Verify inputs are available
rostopic list | grep -E "velodyne|imu|camera"

# Check LiDAR rate (should be ~10Hz)
rostopic hz /velodyne_points

# Check IMU rate (should be ~200Hz)
rostopic hz /imu/data

# Check camera
rostopic hz /camera/image_raw
```

### Check Output Topics

```bash
# Verify FAST-LIVO outputs exist
rostopic list | grep -E "Odometry|path|Laser_map|vision_pose"

# Check odometry rate (should be ~10Hz)
rostopic hz /Odometry

# View current pose
rostopic echo /Odometry/pose/pose -n 1

# Check path length
rostopic echo /path/poses --noarr -n 1
```

### Verify Data Flow

```bash
# One-liner to check all critical topics
for topic in /velodyne_points /imu/data /Odometry; do
  echo "=== $topic ===" && timeout 2 rostopic hz $topic 2>&1 | head -3
done
```

## Expected Data

### Odometry Output

| Field | Description | Expected Value |
|-------|-------------|----------------|
| `header.frame_id` | Reference frame | `map` |
| `child_frame_id` | Robot frame | `base_link` |
| `pose.pose.position` | XYZ position | Meters from origin |
| `pose.pose.orientation` | Quaternion | Normalized (w near 1 when level) |

### Console Output

When running correctly, you should see periodic output like:

```
+-------------------------------------------------------------+
|                         VIO Time                            |
+-------------------------------------------------------------+
| Sparse Map Size               | 5000+                       |
| Average Total Time            | 0.000xxx                    |
+-------------------------------------------------------------+
```

## Configuration

Custom configs are mounted from `docker_data/fast-livo/config/`:

| File | Purpose |
|------|---------|
| `gazebo_vlp16.yaml` | LiDAR/IMU parameters and extrinsics |
| `camera_gazebo.yaml` | Camera intrinsics |
| `mapping_gazebo_vlp16.launch` | Launch file for Gazebo setup |
| `pose_to_odom.py` | Converts PoseStamped to Odometry |

## Troubleshooting

### Container exits immediately

```bash
# Check build logs
docker compose logs fast-livo | head -50

# Common causes:
# - Missing launch file (check config/ has mapping_gazebo_vlp16.launch)
# - Build failed (delete repos/ and restart)
```

### "No point!!!" messages

This means LiDAR data isn't being received:

```bash
# Check if Gazebo is publishing
rostopic hz /velodyne_points

# If 0Hz, check ros-gazebo container is running
docker ps --filter name=ros_gazebo
```

### Odometry not publishing

```bash
# Check if pose_to_odom converter is running
ps aux | grep pose_to_odom

# Check source topic
rostopic hz /mavros/vision_pose/pose
```

### High drift / bad odometry

1. Check IMU data is valid: `rostopic echo /imu/data -n 1`
2. Verify camera is publishing: `rostopic hz /camera/image_raw`
3. Check config extrinsics match your sensor setup

## Rebuild Container

```bash
# Full rebuild (clears cached repos)
docker run --rm -v ./docker_data/fast-livo/repos:/repos alpine rm -rf /repos/*
docker compose up -d --build fast-livo

# Quick restart (keeps cached repos)
docker compose restart fast-livo
```
