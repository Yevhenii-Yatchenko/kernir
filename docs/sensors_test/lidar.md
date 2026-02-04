# LiDAR Sensor Testing

## Overview

The rover model includes a Velodyne VLP-16 LiDAR using the `libgazebo_ros_velodyne_gpu_laser.so` plugin.

**Configuration:**
- Topic: `/velodyne_points`
- Update rate: 10Hz
- Frame: `velodyne`
- Message type: `sensor_msgs/PointCloud2`
- Channels: 16 vertical beams
- Horizontal samples: 1875 (360° coverage)
- Range: 0.9m - 130m

## Testing Commands

Run these inside the ROS container (`./docker.sh shell`):

### Check Topic Availability

```bash
# Check if the topic exists
source /opt/ros/noetic/setup.bash
rostopic list | grep velodyne

# See message type and structure
rostopic info /velodyne_points
rosmsg show sensor_msgs/PointCloud2
```

### View LiDAR Data

```bash
# View raw point cloud metadata (streams continuously)
rostopic echo /velodyne_points

# View just one message header
rostopic echo /velodyne_points/header -n 1

# Check publish rate (should be ~10Hz)
rostopic hz /velodyne_points

# Check message bandwidth
rostopic bw /velodyne_points
```

## Expected Data

| Field | Description | Expected Value |
|-------|-------------|----------------|
| `header.frame_id` | Reference frame | `velodyne` |
| `height` | Number of rows | 1 (unorganized) |
| `width` | Number of points | ~30000 per scan |
| `fields` | Point fields | x, y, z, intensity, ring |

## Visualization

If display forwarding is available:

```bash
# View point cloud in RViz
rviz -d /path/to/config.rviz

# Or launch RViz and add PointCloud2 display manually
rviz
# Add > By topic > /velodyne_points > PointCloud2
# Set Fixed Frame to "velodyne"
```

## Troubleshooting

If the topic doesn't appear:

1. Verify Gazebo is running with the model spawned
2. Check Gazebo topics: `gz topic -l`
3. Look for plugin load errors in Gazebo console output
4. Ensure GPU is available (plugin uses `gpu_ray` sensor)
