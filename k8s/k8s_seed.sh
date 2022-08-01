# 0 - Certificates
# Admin Client Certificate
# Kubelet Client Certificates 1:n (per worker)
# Controller Manager Client Certificate
# Kube Proxy Client Certificate
# Scheduler Client Certificate
# Kubernetes API Server Certificate
# Service Account Key Pair

# Disable swap - otherwise kubelet doesn't run
swapoff -a

# Load required kernel modules
modprobe overlay && modprobe br_netfilter

# Kernel module should be loaded on every reboot
cat <<EOF > /etc/modules-load.d/crio-net.conf
overlay
br_netfilter
EOF

# Network settings
cat <<EOF > /etc/sysctl.d/99-kubernetes-cri.conf
net.bridge.bridge-nf-call-iptables  = 1
net.ipv4.ip_forward                 = 1
net.bridge.bridge-nf-call-ip6tables = 1
EOF

cat << EOF > /etc/sysctl.d/99-kubelet-kernel.conf
kernel.panic         = 10
kernel.panic_on_oops = 1
EOF

# 1a - Base Setup (packages) - Development
# For listing versions: dnf module list cri-o
VERSION=1.24
dnf module enable cri-o:$VERSION
dnf install cri-o cri-tools runc

systemctl enable crio.service
systemctl start crio.service

dnf install kubernetes-node kubernetes-client containernetworking-plugins

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

# In a different terminal let's add a new pod
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

# Cleanup: move hello-world out of the "hot" folder; kubelet will remove all respective pods and containers
mv /etc/kubernetes/manifests/hello-world.yaml /etc/kubernetes/
crictl rmi $(crictl images -q) # images afaik remain (so we do manual cleanup)

# 1b - Base Setup (production FCOS)
#rpm-ostree install kubelet kubectl cri-o

# 2 - Control plane specialization
kubeadm init --config clusterconfig.yml

dnf install kubernetes-master kubernetes-kubeadm kubernetes-client etcd
# 2b - Production FCOS
#rpm-ostree install kubeadm kube-apiserver kube-controller-manager kube-scheduler etcd

systemctl enable kube-apiserver kube-controller-manager kube-scheduler
systemctl start kube-apiserver kube-controller-manager kube-scheduler

# TODO: Load Balancer haproxy (api-server) + vmWare NSX

# Network Fabric
# Production vmWare NSX-T => NCP
# Development:
#     - docker NAT
#     - brctl
#     - ovs-vsctl
#     - ip link add eth0p0 link eth0 type macvlan mode bridge 

# 3 - Worker node specialization
systemctl enable crio kubelet kube-proxy
systemctl start crio kubelet kube-proxy

cat <<- EOF >> /etc/crio/crio.conf
# Do not wipe containers and images after a reboot; w00t?
internal_wipe = false
apparmor_profile = "crio-default"
EOF

# Metrics port for CRI-O is on 9537 by default

# Make a standalone worker node (with no control plane)
cat <<- EOF > clusterconfig.yml
apiVersion: kubeadm.k8s.io/v1beta3
kind: ClusterConfiguration
kubernetesVersion: v1.24.0
networking:
  podSubnet: 10.244.0.0/16
---
apiVersion: kubeadm.k8s.io/v1beta3
kind: InitConfiguration
nodeRegistration:
  criSocket: unix:///var/run/crio/crio.sock
---
apiVersion: kubelet.config.k8s.io/v1beta1
kind: KubeletConfiguration
staticPodPath: /etc/kubernetes/manifests
EOF

# 4 - Install DNS support (TBD?)
kubectl apply -f https://storage.googleapis.com/kubernetes-the-hard-way/coredns-1.8.yaml



# Easy login for non-root user
mkdir -p $HOME/.kube
sudo cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
sudo chown $(id -u):$(id -g) $HOME/.kube/config

