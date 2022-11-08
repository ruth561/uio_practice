#! /bin/bash

# 現在のKernelに対応するversionのヘッダをサーチする
apt search linux-headers-"$(uname -r)"

# インストールする
sudo apt install linux-headers-"$(uname -r)"
