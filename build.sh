#!/bin/bash

dpdk_dir=$(readlink -f $(dirname $0))/dpdk
build_dir=$dpdk_dir/build
install_dir=$build_dir/install

echo "Caching sudo..."
sudo whoami

if [[ ! -d libcommon/bin ]]; then
    echo "Building libcommon..."
    git submodule update --init
    git -C libcommon checkout tags/v0.1
    make -C libcommon 
fi

# Fetch DPDK repository
if [[ ! -d $dpdk_dir || -z $(ls $dpdk_dir/*) ]]; then
    echo "Fetching DPDK repository from git..."
    git clone https://github.com/DPDK/dpdk.git $dpdk_dir
fi

# Checkout DPDK version tag
cd $dpdk_dir
git checkout v21.11

# Create the DPDK build dir
if [[ -d $build_dir ]]; then
    read -p "DPDK build dir exists. Do you want to delete it? [y|N]" ans
    if [[ ! -z $ans || $ans =~ [Yy] ]]; then
        rm $build_dir -rf
    fi
fi

echo "Configuring DPDK..."
meson -Denable_kmods=true -Dprefix=$install_dir build
cd build

# Make DPDK, install locally
echo "Making DPDK..."
ninja
sudo ninja install
sudo ldconfig
sudo pkg-config --modversion libdpdk
user=$USER
sudo chown $user $dpdk_dir -R
