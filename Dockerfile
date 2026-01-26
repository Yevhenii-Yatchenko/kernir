FROM osrf/ros:noetic-desktop-full

# Install additional packages
RUN apt-get update && apt-get install -y \
    python3-lxml \
    psmisc \
    x11-apps \
    && rm -rf /var/lib/apt/lists/*

# Create python symlink for legacy scripts
RUN ln -sf /usr/bin/python3 /usr/bin/python
