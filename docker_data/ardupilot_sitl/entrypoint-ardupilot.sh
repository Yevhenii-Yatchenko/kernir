#!/bin/bash
set -e

cd /ardupilot

# Default values
VEHICLE=${ARDUPILOT_VEHICLE:-Rover}
FRAME=${ARDUPILOT_FRAME:-gazebo-rover}
HEADLESS=${ARDUPILOT_HEADLESS:-0}

# Build command arguments
ARGS="-v $VEHICLE -f $FRAME"

# Add console if not headless
if [ "$HEADLESS" = "0" ]; then
    ARGS="$ARGS --console"
fi

# Add any extra arguments passed to the container
if [ $# -gt 0 ]; then
    ARGS="$ARGS $@"
fi

echo "Starting ArduPilot SITL..."
echo "  Vehicle: $VEHICLE"
echo "  Frame: $FRAME"
echo "  Headless: $HEADLESS"

exec python Tools/autotest/sim_vehicle.py $ARGS
