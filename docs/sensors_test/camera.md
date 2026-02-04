# Camera Sensor Testing

## Overview

The rover model includes a forward-facing camera using the `libgazebo_ros_camera.so` plugin.

**Configuration:**
- Topic: `/camera/image_raw`
- Frame: `camera_link`
- Message type: `sensor_msgs/Image`

## Testing Commands

Run these inside the ROS container (`./docker.sh shell`):

### Check Topic Availability

```bash
# Check if the topic exists
source /opt/ros/noetic/setup.bash
rostopic list | grep camera

# See message type and structure
rostopic info /camera/image_raw
rosmsg show sensor_msgs/Image
```

### View Camera Data

```bash
# View raw image metadata (streams continuously)
rostopic echo /camera/image_raw

# View just one message header
rostopic echo /camera/image_raw/header -n 1

# Check publish rate
rostopic hz /camera/image_raw
```

### Visual Display

```bash
# Open image viewer window (requires X11 forwarding)
rosrun image_view image_view image:=/camera/image_raw
```

## Expected Data

| Field | Description | Expected Value |
|-------|-------------|----------------|
| `header.frame_id` | Reference frame | `camera_link` |
| `height` | Image height in pixels | Depends on config |
| `width` | Image width in pixels | Depends on config |
| `encoding` | Pixel format | `rgb8` or `bgr8` |

## Visualization

If display forwarding is available:

```bash
# View camera feed
rosrun image_view image_view image:=/camera/image_raw

# Or use rqt
rqt_image_view /camera/image_raw
```

## Troubleshooting

If the topic doesn't appear:

1. Verify Gazebo is running with the model spawned
2. Check Gazebo topics: `gz topic -l`
3. Look for plugin load errors in Gazebo console output
