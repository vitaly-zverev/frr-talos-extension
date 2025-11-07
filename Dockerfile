FROM quay.io/frrouting/frr:10.4.1 AS build_frr
RUN echo -e '\
export ASN_METALLB_LOCAL=4200099998 \n\
export ASN_METALLB_REMOTE=4200099999 \n\
export NAMESPACE_METALLB=metallb \n\
export PEER_IP_LOCAL=192.168.250.254 \n\
export PEER_IP_REMOTE=192.168.250.255 \n\
export PEER_IP_PREFIX=31 \n\
export PEER_V6ONLY=yes \n\
export INTERFACE_MTU=1500 \
' > /etc/frr/env.sh
COPY docker-start.j2 /usr/lib/frr/docker-start.j2
COPY daemons /etc/frr/daemons
COPY frr.conf.j2 /etc/frr/frr.conf.j2
COPY install_j2cli12.sh /install_j2cli12.sh
RUN apk add --no-cache --update-cache tcpdump gettext py3-pip curl lldpd iputils bind-tools busybox-extras mtr lshw jq git

# Из  шаблона /usr/lib/frr/docker-start.j2 готовим /usr/lib/frr/docker-start ( он указан вторым параметром tini в frr.yaml манифесте)
RUN bash /install_j2cli12.sh && source venv/bin/activate && source /etc/frr/env.sh && j2 -o /usr/lib/frr/docker-start /usr/lib/frr/docker-start.j2

FROM golang:1.24 AS build_gobgp


ENV CGO_ENABLED=0 \
    GOOS=linux \
    GOARCH=amd64

WORKDIR /src

RUN git clone https://github.com/osrg/gobgp.git . \
 && go build -o _out/gobgp  -ldflags="-s -w" ./cmd/gobgp \
 && go build -o _out/gobgpd  -ldflags="-s -w" ./cmd/gobgpd 

FROM scratch AS frr_and_gobgb
COPY --from=build_frr / /rootfs/usr/local/lib/containers/frr/
COPY frr.yaml /rootfs/usr/local/etc/containers/frr.yaml
COPY manifest.yaml /manifest.yaml

COPY --from=build_gobgp /src/_out/gobgpd /rootfs/usr/local/lib/containers/frr/bin/gobgpd
COPY --from=build_gobgp /src/_out/gobgp /rootfs/usr/local/lib/containers/frr/bin/gobgp
COPY gobgpd.toml  /rootfs/usr/local/etc/containers/gobgpd.toml

ENTRYPOINT ["/rootfs/usr/local/lib/containers/frr/bin/gobgpd","-f","/rootfs/usr/local/etc/containers/gobgpd.toml"]

