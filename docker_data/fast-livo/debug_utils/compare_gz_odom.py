#!/usr/bin/env python3
"""Compare Gazebo ground truth vs FAST-LIVO2 odometry in real time.
Logs to file with timestamps. Writes one line per second to keep logs manageable.

Tracks both position and yaw to isolate rotational drift (e.g. during tank turns).

Parses /gazebo/model_states as raw bytes to avoid gazebo_msgs dependency."""

import sys
import time
import math
import struct
from io import BytesIO
import rospy
from rospy.msg import AnyMsg
from nav_msgs.msg import Odometry

gz_pos = [None]
gz_yaw = [None]
gz_start = [None]
gz_yaw_start = [None]
odom_start = [None]
odom_yaw_start = [None]
last_log = [0]
log_file = [sys.stdout]


def quat_to_yaw(qx, qy, qz, qw):
    """Extract yaw (rotation around Z) from quaternion."""
    siny_cosp = 2.0 * (qw * qz + qx * qy)
    cosy_cosp = 1.0 - 2.0 * (qy * qy + qz * qz)
    return math.atan2(siny_cosp, cosy_cosp)


def angle_diff(a, b):
    """Shortest signed angle difference (a - b), wrapped to [-pi, pi]."""
    d = a - b
    while d > math.pi:
        d -= 2 * math.pi
    while d < -math.pi:
        d += 2 * math.pi
    return d


def gz_cb(msg):
    # Parse ModelStates manually — no gazebo_msgs needed
    buf = BytesIO()
    msg.serialize(buf)
    raw = buf.getvalue()

    off = 0
    n_names = struct.unpack_from('<I', raw, off)[0]
    off += 4
    names = []
    for _ in range(n_names):
        slen = struct.unpack_from('<I', raw, off)[0]
        off += 4
        names.append(raw[off:off+slen].decode())
        off += slen

    try:
        idx = names.index('simple_rover')
    except ValueError:
        return

    # Pose array: each Pose = 7 doubles (x,y,z, qx,qy,qz,qw) = 56 bytes
    n_poses = struct.unpack_from('<I', raw, off)[0]
    off += 4
    pose_off = off + idx * 56
    x, y, z, qx, qy, qz, qw = struct.unpack_from('<ddddddd', raw, pose_off)

    gz_pos[0] = (x, y, z)
    gz_yaw[0] = quat_to_yaw(qx, qy, qz, qw)
    if gz_start[0] is None:
        gz_start[0] = gz_pos[0]
        gz_yaw_start[0] = gz_yaw[0]


def odom_cb(msg):
    now = time.time()
    if now - last_log[0] < 1.0:
        return
    last_log[0] = now

    p = msg.pose.pose.position
    q = msg.pose.pose.orientation
    o = (p.x, p.y, p.z)
    o_yaw = quat_to_yaw(q.x, q.y, q.z, q.w)

    g = gz_pos[0]
    g_yaw = gz_yaw[0]
    if g is None:
        return
    if odom_start[0] is None:
        odom_start[0] = o
        odom_yaw_start[0] = o_yaw

    # Relative displacement since start
    gd = (g[0]-gz_start[0][0], g[1]-gz_start[0][1], g[2]-gz_start[0][2])
    od = (o[0]-odom_start[0][0], o[1]-odom_start[0][1], o[2]-odom_start[0][2])
    # Position error
    ex, ey, ez = od[0]-gd[0], od[1]-gd[1], od[2]-gd[2]
    pos_err = (ex**2 + ey**2 + ez**2)**0.5

    # Yaw: cumulative change from start
    gz_dyaw = angle_diff(g_yaw, gz_yaw_start[0])
    od_dyaw = angle_diff(o_yaw, odom_yaw_start[0])
    yaw_err = angle_diff(od_dyaw, gz_dyaw)

    ts = time.strftime('%H:%M:%S')
    line = (
        '%s  GZ_d: %+.3f %+.3f %+.3f  OD_d: %+.3f %+.3f %+.3f  '
        'PosErr: %.4f  GZ_yaw: %+.1f  OD_yaw: %+.1f  YawErr: %+.1f' % (
            ts, gd[0], gd[1], gd[2], od[0], od[1], od[2],
            pos_err,
            math.degrees(gz_dyaw), math.degrees(od_dyaw),
            math.degrees(yaw_err)))
    log_file[0].write(line + '\n')
    log_file[0].flush()


rospy.init_node('compare_gz_odom')

if len(sys.argv) > 1:
    log_file[0] = open(sys.argv[1], 'a', buffering=1)

rospy.Subscriber('/gazebo/model_states', AnyMsg, gz_cb)
rospy.Subscriber('/Odometry', Odometry, odom_cb)
rospy.loginfo('Comparing Gazebo ground truth vs odometry — position + yaw (1 Hz)')
rospy.spin()
