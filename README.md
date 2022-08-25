[preview]: https://raw.githubusercontent.com/MarkusMcNugen/docker-templates/master/openconnect/ocserv-icon.png "Custom ocserv icon"

![alt text][preview]

# OpenConnect VPN Server
OpenConnect VPN server is an SSL VPN server that is secure, small, fast and configurable. It implements the OpenConnect SSL VPN protocol and has also (currently experimental) compatibility with clients using the AnyConnect SSL VPN protocol. The OpenConnect protocol provides a dual TCP/UDP VPN channel and uses the standard IETF security protocols to secure it. The OpenConnect client is multi-platform and available [here](http://www.infradead.org/openconnect/). Alternatively, you can try connecting using the official Cisco AnyConnect client (Confirmed working on Android).

[Homepage](https://ocserv.gitlab.io/www/platforms.html)

[Documentation](https://ocserv.gitlab.io/www/manual.html)

[Source](https://gitlab.com/ocserv/ocserv)

# Restrictions
Fork is in testing.
Container running in privelegged mode, use it for own risk.
For example,make shure you are use latest kernel and turned off shell or web access.
For this reason there is no certbot in build.

# Features
* The dockerfile always download and compile the *latest* release of OpenConnect VPN server
* Entrypoint can use your own ocserv.conf, cli or compose env var will owerwrite it
* Modification of the listening port for more networking versatility
* Customizing the DNS servers used for queries over the VPN
* Supports tunneling all traffic over the VPN or tunneling only specific routes via split-include
* Config directory can be mounted to a host directory for persistence 
* Create certs automatically using default or provided values, or drop your own certs in /config/certs

# Run container from Docker registry
The container is available from the Docker registry and this is the simplest way to get it.

## Basic Configuration
### Without customizing cert variables
```bash
$ docker run --privileged  -d \
              -p 4443:4443 \
              -p 4443:4443/udp \
              mcgr0g/openconnect-2nas
```
or for local test run `make simple`

### With customizing cert variables
```bash
$ docker run --privileged  -d \
              -p 4443:4443 \
              -p 4443:4443/udp \
              -e "CA_CN=VPN CA" \
              -e "CA_ORG=OCSERV" \
              -e "CA_DAYS=9999" \
              -e "SRV_CN=vpn.example.com" \
              -e "SRV_ORG=MyCompany" \
              -e "SRV_DAYS=9999" \
              mcgr0g/openconnect-2nas
```
or for local test configure Makefile and run `make customcert`

## Intermediate Configuration (Providing own certs in /config/certs and running on port 443):
Cert files are stored in /config/certs. It will automatically generate certs if the following two files are not present in the cert directory:
```
server-key.pem
server-cert.pem
```
```bash
$ docker run --privileged  -d \
              -v /your/config/path/:/config \
              -e "LISTEN_PORT=443" \
              -e "DNS_SERVERS=192.168.1.190" \
              -e "TUNNEL_MODE=split-include" \
              -e "TUNNEL_ROUTES=192.168.1.0/24" \
              -e "SPLIT_DNS_DOMAINS=example.com" \
              -p 443:443 \
              -p 443:443/udp \
              --name openconnect
              mcgr0g/openconnect-2nas
```

### With pregenerated cetrs
```docker
version: "3"

services:
  ocserv:
    container_name: openconnect
    image: mcgr0g/openconnect-2nas:latest
    ports:
      - "443:443/tcp"
      - "443:443/udp"
    environment:
      LISTEN_PORT: 443
      TUNNEL_MODE: 'split-include'
      TUNNEL_ROUTES: '192.168.1.0/24, 192.168.2.0/24'
      DNS_SERVERS: 192.168.2.1
      SPLIT_DNS_DOMAINS: 'router.lan'
      CA_CN: 'VPN CA'
      CA_ORG: 'OCSERV'
      CA_DAYS: 9999 
      SRV_CN: 'vpn.example.com'
      SRV_ORG: 'Example Company'
      SRV_DAYS: 9999
    volumes:
      - './config/:/config/'
    cap_add:
      - NET_ADMIN
    privileged: true
    restart: unless-stopped
```

# Variables
| Variable | Required | Function | Example |
|----------|----------|----------|----------|
|`LISTEN_PORT`| No | Listening port for VPN connections|`LISTEN_PORT=4443`|
|`DNS_SERVERS`| No | Comma delimited name servers |`DNS_SERVERS=8.8.8.8,8.8.4.4`|
|`TUNNEL_MODE`| No | Tunnel mode (all / split-include) |`TUNNEL_MODE=split-include`|
|`TUNNEL_ROUTES`| No | Comma delimited tunnel routes in CIDR notation |`TUNNEL_ROUTES=192.168.1.0/24`|
|`DNS_SERVERS`| NO | Comma delimited DNS servers ip | `DNS_SERVERS="8.8.8.8,37.235.1.174,8.8.4.4,37.235.1.177"`|
|`SPLIT_DNS_DOMAINS`| No | Comma delimited dns domains |`SPLIT_DNS_DOMAINS=example.com`|


# How to use this OpenConnect Server Docker
Install and run the docker container with your chosen options. Port forward incoming traffic on your router, some outside port to the containers IP and the listening port on the inside. After port forwarding is established you will need to create VPN accounts for users to login with usernames and passwords.

## Add User/Change Password
Add users by executing the following command on the host running the docker container
```
docker exec -it openconnect ocpasswd -c /config/ocpasswd mcgr0g
Enter password:
Re-enter password:
```

## Delete User
Delete users by executing the following command on the host running the docker container
```
docker exec -it openconnect ocpasswd -c /config/ocpasswd -d mcgr0g
```

## Login and Logout Log Messages
After a user successfully logins to the VPN a message will be logged in the docker log.<br>
*Example of login message:*
```
[info] User markusmcnugen Connected - Server: 192.168.1.165 VPN IP: 192.168.255.194 Remote IP: 107.92.120.188 
```

*Example of logoff message:*
```
[info] User markusmcnugen Disconnected - Bytes In: 175856 Bytes Out: 4746819 Duration:63
```

# Building the container yourself
To build this container, clone the repository and cd into it.

### Build it:
```
$ cd /repo/location/openconnect-2nas
$ docker build -t opopenconnect-2nasnconnect .
```

or use `make build`
