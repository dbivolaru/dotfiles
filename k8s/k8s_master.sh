# THIS IS NOT TESTED - DO NOT USE

# 0 - Certificates
# Admin Client Certificate
# Kubelet Client Certificates 1:n (per worker)
# Controller Manager Client Certificate
# Kube Proxy Client Certificate
# Scheduler Client Certificate
# Kubernetes API Server Certificate
# Service Account Key Pair

# 1 - Control plane specialization

dnf install kubernetes-master kubernetes-kubeadm kubernetes-client etcd

# 2 - Cluster configuration
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
kubeadm init --config clusterconfig.yml

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


# 4 - Install DNS support (TBD?)
kubectl apply -f https://storage.googleapis.com/kubernetes-the-hard-way/coredns-1.8.yaml



# Easy login for non-root user
mkdir -p $HOME/.kube
sudo cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
sudo chown $(id -u):$(id -g) $HOME/.kube/config

