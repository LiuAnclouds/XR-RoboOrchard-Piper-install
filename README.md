# XR HoloBrain Piper Install

## 1. Clone

```bash
mkdir -p ~/SOP
cd ~/SOP

git clone https://github.com/LiuAnclouds/XR-HoloBrain-Piper-install.git deploy
cd deploy
```

## 2. Install Environment

```bash
bash build_holobrain_image.sh
bash run_holobrain_container.sh
bash install_main.sh
bash install_piper_sdk.sh
```

If you do not need Torch in the Docker image:

```bash
INSTALL_TORCH=0 bash build_holobrain_image.sh
bash run_holobrain_container.sh
bash install_main.sh
bash install_piper_sdk.sh
```

## Notes

- Run all commands on the S100 host.
- This README only covers environment setup.
- Starting PC Service or HoloBrain control is handled separately after installation.
- Default workspace path is `~/SOP`. Override with `SOP_DIR=/path/to/SOP` if needed.
