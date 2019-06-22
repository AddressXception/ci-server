#cloud-config
# vim: syntax=yaml
# cloud-init file for a custom VM that supports docker
# see: https://cloud-init.io/

# update and upgrade packages, install new packages if needed
package_update: true
package_upgrade: true
package_reboot_if_required: true

packages:
  - audispd-plugins
  - auditd
  - curl
  # https://github.com/docker/compose/issues/6023#issuecomment-425197890
  #- docker-compose
  - docker.io
  - git
  - fail2ban
  - htop
  - language-pack-en-base
  - tmux
  - vim
  - wget

# Set the locale of the system
# Value of 'timezone' must exist in /usr/share/zoneinfo
locale: "en_US.UTF-8"
timezone: "America/New_York"

# configure linux system files
write_files:
  # Configure SSH
  - path: /etc/ssh/sshd_config
    permissions: 0644
    # strengthen SSH cyphers
    content: |
      Port ${ssh_port}
      Protocol 2
      HostKey /etc/ssh/ssh_host_ed25519_key
      KexAlgorithms curve25519-sha256@libssh.org
      Ciphers chacha20-poly1305@openssh.com,aes256-gcm@openssh.com,aes128-gcm@openssh.com,aes256-ctr,aes192-ctr,aes128-ctr
      MACs hmac-sha2-512-etm@openssh.com,hmac-sha2-256-etm@openssh.com,umac-128-etm@openssh.com
      UsePrivilegeSeparation yes
      KeyRegenerationInterval 3600
      ServerKeyBits 1024
      SyslogFacility AUTH
      LogLevel INFO
      LoginGraceTime 120
      PermitRootLogin prohibit-password
      StrictModes yes
      RSAAuthentication yes
      PubkeyAuthentication yes
      IgnoreRhosts yes
      RhostsRSAAuthentication no
      HostbasedAuthentication no
      PermitEmptyPasswords no
      ChallengeResponseAuthentication no
      PasswordAuthentication no
      X11Forwarding yes
      X11DisplayOffset 10
      PrintMotd no
      PrintLastLog yes
      TCPKeepAlive yes
      AcceptEnv LANG LC_*
      Subsystem sftp /usr/
      UsePAM yes
  # configure Fail2Ban
  - path: /etc/fail2ban/jail.d/override-ssh-port.conf
    permissions: 0644
    content: |
      [sshd]
      enabled = true
      port    = ${ssh_port}
      logpath = %(sshd_log)s
      backend = %(sshd_backend)s
  # TODO: configure AppArmor
  # TODO: configure SELinux
  - path: /etc/profile.d/docker-registry.sh
    content: |
      export DOCKER_REGISTRY=${registry_server}
      export DOCKER_REGISTRY_USERNAME=${registry_username}
      export DOCKER_REGISTRY_PASSWORD=${registry_password}
  # configure docker
  - path: /etc/systemd/system/docker.service.d/docker.conf
    content: |
      [Service]
        ExecStart=
        ExecStart=/usr/bin/dockerd
  # run image
  - path: /etc/systemd/system/build-agent.service
    content: |
      [Unit]
        After=docker.service
        Requires=docker.service

      [Service]
        TimeoutStartSec=0
        Restart=always
        RestartSec=10s
        ExecStartPre=-/usr/bin/docker stop ${agent_name}
        ExecStartPre=-/usr/bin/docker rm ${agent_name}
        ExecStartPre=/usr/bin/docker login \
                    -u '${registry_username}' \
                    -p '${registry_password}' \
                    '${registry_server}'
        ExecStartPre=/usr/bin/docker pull ${registry_agent_image}
        ExecStart=/usr/bin/docker run \
                    --rm \
                    ${docker_env_vars} \
                    -v /var/run/docker.sock:/var/run/docker.sock \
                    --name ${agent_name} \
                    ${registry_agent_image}
        ExecStop=/usr/bin/docker stop ${agent_name}
        
      [Install]
        WantedBy=default.target
        
runcmd:
  - echo "adding ${admin_username} to docker group"
  - usermod -G docker ${admin_username}
  - systemctl daemon-reload
  # https://docs.docker.com/install/linux/linux-postinstall//#configure-docker-to-start-on-boot
  - systemctl enable docker
  - systemctl start docker
  - echo "enabling build agent"
  - systemctl enable build-agent.service
  - systemctl start build-agent.service
  - systemctl status build-agent.service
  # https://github.com/docker/compose/issues/6023#issuecomment-425197890
  - echo "installing docker compose"
  - apt install -y --no-install-recommends docker-compose
