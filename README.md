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
docker run --rm  frr-gobgp-talos-extension --version
gobgpd version 3.37.0


docker run --rm  frr-gobgp-talos-extension --log-level=debug
{"level":"info","msg":"gobgpd started","time":"2025-06-03T12:44:57Z"}
{"Topic":"Config","level":"info","msg":"Finished reading the config file","time":"2025-06-03T12:44:57Z"}
{"Key":"192.168.10.2","Topic":"config","level":"info","msg":"Add Peer","time":"2025-06-03T12:44:57Z"}
{"Key":"192.168.10.2","Topic":"Peer","level":"info","msg":"Add a peer configuration","time":"2025-06-03T12:44:57Z"}
{"Key":"192.168.10.3","Topic":"config","level":"info","msg":"Add Peer","time":"2025-06-03T12:44:57Z"}
{"Key":"192.168.10.3","Topic":"Peer","level":"info","msg":"Add a peer configuration","time":"2025-06-03T12:44:57Z"}
{"Key":"192.168.10.4","Topic":"config","level":"info","msg":"Add Peer","time":"2025-06-03T12:44:57Z"}
{"Key":"192.168.10.4","Topic":"Peer","level":"info","msg":"Add a peer configuration","time":"2025-06-03T12:44:57Z"}
{"Key":"192.168.10.5","Topic":"config","level":"info","msg":"Add Peer","time":"2025-06-03T12:44:57Z"}
{"Key":"192.168.10.5","Topic":"Peer","level":"info","msg":"Add a peer configuration","time":"2025-06-03T12:44:57Z"}
{"Duration":0,"Key":"192.168.10.2","Topic":"Peer","level":"debug","msg":"IdleHoldTimer expired","time":"2025-06-03T12:44:57Z"}
{"Key":"192.168.10.2","Topic":"Peer","level":"debug","msg":"state changed","new":"BGP_FSM_ACTIVE","old":"BGP_FSM_IDLE","reason":{"Type":7,"BGPNotification":null,"Data":null},"time":"2025-06-03T12:44:57Z"}
{"Duration":0,"Key":"192.168.10.3","Topic":"Peer","level":"debug","msg":"IdleHoldTimer expired","time":"2025-06-03T12:44:57Z"}
{"Key":"192.168.10.3","Topic":"Peer","level":"debug","msg":"state changed","new":"BGP_FSM_ACTIVE","old":"BGP_FSM_IDLE","reason":{"Type":7,"BGPNotification":null,"Data":null},"time":"2025-06-03T12:44:57Z"}
{"Duration":0,"Key":"192.168.10.5","Topic":"Peer","level":"debug","msg":"IdleHoldTimer expired","time":"2025-06-03T12:44:57Z"}
{"Key":"192.168.10.5","Topic":"Peer","level":"debug","msg":"state changed","new":"BGP_FSM_ACTIVE","old":"BGP_FSM_IDLE","reason":{"Type":7,"BGPNotification":null,"Data":null},"time":"2025-06-03T12:44:57Z"}
{"Duration":0,"Key":"192.168.10.4","Topic":"Peer","level":"debug","msg":"IdleHoldTimer expired","time":"2025-06-03T12:44:57Z"}
{"Key":"192.168.10.4","Topic":"Peer","level":"debug","msg":"state changed","new":"BGP_FSM_ACTIVE","old":"BGP_FSM_IDLE","reason":{"Type":7,"BGPNotification":null,"Data":null},"time":"2025-06-03T12:44:57Z"}
{"Key":"192.168.10.5","Topic":"Peer","level":"debug","msg":"try to connect","time":"2025-06-03T12:44:58Z"}
{"Key":"192.168.10.4","Topic":"Peer","level":"debug","msg":"try to connect","time":"2025-06-03T12:44:58Z"}
{"Key":"192.168.10.2","Topic":"Peer","level":"debug","msg":"try to connect","time":"2025-06-03T12:44:58Z"}
{"Key":"192.168.10.3","Topic":"Peer","level":"debug","msg":"try to connect","time":"2025-06-03T12:44:58Z"}
^C{"level":"info","msg":"stopping gobgpd server","time":"2025-06-03T12:45:01Z"}
{"Key":"192.168.10.5","Topic":"Peer","level":"info","msg":"Delete a peer configuration","time":"2025-06-03T12:45:01Z"}
{"Key":"192.168.10.2","Topic":"Peer","level":"info","msg":"Delete a peer configuration","time":"2025-06-03T12:45:01Z"}
{"Key":"192.168.10.3","Topic":"Peer","level":"info","msg":"Delete a peer configuration","time":"2025-06-03T12:45:01Z"}
{"Key":"192.168.10.4","Topic":"Peer","level":"info","msg":"Delete a peer configuration","time":"2025-06-03T12:45:01Z"}
{"Key":"192.168.10.3","Topic":"Peer","level":"debug","msg":"stop connect loop","time":"2025-06-03T12:45:01Z"}
{"Key":"192.168.10.4","Topic":"Peer","level":"debug","msg":"stop connect loop","time":"2025-06-03T12:45:01Z"}
{"Key":"192.168.10.2","Topic":"Peer","level":"debug","msg":"stop connect loop","time":"2025-06-03T12:45:01Z"}
{"Key":"192.168.10.5","Topic":"Peer","level":"debug","msg":"stop connect loop","time":"2025-06-03T12:45:01Z"}
{"Key":"192.168.10.3","State":2,"Topic":"Peer","level":"debug","msg":"freed fsm.h","time":"2025-06-03T12:45:01Z"}
{"Key":"192.168.10.5","State":2,"Topic":"Peer","level":"debug","msg":"freed fsm.h","time":"2025-06-03T12:45:01Z"}
{"Key":"192.168.10.2","State":2,"Topic":"Peer","level":"debug","msg":"freed fsm.h","time":"2025-06-03T12:45:01Z"}
{"Key":"192.168.10.4","State":2,"Topic":"Peer","level":"debug","msg":"freed fsm.h","time":"2025-06-03T12:45:01Z"}

```


Original image (frr only) is available at `abckey/frr-talos-extension`
