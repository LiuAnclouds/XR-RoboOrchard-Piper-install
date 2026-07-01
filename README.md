# XR RoboOrchard Piper Install

## Install

```bash
mkdir -p ~/SOP
cd ~/SOP

git clone git@github.com:LiuAnclouds/XR-RoboOrchard-Piper-install.git deploy
cd deploy

bash 01_build_image.sh
bash 02_run_container.sh
bash 03_install_roboorchard_xr.sh
bash 04_install_piper_sdk.sh
bash 05_verify_install.sh
```

If GitHub SSH is not configured, clone with HTTPS instead:

```bash
git clone https://github.com/LiuAnclouds/XR-RoboOrchard-Piper-install.git deploy
```

If you do not need Torch in the Docker image:

```bash
INSTALL_TORCH=0 bash 01_build_image.sh
bash 02_run_container.sh
bash 03_install_roboorchard_xr.sh
bash 04_install_piper_sdk.sh
bash 05_verify_install.sh
```


To mount the projects under another container directory instead of `/moonxkj`:

```bash
CONTAINER_ROOT=/workspace bash 02_run_container.sh
CONTAINER_ROOT=/workspace bash 03_install_roboorchard_xr.sh
CONTAINER_ROOT=/workspace bash 04_install_piper_sdk.sh
CONTAINER_ROOT=/workspace bash 05_verify_install.sh
```


Common optional parameters:

```bash
SOP_DIR=~/SOP                  # host workspace directory
CONTAINER_ROOT=/moonxkj        # container mount root
DOCKER_NAME=holobrain          # container name
IMAGE_NAME=holobrain-dev:latest
ROS_DOMAIN_ID=2
```


## Notes

- The image is built with RoboOrchard native `projects/HoloBrain/dev/build.sh`.
- RoboOrchard is installed with its native `make dev-env`, `make install-editable`, `make ros2-dev-env`, and `make build` flow.

- Run commands on the robot host.
- Default workspace path is `~/SOP`.
- This repository only installs and verifies the environment.
