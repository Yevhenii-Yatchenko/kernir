#!/usr/bin/env python3
"""Relay node that fixes Gazebo velodyne per-point timestamps.

Gazebo's gpu_ray sensor captures all points instantaneously (no rotation),
so the per-point `time` field is always 0. FAST-LIVO2 detects this and falls
back to angle-based timestamp estimation (omega_l=3.61 deg/ms), which produces
wrong offsets (~200ms span) and causes motion undistortion to distort the
already-correct point cloud.

Fix: set the `time` field to a tiny positive value so FAST-LIVO2 uses it
directly (given_offset_time=true), resulting in near-zero curvature values
and no undistortion — correct for instantaneous capture.
"""

import rospy
import struct
from sensor_msgs.msg import PointCloud2

pub = None
TIME_BYTES = struct.pack('<f', 0.001)  # tiny positive value


def cb(msg):
    data = bytearray(msg.data)
    step = msg.point_step
    n = msg.width * msg.height
    # Set the time field (float32 at offset 18) for each point
    for i in range(n):
        offset = i * step + 18
        data[offset:offset + 4] = TIME_BYTES
    msg.data = bytes(data)
    pub.publish(msg)


rospy.init_node('lidar_timestamp_fix')
pub = rospy.Publisher('/velodyne_points', PointCloud2, queue_size=1)
rospy.Subscriber('/velodyne_points_raw', PointCloud2, cb, queue_size=1)
rospy.loginfo('lidar_timestamp_fix: relaying /velodyne_points_raw -> /velodyne_points')
rospy.spin()
