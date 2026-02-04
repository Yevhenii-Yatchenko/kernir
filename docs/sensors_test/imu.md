# IMU Sensor Testing

## Overview

The simple_rover model includes an IMU sensor using the `libgazebo_ros_imu_sensor.so` plugin.

**Configuration:**
- Topic: `/imu/data`
- Update rate: 200Hz
- Frame: `imu_link`
- Message type: `sensor_msgs/Imu`

## Testing Commands

Run these inside the ROS container (`./docker.sh shell`):

### Check Topic Availability

```bash
# Check if the topic exists
source /opt/ros/noetic/setup.bash
rostopic list | grep imu

# See message type and structure
rostopic info /imu/data
rosmsg show sensor_msgs/Imu
```

### View IMU Data

```bash
# View raw IMU data (streams continuously)
rostopic echo /imu/data

# View just one message
rostopic echo /imu/data -n 1

# Check publish rate (should be ~200Hz)
rostopic hz /imu/data
```

### Sanity Checks

```bash
# When rover is stationary, linear_acceleration.z should be ~9.8 m/s²
rostopic echo /imu/data/linear_acceleration -n 5
```

## Expected Data

| Field | Description | Stationary Value |
|-------|-------------|------------------|
| `orientation` | Quaternion (x, y, z, w) | Reflects gravity direction |
| `angular_velocity` | rad/s around each axis | ~0 |
| `linear_acceleration` | m/s² | z ~9.8 (gravity) |

## Visualization

If display forwarding is available:

```bash
rqt_plot /imu/data/linear_acceleration/x:y:z
```

## Troubleshooting

If the topic doesn't appear:

1. Verify Gazebo is running with the model spawned
2. Check Gazebo topics: `gz topic -l`
3. Look for plugin load errors in Gazebo console output
