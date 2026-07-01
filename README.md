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

## Notes

- Run commands on the robot host.
- Default workspace path is `~/SOP`.
- This repository only installs and verifies the environment.
