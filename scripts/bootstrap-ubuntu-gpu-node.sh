#!/usr/bin/env bash
set -euo pipefail

sudo apt-get update
sudo apt-get install -y \
  ca-certificates curl gnupg lsb-release software-properties-common \
  build-essential dkms "linux-headers-$(uname -r)" \
  git vim tmux htop iotop iftop iperf3 jq yq unzip \
  pciutils numactl hwloc fio sysstat nvme-cli ethtool

sudo swapoff -a
sudo sed -i.bak '/ swap / s/^/#/' /etc/fstab

cat <<'EOF' | sudo tee /etc/modules-load.d/k8s.conf
overlay
br_netfilter
EOF
sudo modprobe overlay
sudo modprobe br_netfilter

cat <<'EOF' | sudo tee /etc/sysctl.d/99-compute-center.conf
net.bridge.bridge-nf-call-iptables = 1
net.bridge.bridge-nf-call-ip6tables = 1
net.ipv4.ip_forward = 1
vm.max_map_count = 262144
fs.inotify.max_user_watches = 1048576
EOF
sudo sysctl --system

echo "Base packages and kernel settings are ready."
echo "Next: install NVIDIA driver, reboot, then run NVIDIA container toolkit commands from docs/04-installation-ubuntu.md."

