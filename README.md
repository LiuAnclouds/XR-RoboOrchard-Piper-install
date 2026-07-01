# XR HoloBrain Piper Install

This repository installs the S100 XR HoloBrain Piper environment using the same Docker runtime layout that was verified on the working machine.

## 0. Clone This Install Repository

On the S100 host:

```bash
mkdir -p /home/sunrise/moonxkj/SOP
cd /home/sunrise/moonxkj/SOP

git clone https://github.com/LiuAnclouds/XR-HoloBrain-Piper-install.git deploy
cd deploy
```

## 1. Source Policy

The deploy flow clones these upstream repositories when the local folders are missing:

```text
RoboOrchard                    -> https://github.com/HorizonRobotics/RoboOrchard.git
XRoboToolkit-PC-Service-Pybind -> https://github.com/XR-Robotics/XRoboToolkit-PC-Service-Pybind.git
piper_sdk                      -> https://github.com/agilexrobotics/piper_sdk.git
```

`XRoboToolkit-Teleop-Sample-Python` is not mounted by the verified runtime container. If the pybind setup flow needs it, it should create/use it from inside `XRoboToolkit-PC-Service-Pybind`.

## 2. Main Files

```text
Dockerfile.holobrain       # base Docker image, no piper_sdk baked in
build_holobrain_image.sh   # build image holobrain-dev:s100
run_holobrain_container.sh # clone missing upstream repos, then start container with verified mounts
install_all.sh             # install RoboOrchard, pybind, PC Service, and launch patch
install_piper_sdk.sh       # install piper_sdk separately
start.sh                   # start PC Service and HoloBrain control chain
check.sh                   # check processes, ports, ROS topics, CPU
patches/pybind_patch.cpp   # local full pybind replacement file
```

## 3. Install Order

```bash
cd /home/sunrise/moonxkj/SOP/deploy

bash build_holobrain_image.sh
bash run_holobrain_container.sh
bash install_all.sh
bash install_piper_sdk.sh
bash start.sh
bash check.sh
```

## 4. Docker Runtime Mounts

`run_holobrain_container.sh` matches the verified runtime container mounts:

```bash
-v /dev:/dev
-v "$SOP_DIR/RoboOrchard:/moonxkj/RoboOrchard"
-v "$SOP_DIR/XRoboToolkit-PC-Service-Pybind:/moonxkj/XRoboToolkit-PC-Service-Pybind"
-v "$SOP_DIR/piper_sdk:/moonxkj/piper_sdk"
```

It also uses:

```bash
--network host
--ipc host
--pid host
--rm
--privileged
--shm-size=4g
```

## 5. Torch CPU-only

The Dockerfile installs CPU-only PyTorch wheels:

```text
torch==2.8.0+cpu
torchvision==0.23.0+cpu
torchaudio==2.8.0+cpu
```

using:

```bash
--index-url https://download.pytorch.org/whl/cpu
```

This avoids pulling NVIDIA/CUDA packages.

If Torch is not needed, skip it during image build:

```bash
INSTALL_TORCH=0 bash build_holobrain_image.sh
```

## 6. pybind Patch

Use only this local full replacement file:

```text
patches/pybind_patch.cpp
```

`install_all.sh` copies it into the container with `docker cp`, then replaces:

```text
XRoboToolkit-PC-Service-Pybind/bindings/py_bindings.cpp
```

## 7. What install_all.sh Does

1. Installs RoboOrchard inside Docker.
2. Copies `patches/pybind_patch.cpp` to `XRoboToolkit-PC-Service-Pybind/bindings/py_bindings.cpp`, then builds pybind.
3. Installs host PC Service deb and rewrites `/opt/apps/roboticsservice/runService.sh`.
4. Patches HoloBrain `launch.yaml` with the current `RIGHT_READY` value.

## 8. Override Repository URLs

```bash
ROBO_REPO=https://github.com/HorizonRobotics/RoboOrchard.git \
PYBIND_REPO=https://github.com/XR-Robotics/XRoboToolkit-PC-Service-Pybind.git \
PIPER_REPO=https://github.com/agilexrobotics/piper_sdk.git \
bash run_holobrain_container.sh
```

## 9. Safety

`start.sh` loads HoloBrain `launch.yaml`. If `reset_ctrl` is enabled in that file, the arm may move to `RIGHT_READY`.
Make sure the robot is in a safe state before running `start.sh`.
