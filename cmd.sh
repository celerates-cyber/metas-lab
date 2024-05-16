#!/bin/bash

create_network() {
    docker network create \
    --subnet=10.11.0.0/24 \
    --gateway=10.11.0.1 \
    metas-net > /dev/null
}

create_instances() {

    cat << EOF >> instance1
        # Use Ubuntu 20.04 as base image
        FROM ubuntu:20.04

        # Set hostname
        RUN echo 'servera.lab.example.com' > /etc/hostname

        # Install SSH server, rsyslog, vim, iproute2, net-tools, sudo, and ping
        RUN apt-get update && \
            DEBIAN_FRONTEND=noninteractive apt-get install -y \
            openssh-server \
            rsyslog \
            vim \
            iproute2 \
            net-tools \
            sudo \
            iputils-ping && \
            apt-get clean && \
            rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

        # Configure SSH
        RUN mkdir /var/run/sshd
        RUN echo 'root:password' | chpasswd

        # Configure rsyslog
        RUN sed -i '/imklog/s/^/#/' /etc/rsyslog.conf # Uncomment to enable local logging
        RUN systemctl enable rsyslog.service

        # Expose SSH port
        EXPOSE 22

        # Start SSH server and rsyslogd
        CMD service rsyslog start && /usr/sbin/sshd -D

EOF
    image_name="metas-image"
    docker build -f instance1 -t "$image_name" .
    docker run -itd --name server-a --hostname server-a --restart always --network metas-net $image_name > /dev/null
    docker run -itd --name server-b --hostname server-b --restart always --network metas-net $image_name > /dev/null
}

instances_info() {
    instances=("server-a" "server-b")
    echo " "
    echo "##### LAB INFO. #####"
    for i in "${instances[@]}"; do
        hostname=$(docker inspect -f '{{.Config.Hostname}}' "$i")
        ip=$(docker inspect -f '{{range .NetworkSettings.Networks}}{{.IPAddress}}{{end}}' "$i")
        echo "Hostname: $hostname"
        echo "IP Address: $ip"
    done
}

main() {
    echo "Creating a network"
    create_network

    if [ $? -eq 0 ]; then
        echo "Network created successfully"
        echo "Creating instances"
        create_instances

        if [ $? -eq 0 ]; then
            echo "Instances created successfully"
            instances_info
        else
            echo "Failed to create instances"
        fi
    else
        echo "Failed to create network"
    fi
}

main
