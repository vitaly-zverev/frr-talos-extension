# Customized FRR talos system extension image for BGP routing on the Kubernetes host

***

FRR container is used for Routing on the Host, it also peers with Metallb BGP speaker, to receive route update of load balancer IPs from Metallb, then further send to Leaf routers. 

docker start script template [docker-start.j2](docker-start.j2) is substitued during docker image build, `/usr/lib/frr/docker-start` is then generated as container start script.

frr configuration template [frr.conf.j2](frr.conf.j2) is pre-built into container, variables in the template will be substituted during container start-up, with server local specific values, `/etc/frr/frr.conf` then gets generated out of it.

Following parameters are hardcoded, will be the same on each server, you should change them according to your network environment:

- `ASN_METALLB_LOCAL`: `4200099998`
- `ASN_METALLB_REMOTE`: `4200099999`
- `NAMESPACE_METALLB`: `metallb`
- `PEER_IP_LOCAL`: `192.168.250.254`
- `PEER_IP_REMOTE`: `192.168.250.255`
- `PEER_IP_PREFIX`: `31`
- `INTERFACE_MTU`: `1500`

> Above hardcoded variables are placed into container image as `/etc/frr/env.sh`, to be sourced by start script.

To make the FRR system extenion to work, following dynamic varialbes need to be configured in talos machine config:

- `NODE_IP`: This is basically the /32 node-ip on `lo` or `dummy0` , defined as environment variable from talos machine config
- `ASN_LOCAL`: frr local AS Number for upstream peering, defined as environment variable from talos machine config

Example machine config snippet:

```yaml
machine:
  env:
    ASN_LOCAL: 4200001001
    NODE_IP: 10.10.10.10
```

Build the image locally:

```
docker build -t frr-gobgp-talos-extension .
```

By default, entry-point of image adopet for goBGP, as seen from examples:

