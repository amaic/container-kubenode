FROM amaic/systemd

RUN apt-get install -y wget jq yq 

WORKDIR /install

ARG ARCHITECTURE

ARG RUNC_VERSION
RUN <<EOD

wget https://github.com/opencontainers/runc/releases/download/v${RUNC_VERSION}/runc.${ARCHITECTURE} \
--output-document=runc

install -m 755 ./runc /usr/local/sbin/runc

EOD

ARG CNI_VERSION
RUN <<EOD

wget https://github.com/containernetworking/plugins/releases/download/v${CNI_VERSION}/cni-plugins-linux-${ARCHITECTURE}-v${CNI_VERSION}.tgz \
--output-document=cni-plugins.tgz

mkdir --parents /opt/cni/bin
tar Cxzvf /opt/cni/bin cni-plugins.tgz

EOD

ARG CONTAINERD_VERSION
RUN <<EOD

wget https://github.com/containerd/containerd/releases/download/v${CONTAINERD_VERSION}/containerd-${CONTAINERD_VERSION}-linux-${ARCHITECTURE}.tar.gz \
--output-document=containerd.tar.gz

tar Cxzvf /usr/local containerd.tar.gz

mkdir --parents /usr/local/lib/systemd/system

wget https://raw.githubusercontent.com/containerd/containerd/main/containerd.service \
--output-document=/usr/local/lib/systemd/system/containerd.service

ln --symbolic /usr/local/lib/systemd/system/containerd.service /etc/systemd/system/multi-user.target.wants/containerd.service

mkdir --parents /etc/containerd

containerd config default | \
tomlq --toml-output \
'
(.plugins.["io.containerd.grpc.v1.cri"]) |= (
	(.sandbox_image) |= "registry.k8s.io/pause:3.10" |
	(.containerd.runtimes.runc.options.SystemdCgroup) |= true
)
' \
> /etc/containerd/config.toml

EOD

ARG KUBERNETES_VERSION
RUN <<EOD

wget https://dl.k8s.io/v${KUBERNETES_VERSION}/bin/linux/${ARCHITECTURE}/kubelet \
--output-document=kubelet

install -m 755 ./kubelet /usr/local/bin/kubelet

mkdir --parents /usr/lib/systemd/system/kubelet.service.d
mkdir --parents /etc/systemd/system/kubelet.service.d

cat <<EOB > /usr/lib/systemd/system/kubelet.service

[Unit]
Description=kubelet: The Kubernetes Node Agent
Documentation=https://kubernetes.io/docs/
Wants=network-online.target
After=network-online.target

[Service]
ExecStart=/usr/local/bin/kubelet
Restart=always
StartLimitInterval=0
RestartSec=10

[Install]
WantedBy=multi-user.target

EOB

ln --symbolic /usr/lib/systemd/system/kubelet.service /etc/systemd/system/multi-user.target.wants/kubelet.service

EOD



# wget https://dl.k8s.io/v${KUBERNETES_VERSION}/bin/linux/${ARCHITECTURE}/kubeadm \
# --output-document=kubeadm

# install -m 755 ./kubeadm /usr/local/bin/kubeadm

# wget https://dl.k8s.io/v${KUBERNETES_VERSION}/bin/linux/${ARCHITECTURE}/kubectl \
# --output-document=kubectl

# install -m 755 ./kubectl /usr/local/bin/kubectl


# RUN apt-get install -y bash-completion iproute2

