# GitHub Repository Plan

Repository:

```text
https://github.com/LiuAnclouds/XR-RoboOrchard-Piper-install.git
```

## Final files

```text
XR-RoboOrchard-Piper-install/
??? Dockerfile.holobrain
??? 01_build_image.sh
??? 02_run_container.sh
??? 03_install_roboorchard_xr.sh
??? 04_install_piper_sdk.sh
??? 05_verify_install.sh
??? README.md
??? patches/
    ??? pybind_patch.cpp
```

## Clone command on robot host

```bash
mkdir -p ~/SOP
cd ~/SOP
git clone https://github.com/LiuAnclouds/XR-RoboOrchard-Piper-install.git deploy
cd deploy
```

## Install order

```bash
bash 01_build_image.sh
bash 02_run_container.sh
bash 03_install_roboorchard_xr.sh
bash 04_install_piper_sdk.sh
bash 05_verify_install.sh
```

## Upstream repositories cloned by 02_run_container.sh

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
INSTALL_TORCH=0 bash 01_build_image.sh  # optional skip
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
