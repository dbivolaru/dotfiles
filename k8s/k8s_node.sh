# Standalone kubelet with static pods

# 0 - OS Setup
# Disable swap - otherwise kubelet/pods won't perform
# If you use zram, then no need to do so; I updated the kubelet config to take it
swapoff -a

# Load required kernel modules & settings
modprobe overlay && modprobe br_netfilter
sysctl -w net.bridge.bridge-nf-call-iptables=1
sysctl -w net.ipv4.ip_forward=1
sysctl -w net.bridge.bridge-nf-call-ip6tables=1
sysctl -w kernel.panic=10
sysctl -w kernel.panic_on_oops=1

# Kernel module should be loaded on every reboot
cat <<EOF > /etc/modules-load.d/crio-net.conf
overlay
br_netfilter
EOF

# Network settings should be loaded on every reboot
cat <<EOF > /etc/sysctl.d/99-kubernetes-cri.conf
net.bridge.bridge-nf-call-iptables  = 1
net.ipv4.ip_forward                 = 1
net.bridge.bridge-nf-call-ip6tables = 1
EOF

# Kernel settings (kubelet also sets them itself; here just for reference explicitly)
cat << EOF > /etc/sysctl.d/99-kubelet-kernel.conf
kernel.panic         = 10
kernel.panic_on_oops = 1
EOF

# 1 - Base Setup (packages)
# For listing versions: dnf module list cri-o
VERSION=1.24
dnf module enable cri-o:$VERSION
dnf install cri-o cri-tools runc

systemctl enable crio
systemctl start crio

dnf install kubernetes-node kubernetes-client containernetworking-plugins

# 2 - Kubelet Setup

cat << EOF > /etc/kubernetes/kubelet.config
# https://kubernetes.io/docs/reference/config-api/kubelet-config.v1beta1/
apiVersion: kubelet.config.k8s.io/v1beta1
kind: KubeletConfiguration
registerNode: false
authentication:
  anonymous:
    enabled: true
  webhook:
    enabled: false
authorization:
  mode: AlwaysAllow
failSwapOn: false
staticPodPath: /etc/kubernetes/manifests
fileCheckFrequency: 20s
cgroupDriver: systemd
EOF


cp /usr/lib/systemd/system/kubelet.service /etc/systemd/system/
systemctl daemon-reload
systemctl enable kubelet
cat << EOF > /etc/kubernetes/config
# Logging to stderr will get recorded in systemd
KUBE_LOGTOSTDERR="--logtostderr=true"

# Default verbosity
KUBE_LOG_LEVEL="--v=2"
EOF
cat << EOF > /etc/kubernetes/kubelet
# As we run in standalone mode we specify a KubeletConfiguration directly
KUBELET_KUBECONFIG="--config=/etc/kubernetes/kubelet.config"

# Specify we are using CRI-O
KUBELET_ARGS="--container-runtime-endpoint=unix:///var/run/crio/crio.sock"

# Not needed - actual hostname
KUBELET_HOSTNAME=""

# Not needed - info server
KUBELET_ADDRESS=""
KUBELET_PORT=""
EOF

systemctl start kubelet

# What just happened? We have a standalone kubelet setup running.
# Anytime you create a .yaml file under /etc/kubernets/manifests/ it will get orchestrated


# From this point on is just optional (as example):

# 3a (Optional) - Example app (Hello World)

# Hello world!
cat << EOF > /etc/kubernetes/manifests/hello-world.yaml
# https://kubernetes.io/docs/reference/kubernetes-api/workload-resources/pod-v1/
apiVersion: v1
kind: Pod
metadata:
  creationTimestamp: null
  name: hello-world-pod
spec:
  containers:
  - image: ubuntu
    imagePullPolicy: IfNotPresent
    name: hello-world-container
    command: ["/bin/sh", "-c", "while :; do echo 'Hello World!'; sleep 60; done"]
status: {}
EOF

# Wait a bit; in the background the kubelet is reconciling the new pod definition with the existing running pods
sleep 60

# Kubelet should have (1) downloaded all images (2) created containers (3) configured pod
# We check that it's running
crictl pods
crictl ps

# Enter the container id here:
crictl attach <container_hexid>
# Wait a bit and see:
# Hello World!
# Disconnect with ^C

# Check logs
crictl logs <container_hexid>

# Exit kubelet from other terminal and confirm hello-world is STILL running :)
crictl ps

# 3b (Optional) - Cleanup: move hello-world out of the "hot" folder; kubelet will remove all respective pods and containers
rm /etc/kubernetes/manifests/hello-world.yaml
sleep 120
crictl rmi $(crictl images -q) # images afaik remain (so we do manual cleanup)

