#!/home/wintery/kernir/.venv/bin/python3
"""
Monitor FAST-LIVO2 and raw LiDAR topics side by side.
Run from host: python3 monitor_topics.py

Requires: pip install roslibpy
"""
import time
import threading
import roslibpy

HOST = 'localhost'
PORT = 9090

TOPICS = {
    # Raw input
    '/velodyne_points':              'sensor_msgs/PointCloud2',
    # FAST-LIVO2 outputs (point clouds)
    '/cloud_registered':             'sensor_msgs/PointCloud2',
    '/cloud_effected':               'sensor_msgs/PointCloud2',
    '/Laser_map':                    'sensor_msgs/PointCloud2',
    # FAST-LIVO2 odometry
    '/aft_mapped_to_init':           'nav_msgs/Odometry',
}

stats = {}
lock = threading.Lock()


def make_callback(name, msg_type):
    def callback(msg):
        with lock:
            entry = stats.setdefault(name, {
                'count': 0, 'last_time': 0,
                'last_info': '', 'type': msg_type
            })
            entry['count'] += 1
            entry['last_time'] = time.time()

            if msg_type == 'sensor_msgs/PointCloud2':
                w = msg.get('width', 0)
                h = msg.get('height', 0)
                n = w * h
                frame = msg.get('header', {}).get('frame_id', '?')
                data = msg.get('data', '')
                data_len = len(data) if isinstance(data, (list, bytes)) else len(str(data))
                entry['last_info'] = f'pts={n:<6} frame={frame:<16} data_bytes~{data_len}'
            elif msg_type == 'nav_msgs/Odometry':
                pose = msg.get('pose', {}).get('pose', {})
                pos = pose.get('position', {})
                x = pos.get('x', 0)
                y = pos.get('y', 0)
                z = pos.get('z', 0)
                frame = msg.get('header', {}).get('frame_id', '?')
                entry['last_info'] = f'pos=({x:.2f}, {y:.2f}, {z:.2f}) frame={frame}'
    return callback


def display_loop():
    while True:
        time.sleep(1.0)
        now = time.time()
        print('\033[2J\033[H')  # clear screen
        print(f'=== FAST-LIVO2 Topic Monitor === {time.strftime("%H:%M:%S")}')
        print(f'{"TOPIC":<30} {"MSGS":>5} {"AGE":>6} {"INFO"}')
        print('-' * 100)
        with lock:
            for name in TOPICS:
                if name in stats:
                    s = stats[name]
                    age = now - s['last_time'] if s['last_time'] > 0 else -1
                    age_str = f'{age:.1f}s' if age >= 0 else 'never'
                    print(f'{name:<30} {s["count"]:>5} {age_str:>6} {s["last_info"]}')
                else:
                    print(f'{name:<30}     0  never (no messages yet)')
        print('-' * 100)
        print('Ctrl+C to stop')


def main():
    print(f'Connecting to rosbridge at ws://{HOST}:{PORT} ...')
    client = roslibpy.Ros(host=HOST, port=PORT)
    client.run()
    print('Connected!')

    for topic_name, msg_type in TOPICS.items():
        listener = roslibpy.Topic(client, topic_name, msg_type)
        listener.subscribe(make_callback(topic_name, msg_type))
        print(f'  subscribed: {topic_name}')

    t = threading.Thread(target=display_loop, daemon=True)
    t.start()

    try:
        while True:
            time.sleep(0.5)
    except KeyboardInterrupt:
        print('\nStopping...')
    finally:
        client.terminate()


if __name__ == '__main__':
    main()
