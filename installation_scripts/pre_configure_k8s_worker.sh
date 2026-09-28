#!/usr/bin/env bash
# Prepare a worker node for kubeadm.
#
# Target: Kubernetes v1.37 on Ubuntu 22.04 / 24.04.
#
# What changed from the previous version of this script, and why:
#
#   apt.kubernetes.io and packages.cloud.google.com were frozen in September
#   2023 and switched off in March 2024. Any script still pointing at them
#   fails at `apt update`. The replacement is pkgs.k8s.io, and the repository
#   URL now contains the minor version, so upgrading between minors means
#   editing the sources file rather than just running apt upgrade.
#
#   apt-key and /etc/apt/trusted.gpg.d are deprecated. Keys belong in
#   /etc/apt/keyrings and are bound to one repository with signed-by.
#
set -euo pipefail

KUBE_VERSION="${KUBE_VERSION:-v1.37}"
NODE_NAME="${NODE_NAME:-k8sworker.ssktraining.com}"

echo "==> preparing worker node for Kubernetes ${KUBE_VERSION}"

# --- hostname and /etc/hosts -----------------------------------------------
sudo hostnamectl set-hostname "${NODE_NAME}"
if [ -f hostname.txt ]; then
  sudo tee -a /etc/hosts < hostname.txt >/dev/null
else
  echo "    hostname.txt not found; add master and worker entries to /etc/hosts yourself"
fi

# --- swap ------------------------------------------------------------------
# kubelet still refuses to start with swap on unless you opt in. Swap support
# reached beta in v1.28 (NodeSwap) but the default is still fail-on-swap, so
# this stays.
sudo swapoff -a
sudo sed -i '/\sswap\s/ s/^\(.*\)$/#\1/g' /etc/fstab

# --- kernel modules and sysctl ---------------------------------------------
sudo tee /etc/modules-load.d/k8s.conf >/dev/null <<'EOF'
overlay
br_netfilter
EOF

sudo modprobe overlay
sudo modprobe br_netfilter

sudo tee /etc/sysctl.d/k8s.conf >/dev/null <<'EOF'
net.bridge.bridge-nf-call-iptables  = 1
net.bridge.bridge-nf-call-ip6tables = 1
net.ipv4.ip_forward                 = 1
EOF

sudo sysctl --system >/dev/null

# --- container runtime (containerd) ----------------------------------------
sudo apt-get update
sudo apt-get install -y curl gnupg ca-certificates apt-transport-https

sudo install -m 0755 -d /etc/apt/keyrings
sudo curl -fsSL https://download.docker.com/linux/ubuntu/gpg \
  | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg
sudo chmod a+r /etc/apt/keyrings/docker.gpg

echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu $(. /etc/os-release && echo "$VERSION_CODENAME") stable" \
  | sudo tee /etc/apt/sources.list.d/docker.list >/dev/null

sudo apt-get update
sudo apt-get install -y containerd.io

# Use the systemd cgroup driver. On cgroup v2 (the default on Ubuntu 22.04+)
# kubelet and the runtime must agree, or pods start and then die with cgroup
# errors that read like something else entirely.
#
# The config layout differs between containerd 1.x and 2.x, but the key name
# does not, so this substitution works on both.
sudo mkdir -p /etc/containerd
containerd config default | sudo tee /etc/containerd/config.toml >/dev/null
sudo sed -i 's/SystemdCgroup = false/SystemdCgroup = true/' /etc/containerd/config.toml

sudo systemctl restart containerd
sudo systemctl enable containerd

# --- kubeadm, kubelet, kubectl ---------------------------------------------
sudo curl -fsSL "https://pkgs.k8s.io/core:/stable:/${KUBE_VERSION}/deb/Release.key" \
  | sudo gpg --dearmor -o /etc/apt/keyrings/kubernetes-apt-keyring.gpg

echo "deb [signed-by=/etc/apt/keyrings/kubernetes-apt-keyring.gpg] https://pkgs.k8s.io/core:/stable:/${KUBE_VERSION}/deb/ /" \
  | sudo tee /etc/apt/sources.list.d/kubernetes.list >/dev/null

sudo apt-get update
sudo apt-get install -y kubelet kubeadm kubectl
sudo apt-mark hold kubelet kubeadm kubectl

sudo systemctl enable --now kubelet

echo
echo "==> done. versions installed:"
kubeadm version -o short
kubectl version --client -o yaml | grep gitVersion | head -1
echo
echo "Next, join this node to the cluster using the command kubeadm printed"
echo "on the control plane. It looks like:"
echo
echo "  sudo kubeadm join k8smaster.ssktraining.com:6443 \\"
echo "    --token <token> \\"
echo "    --discovery-token-ca-cert-hash sha256:<hash>"
echo
echo "Lost it? On the control plane run:  kubeadm token create --print-join-command"
