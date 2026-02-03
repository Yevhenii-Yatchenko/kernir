#!/usr/bin/env python3
"""
Converts geometry_msgs/PoseStamped to nav_msgs/Odometry.
Subscribes to /mavros/vision_pose/pose, publishes to /Odometry.
"""
import rospy
from geometry_msgs.msg import PoseStamped
from nav_msgs.msg import Odometry

pub = None

def callback(pose_msg):
    odom = Odometry()
    odom.header = pose_msg.header
    odom.header.frame_id = "map"  # or "odom" depending on your setup
    odom.child_frame_id = "base_link"
    odom.pose.pose = pose_msg.pose
    # Covariance left as zeros (unknown)
    pub.publish(odom)

def main():
    global pub
    rospy.init_node('pose_to_odom_converter', anonymous=True)

    input_topic = rospy.get_param('~input_topic', '/mavros/vision_pose/pose')
    output_topic = rospy.get_param('~output_topic', '/Odometry')

    pub = rospy.Publisher(output_topic, Odometry, queue_size=10)
    rospy.Subscriber(input_topic, PoseStamped, callback)

    rospy.loginfo(f"Converting {input_topic} -> {output_topic}")
    rospy.spin()

if __name__ == '__main__':
    main()
