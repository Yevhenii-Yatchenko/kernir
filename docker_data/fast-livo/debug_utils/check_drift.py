#!/usr/bin/env python3
"""Monitor odometry drift from starting position.
Logs to file with timestamps. Writes one line per second."""

import sys
import time
import rospy
from nav_msgs.msg import Odometry

start = [None]
last_log = [0]
log_file = [sys.stdout]


def cb(msg):
    now = time.time()
    p = msg.pose.pose.position
    if start[0] is None:
        start[0] = (p.x, p.y, p.z)
        ts = time.strftime('%H:%M:%S')
        log_file[0].write('%s  Starting position: %.3f %.3f %.3f\n' % (ts, p.x, p.y, p.z))
        log_file[0].flush()
        return
    if now - last_log[0] < 1.0:
        return
    last_log[0] = now
    dx = p.x - start[0][0]
    dy = p.y - start[0][1]
    dz = p.z - start[0][2]
    dist = (dx**2 + dy**2 + dz**2)**0.5
    ts = time.strftime('%H:%M:%S')
    log_file[0].write('%s  Drift: x=%+.4f y=%+.4f z=%+.4f  total=%.4fm\n' % (ts, dx, dy, dz, dist))
    log_file[0].flush()


rospy.init_node('check_drift')

if len(sys.argv) > 1:
    log_file[0] = open(sys.argv[1], 'a', buffering=1)

rospy.Subscriber('/Odometry', Odometry, cb)
rospy.spin()
