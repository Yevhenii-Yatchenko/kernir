#!/usr/bin/env python3
"""Verify FAST-LIVO2 timestamp handling. Runs once and exits.
Optionally appends result to a log file."""

import sys
import time
import struct
import math
import rospy
from sensor_msgs.msg import PointCloud2

OMEGA_L = 3.61
log_file = [sys.stdout]


def cb(msg):
    step = msg.point_step
    n = msg.width * msg.height
    ts = time.strftime('%H:%M:%S')

    # Check last point's time field
    last_time = struct.unpack_from('<f', msg.data, (n-1) * step + 18)[0]
    given = last_time > 0

    log_file[0].write('%s  Points: %d  given_offset_time: %s  last_time: %.6f\n' % (
        ts, n, given, last_time))

    if given:
        log_file[0].write('%s  OK: timestamp fix active, no fallback undistortion\n' % ts)
    else:
        log_file[0].write('%s  WARNING: fallback active, broken undistortion!\n' % ts)

    log_file[0].flush()
    rospy.signal_shutdown('done')


rospy.init_node('check_undistortion')

if len(sys.argv) > 1:
    log_file[0] = open(sys.argv[1], 'a', buffering=1)

rospy.Subscriber('/velodyne_points', PointCloud2, cb)
rospy.spin()
