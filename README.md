# Automated Ubuntu image building for Raspberry Pi 

This repository contains a simple script to automate the process of building custom Ubuntu images for the Raspberry Pi. It provides two ways of customizing the image:

1. Script file: A script file to be run inside [chroot](https://en.wikipedia.org/wiki/Chroot) during the image creation.
1. Cloud-init configuration file: A configuration file to be applied by [cloud-init](https://help.ubuntu.com/community/CloudInit#:~:text=cloud%2Dinit%20is%20the%20Ubuntu,setting%20a%20default%20locale) once the system boots up for the first time.

## Arguments

In this section, the arguments of the tool are described. All arguments are optional. 

1. `-a` `[armhf|arm64]`: Target architecture of image.
1. `-v` `[18.04.5|20.04.3]`: Target version of Ubuntu.
1. `-h` `[raspi|raspi2|raspi3|raspi4]`: Target hardware for image. It is important to provide the right value `[raspi2|raspi3|raspi4]` for Ubuntu 18.04.5 and `[raspi]` for Ubuntu 20.04.3. The value must align with available downloads from [https://cdimage.ubuntu.com/releases/](https://cdimage.ubuntu.com/releases/). 
1. `-s` `[path]`: Script file to customize image inside chroot.
1. `-c` `[path]`: Cloud-init configuration file to customize image after system boot.
1. `-o` `[path]`: Output image file.
1. `-q`: Enable virtualization with QEMU (unstable).

## Examples

In this section, two example usages are described.

1. Build an Ubuntu 18.04.5 image with a cloud-init file.
    ```bash
    sudo ./build.sh -a arm64 -v 18.04.5 -h raspi4 -s ./examples/script.sh
    ```

1. Build an Ubuntu 20.04.3 image with a script file and cloud-init file. Notice that the version of Raspberry Pi is not specified for Ubuntu 20.04.03.
    ```bash
    sudo ./build.sh -a arm64 -v 20.04.3 -h raspi -s ./examples/script.sh -c ./examples/cloud.cfg -q -o output.img.xz
    ```

## Virtualization

Out-of-the-box virtualization is possible using QEMU. However, the virtualization support for actions such as `apt-get upgrade` and `apt-get install` is unstable and frequently hangs. It is recommended to run the tool on the target architecture. 
