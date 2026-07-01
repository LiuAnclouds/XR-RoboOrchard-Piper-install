# GitHub Repository Plan

Repository:

```text
https://github.com/LiuAnclouds/XR-RoboOrchard-Piper-install.git
```

## Final files

```text
XR-RoboOrchard-Piper-install/
??? Dockerfile.holobrain
??? build_holobrain_image.sh
??? run_holobrain_container.sh
??? install_main.sh
??? install_piper_sdk.sh
??? start.sh
??? check.sh
??? README.md
??? patches/
    ??? pybind_patch.cpp
```

## Clone command on S100

```bash
mkdir -p ~/SOP
cd ~/SOP
git clone https://github.com/LiuAnclouds/XR-RoboOrchard-Piper-install.git deploy
cd deploy
```

## Install order

```bash
bash build_holobrain_image.sh
bash run_holobrain_container.sh
bash install_main.sh
bash install_piper_sdk.sh
# Optional after environment setup:
# bash start.sh
# bash check.sh
```

## Upstream repositories cloned by run_holobrain_container.sh

```text
https://github.com/HorizonRobotics/RoboOrchard.git
https://github.com/XR-Robotics/XRoboToolkit-PC-Service-Pybind.git
https://github.com/agilexrobotics/piper_sdk.git
```

## Docker runtime must match verified config

```bash
--network host
--ipc host
--pid host
--rm
--privileged
--shm-size=4g
-v /dev:/dev
-v "$SOP_DIR/RoboOrchard:/moonxkj/RoboOrchard"
-v "$SOP_DIR/XRoboToolkit-PC-Service-Pybind:/moonxkj/XRoboToolkit-PC-Service-Pybind"
-v "$SOP_DIR/piper_sdk:/moonxkj/piper_sdk"
```

## Torch

Use CPU-only PyTorch wheels. Do not pull NVIDIA/CUDA packages.

```bash
INSTALL_TORCH=0 bash build_holobrain_image.sh  # optional skip
```

## pybind patch

Use only:

```text
patches/pybind_patch.cpp
```

It replaces:

```text
XRoboToolkit-PC-Service-Pybind/bindings/py_bindings.cpp
```
