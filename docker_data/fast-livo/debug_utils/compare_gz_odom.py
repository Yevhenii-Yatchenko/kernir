#!/usr/bin/env python3
"""Compare Gazebo ground truth vs FAST-LIVO2 odometry in real time.
Logs to file with timestamps. Writes one line per second to keep logs manageable."""

import sys
import time
import rospy
from gazebo_msgs.msg import ModelStates
from nav_msgs.msg import Odometry

gz_pos = [None]
gz_start = [None]
odom_start = [None]
last_log = [0]
log_file = [sys.stdout]


def gz_cb(msg):
    idx = msg.name.index('simple_rover')
    p = msg.pose[idx].position
    gz_pos[0] = (p.x, p.y, p.z)
    if gz_start[0] is None:
        gz_start[0] = gz_pos[0]


def odom_cb(msg):
    now = time.time()
    if now - last_log[0] < 1.0:
        return
    last_log[0] = now

    p = msg.pose.pose.position
    o = (p.x, p.y, p.z)
    g = gz_pos[0]
    if g is None:
        return
    if odom_start[0] is None:
        odom_start[0] = o
    # Relative displacement since start
    gd = (g[0]-gz_start[0][0], g[1]-gz_start[0][1], g[2]-gz_start[0][2])
    od = (o[0]-odom_start[0][0], o[1]-odom_start[0][1], o[2]-odom_start[0][2])
    # Error = difference in displacement
    ex, ey, ez = od[0]-gd[0], od[1]-gd[1], od[2]-gd[2]
    err = (ex**2 + ey**2 + ez**2)**0.5
    ts = time.strftime('%H:%M:%S')
    line = '%s  GZ_d: %+.3f %+.3f %+.3f  OD_d: %+.3f %+.3f %+.3f  Err: %.4f' % (
        ts, gd[0], gd[1], gd[2], od[0], od[1], od[2], err)
    log_file[0].write(line + '\n')
    log_file[0].flush()


rospy.init_node('compare_gz_odom')

if len(sys.argv) > 1:
    log_file[0] = open(sys.argv[1], 'a', buffering=1)

rospy.Subscriber('/gazebo/model_states', ModelStates, gz_cb)
rospy.Subscriber('/Odometry', Odometry, odom_cb)
rospy.loginfo('Comparing Gazebo ground truth vs odometry (1 Hz logging)')
rospy.spin()
