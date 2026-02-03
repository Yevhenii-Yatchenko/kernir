source /opt/ros/noetic/setup.bash
cat source /opt/ros/noetic/setup.bash
export GAZEBO_MODEL_PATH=/root/catkin_ws/src/forest_gen:$GAZEBO_MODEL_PATH
gazebo /root/catkin_ws/src/forest_gen/worlds/forest0.world
nvidia-smi
source /opt/ros/noetic/setup.bash
export GAZEBO_MODEL_PATH=/root/catkin_ws/src/forest_gen:$GAZEBO_MODEL_PATH
gazebo /root/catkin_ws/src/forest_gen/worlds/forest0.world
ps aux | grep gz
source /opt/ros/noetic/setup.bash
export GAZEBO_MODEL_PATH=/root/catkin_ws/src/forest_gen:$GAZEBO_MODEL_PATH
gazebo --verbose /root/catkin_ws/src/forest_gen/worlds/forest0.world
source /usr/share/gazebo/setup.bash
export GAZEBO_MODEL_PATH=/root/catkin_ws/src/forest_gen:$GAZEBO_MODEL_PATH
export GAZEBO_RESOURCE_PATH=/root/catkin_ws/src/forest_gen:$GAZEBO_RESOURCE_PATH
gazebo --verbose /root/catkin_ws/src/forest_gen/worlds/forest0.world
cd /root/catkin_ws/src/forest_gen
python3 genWorlds.py --numWorlds 1 --worldSize 40 --treeDensity 0.05
python3 -m pip install lxml
python3 -m ensurepip
python3 -m ensurepipapt update && apt install -y python3-lxml
apt update && apt install -y python3-lxml
python3 genWorlds.py --numWorlds 1 --worldSize 40 --treeDensity 0.05
python3 genWorlds.py --num_worlds 1 --world_length 40 --tree_density 0.05
cd /root/catkin_ws/src/forest_gen
python3 genWorlds.py --num_worlds 1 --world_length 40 --tree_density 0.02
cd /root/catkin_ws/src/forest_gen
python3 genWorlds.py --num_worlds 1 --world_length 40 --tree_density 0.02
ps aux | grep gz
cd /root/catkin_ws/src/ardupilot_gazebo
mkdir -p build && cd build
cmake ..
make -j16
ls -la /root/catkin_ws/src/ardupilot_gazebo/build/libArduPilotPlugin.so
echo $GAZEBO_PLUGIN_PATH
netstat -tulpn | grep 900 || ss -tulpn | grep 900
apt install netstat ss
apt update && apt install -y python3-pip python3-dev
cd /root/catkin_ws/src/ardupilot
python3 -m venv venv
apt install python3.8-venv
python3 -m venv venv
source venv/bin/activate
pip install empy==3.3.4 pymavlink MAVProxy pexpect future
./Tools/autotest/sim_vehicle.py -v Rover -f gazebo-rover --model JSON --console
apt install -y git
./Tools/autotest/sim_vehicle.py -v Rover -f gazebo-rover --model JSON --console
export GIT_VERSION="unknown"
./Tools/autotest/sim_vehicle.py -v Rover -f gazebo-rover --model JSON --console
cd /root/catkin_ws/src/ardupilo
cd /root/catkin_ws/src/ardupilot
./waf configure --board sitl --disable-gccdeps
./waf configure --board sitl 
./waf build --target bin/ardurover -j16
./waf build --target bin/ardurover -j8
git
dpkg -l | grep husky
find /opt/ros /usr -name "*husky*gazebo*.so" 2>/dev/null
dpkg -L ros-noetic-husky-gazebo | grep -E "\.so|plugin"
apt-cache search husky | grep -i gazebo
find /opt/ros -name "*gazebo*plugin*.so" 2>/dev/null | head -10 
cd /root/catkin_ws
catkin_make
cd /root/catkin_ws && catkin_make
cat /usr/local/lib/cmake/Sophus/SophusConfig.cmake
cd /root/catkin_ws
ll
ls -la /usr/local/lib/cmake/Sophus/
cat /usr/local/lib/cmake/Sophus/SophusConfig.cmake
cmake --find-package -DNAME=Sophus -DCOMPILER_ID=GNU -DLANGUAGE=CXX -DMODE=EXIST
rostopic hz /imu/data
grep -n "RECV" /root/catkin_ws/src/ardupilot_gazebo/src/ArduPilotPlugin.cc
cd /root/catkin_ws && catkin_make
cd /root/catkin_ws/src/ardupilot_gazebo/build
make -j16
exit
cd /root/catkin_ws/src/ardupilot_gazebo/build && make -j16
grep -A2 "multiplier\|offset" /root/catkin_ws/src/ardupilot_gazebo/models/rover_ardupilot_vlp16/model.sdf | head -20
ll
cd ~
ll
cd .gazebo/
ll
cd models/
ll
cd baylands/
ll
cd ../../
cd -
ll
cat model.sdf 
ll
cd media/
ll
cd ..
ll
top
