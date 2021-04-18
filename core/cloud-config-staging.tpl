#cloud-config
ssh_authorized_keys:
  - ${ssh_key}

groups:
  - caddy

users:
  - name: caddy
    gecos: Caddy web server
    primary_group: caddy
    groups: caddy
    shell: /usr/sbin/nologin
    homedir: /var/lib/caddy

write_files:
- content: |
    {
      email ${caddy_letsencrypt_email}
    }

    ${faasd_domain_name} {
      tls {
        ca ${caddy_ca}
        dns digitalocean ${do_token}
      }
      reverse_proxy 127.0.0.1:8080
    }

  path: /etc/caddy/Caddyfile

- content: |
    [Unit]
    Description=Caddy
    Documentation=https://caddyserver.com/docs/
    After=network.target network-online.target
    Requires=network-online.target

    [Service]
    Type=notify
    User=caddy
    Group=caddy
    ExecStart=/usr/bin/caddy run --environ --config /etc/caddy/Caddyfile
    ExecReload=/usr/bin/caddy reload --config /etc/caddy/Caddyfile
    TimeoutStopSec=5s
    TimeoutStartSec=10m
    LimitNOFILE=1048576
    LimitNPROC=512
    PrivateTmp=true
    ProtectSystem=full
    AmbientCapabilities=CAP_NET_BIND_SERVICE

    [Install]
    WantedBy=multi-user.target

  path: /etc/systemd/system/caddy.service

package_update: true

packages:
 - runc

runcmd:
- curl -sLSf https://github.com/containerd/containerd/releases/download/v1.3.5/containerd-1.3.5-linux-amd64.tar.gz > /tmp/containerd.tar.gz && tar -xvf /tmp/containerd.tar.gz -C /usr/local/bin/ --strip-components=1
- curl -SLfs https://raw.githubusercontent.com/containerd/containerd/v1.3.5/containerd.service | tee /etc/systemd/system/containerd.service
- systemctl daemon-reload && systemctl start containerd
- /sbin/sysctl -w net.ipv4.conf.all.forwarding=1
- mkdir -p /opt/cni/bin
- curl -sSL https://github.com/containernetworking/plugins/releases/download/v0.8.5/cni-plugins-linux-amd64-v0.8.5.tgz | tar -xz -C /opt/cni/bin
- mkdir -p /go/src/github.com/openfaas/
- mkdir -p /var/lib/faasd/secrets/
- mkdir -p /var/lib/faasd/.docker/
- echo ${gw_password} > /var/lib/faasd/secrets/basic-auth-password
- echo '{"auths":{"registry.digitalocean.com":{"auth":"${do_registry_auth}"}}}' > /var/lib/faasd/.docker/config.json
- echo admin > /var/lib/faasd/secrets/basic-auth-user
- cd /go/src/github.com/openfaas/ && git clone https://github.com/openfaas/faasd && cd faasd && git fetch --all --tags --prune && git checkout tags/${faasd_version} -b tag/${faasd_version}
- curl -fSLs "https://github.com/openfaas/faasd/releases/download/${faasd_version}/faasd" --output "/usr/local/bin/faasd" && chmod a+x "/usr/local/bin/faasd"
- cd /go/src/github.com/openfaas/faasd/ && /usr/local/bin/faasd install
- systemctl status -l containerd --no-pager
- journalctl -u faasd-provider --no-pager
- systemctl status -l faasd-provider --no-pager
- systemctl status -l faasd --no-pager
- curl -sSLf https://cli.openfaas.com | sh
- sleep 5 && journalctl -u faasd --no-pager
- wget -nv https://golang.org/dl/go1.16.3.linux-amd64.tar.gz -O /tmp/go1.16.3.tar.gz && rm -rf /usr/local/go && tar -zxf /tmp/go1.16.3.tar.gz -C /usr/local
- wget -nv https://github.com/caddyserver/xcaddy/releases/download/v0.1.9/xcaddy_0.1.9_linux_amd64.tar.gz -O /tmp/xcaddy.tar.gz && tar -zxf /tmp/xcaddy.tar.gz -C /usr/bin xcaddy
- printenv && export PATH=$PATH:/usr/local/go/bin && export GOPATH=$HOME/go && export GOCACHE=$HOME/.cache/go-build
- xcaddy build "v${caddy_version}" --with github.com/caddy-dns/digitalocean --output /usr/bin/caddy
- systemctl daemon-reload
- systemctl enable caddy
- sleep 5s
- systemctl start caddy
