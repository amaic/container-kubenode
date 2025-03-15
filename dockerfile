FROM amaic/systemd

RUN apt-get install -y wget jq yq 
RUN apt-get install -y bash-completion iproute2

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

EOD