```
git clone https://github.com/vitaly-zverev/frr-talos-extension && cd frr-talos-extension

docker build -t frr-gobgp-talos-extension:1.5 --no-cache .

docker run -ti --rm --entrypoint=/rootfs/usr/local/lib/containers/frr/bin/gobgp frr-gobgp-talos-extension:1.5 --version
gobgp version 4.0.0

docker run -ti --rm --entrypoint=/rootfs/usr/local/lib/containers/frr/bin/gobgpd frr-gobgp-talos-extension:1.5 --version
gobgpd version 4.0.0


INSTALLER_IMAGE=$(uuidgen) && echo $INSTALLER_IMAGE &&  docker tag frr-gobgp-talos-extension:1.5 ttl.sh/$INSTALLER_IMAGE:24h &&  docker push ttl.sh/$INSTALLER_IMAGE:24h
2954d0b4-4d39-485c-8b23-c7522953b2e6
The push refers to repository [ttl.sh/2954d0b4-4d39-485c-8b23-c7522953b2e6]
8e266b1792c5: Pushed
f320f020fa9d: Pushed
b8c9741a5401: Pushed
78b42d85a14c: Mounted from 336efdc8-f5ba-46d4-920b-60a4df886462
de1797da4e55: Pushed
5e7cfc31108a: Pushed
24h: digest: sha256:56eb299ce559f5b59ef3a6b08df683970478b59bb121283ed05216a71d05a517 size: 1572

docker run -ti --rm -v "$PWD/out":/out ghcr.io/siderolabs/imager:v1.11.3 installer --system-extension-image  ttl.sh/$INSTALLER_IMAGE:24h
skipped pulling overlay (no overlay)
profile ready:
arch: amd64
platform: metal
secureboot: false
version: v1.11.3
input:
  kernel:
    path: /usr/install/amd64/vmlinuz
  initramfs:
    path: /usr/install/amd64/initramfs.xz
  sdStub:
    path: /usr/install/amd64/systemd-stub.efi
  sdBoot:
    path: /usr/install/amd64/systemd-boot.efi
  baseInstaller:
    imageRef: ghcr.io/siderolabs/installer-base:v1.11.3
  systemExtensions:
    - imageRef: ttl.sh/2954d0b4-4d39-485c-8b23-c7522953b2e6:24h
output:
  kind: installer
  outFormat: raw
initramfs ready
kernel command line: talos.platform=metal console=tty0 init_on_alloc=1 slab_nomerge pti=on consoleblank=0 nvme_core.io_timeout=4294967295 printk.devkmsg=on selinux=1
UKI ready
installer container image ready
output asset path: /out/installer-amd64.tar

INSTALLER_IMAGE=$(uuidgen) && echo $INSTALLER_IMAGE &&  crane push out/installer-amd64.tar ttl.sh/$INSTALLER_IMAGE:24h
5da00d49-a6d3-4b09-8b81-7a185453fd6b
2025/11/07 22:34:06 pushed blob: sha256:19fb5f0870617a789b6cf4413ee13a12d1521f19fe10678762eb4286fbde5e3f
2025/11/07 22:34:54 pushed blob: sha256:43f6bd7f41213dd30b68759249fc04a1cae0b6a4becd5155e9809719d3919200
2025/11/07 22:40:08 pushed blob: sha256:3fdb9dd5f732aa28689e94596e253e7046f7b9bfaf21add7e209711c5c492dde
2025/11/07 22:40:10 ttl.sh/5da00d49-a6d3-4b09-8b81-7a185453fd6b:24h: digest: sha256:7981f139fecc608307d473edb72a16aa0d3a3146ad6a49c499f4dbb81480c4f3 size: 594
ttl.sh/5da00d49-a6d3-4b09-8b81-7a185453fd6b@sha256:7981f139fecc608307d473edb72a16aa0d3a3146ad6a49c499f4dbb81480c4f3


sudo --preserve-env=HOME talosctl cluster create --provisioner qemu  --name demo --with-debug  --install-image ghcr.io/siderolabs/installer:v1.11.3  --disk 8000
validating CIDR and reserving IPs
generating PKI and tokens
creating state directory in "/home/vzverev/.talos/clusters/demo"
creating network demo
creating load balancer
creating controlplane nodes
creating dhcpd
creating worker nodes
renamed talosconfig context "demo" -> "demo-37"
waiting for API
bootstrapping cluster
waiting for etcd to be healthy: OK
waiting for etcd members to be consistent across nodes: OK
waiting for etcd members to be control plane nodes: OK
waiting for apid to be ready: OK
waiting for all nodes memory sizes: OK
waiting for all nodes disk sizes: OK
waiting for no diagnostics: OK
waiting for kubelet to be healthy: OK
waiting for all nodes to finish boot sequence: OK
waiting for all k8s nodes to report: OK
waiting for all control plane static pods to be running: OK
waiting for all control plane components to be ready: OK
waiting for all k8s nodes to report ready: OK
waiting for kube-proxy to report ready: OK
waiting for coredns to report ready: OK
waiting for all k8s nodes to report schedulable: OK

merging kubeconfig into "/home/vzverev/.kube/config"
renamed cluster "demo" -> "demo-47"
renamed auth info "admin@demo" -> "admin@demo-47"
renamed context "admin@demo" -> "admin@demo-47"
PROVISIONER           qemu
NAME                  demo
NETWORK NAME          demo
NETWORK CIDR          10.5.0.0/24
NETWORK GATEWAY       10.5.0.1
NETWORK MTU           1500
KUBERNETES ENDPOINT   https://10.5.0.1:6443

NODES:

NAME                  TYPE           IP         CPU    RAM      DISK
demo-controlplane-1   controlplane   10.5.0.2   2.00   2.1 GB   8.4 GB
demo-worker-1         worker         10.5.0.3   2.00   2.1 GB   8.4 GB


sudo --preserve-env=HOME talosctl upgrade  --debug --cluster demo --nodes 10.5.0.3 --image ttl.sh/5da00d49-a6d3-4b09-8b81-7a185453fd6b:24h
watching nodes: [10.5.0.3]
    * 10.5.0.3: post check passed
	
sudo --preserve-env=HOME talosctl services  --nodes 10.5.0.3
NODE       SERVICE      STATE     HEALTH   LAST CHANGE   LAST EVENT
10.5.0.3   apid         Running   OK       -5s ago       Health check successful
10.5.0.3   auditd       Running   OK       18s ago       Health check successful
10.5.0.3   containerd   Running   OK       18s ago       Health check successful
10.5.0.3   cri          Running   OK       -4s ago       Health check successful
10.5.0.3   dashboard    Running   ?        -3s ago       Process Process(["/sbin/dashboard"]) started with PID 2073
10.5.0.3   ext-frr      Waiting   ?        -14s ago      Error running Containerd(ext-frr), going to restart forever: task "ext-frr" failed: exit code 1
10.5.0.3   kubelet      Running   OK       -6s ago       Health check successful
10.5.0.3   machined     Running   OK       18s ago       Health check successful
10.5.0.3   syslogd      Running   OK       -2s ago       Health check successful
10.5.0.3   udevd        Running   OK       18s ago       Health check successful

sudo --preserve-env=HOME talosctl get ExtensionServiceConfig  --nodes 10.5.0.2,10.5.0.3 -o yaml

sudo --preserve-env=HOME talosctl logs ext-frr  --nodes 10.5.0.3 --tail -30 | grep  jinja2.exceptions
10.5.0.3: jinja2.exceptions.UndefinedError: 'NODE_IP' is undefined
10.5.0.3: jinja2.exceptions.UndefinedError: 'NODE_IP' is undefined
10.5.0.3: jinja2.exceptions.UndefinedError: 'NODE_IP' is undefined


sudo --preserve-env=HOME talosctl patch mc -p @frr-env.yaml --nodes 10.5.0.3
patched MachineConfigs.config.talos.dev/v1alpha1 at the node 10.5.0.3
Applied configuration without a reboot

sudo --preserve-env=HOME talosctl patch mc -p @frr-env.yaml --nodes 10.5.0.3
patched MachineConfigs.config.talos.dev/v1alpha1 at the node 10.5.0.3
Applied configuration without a reboot

sudo --preserve-env=HOME talosctl logs ext-frr  --nodes 10.5.0.3 --tail -30 | grep 'state -> up'
10.5.0.3: Nov  7 19:48:08 demo-worker-1 daemon.notice watchfrr[43]: [QDG3Y-BY5TN] bgpd state -> up : connect succeeded
10.5.0.3: Nov  7 19:48:09 demo-worker-1 daemon.notice watchfrr[43]: [QDG3Y-BY5TN] bfdd state -> up : connect succeeded
10.5.0.3: Nov  7 19:48:09 demo-worker-1 daemon.notice watchfrr[43]: [QDG3Y-BY5TN] mgmtd state -> up : connect succeeded
10.5.0.3: Nov  7 19:49:14 demo-worker-1 daemon.notice watchfrr[43]: [QDG3Y-BY5TN] zebra state -> up : connect succeeded
10.5.0.3: Nov  7 19:49:14 demo-worker-1 daemon.notice watchfrr[43]: [QDG3Y-BY5TN] mgmtd state -> up : connect succeeded
10.5.0.3: Nov  7 19:49:14 demo-worker-1 daemon.notice watchfrr[43]: [QDG3Y-BY5TN] bgpd state -> up : connect succeeded
10.5.0.3: Nov  7 19:49:14 demo-worker-1 daemon.notice watchfrr[43]: [QDG3Y-BY5TN] bfdd state -> up : connect succeeded
10.5.0.3: Nov  7 19:49:18 demo-worker-1 daemon.notice watchfrr[43]: [QDG3Y-BY5TN] staticd state -> up : connect succeeded

sudo --preserve-env=HOME talosctl cluster destroy --name demo --provisioner qemu
stopping VMs
stopping VM demo-worker-1
stopping VM demo-controlplane-1
removing dhcpd
removing load balancer
removing kms
removing network
removing siderolink agent
removing state directory
removing json logs




```


Original image (frr only) is available at `abckey/frr-talos-extension`
