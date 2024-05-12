#!/bin/bash

create_network() {
    docker network create \
    --subnet=10.11.0.0/24 \
    --gateway=10.11.0.1 \
    metas-lab > /dev/null
}

create_instances() {
    docker run -itd --name server-a --hostname server-a --restart always --network cyberates-net ubuntu:20.04-custom > /dev/null
    docker run -itd --name server-b --hostname server-b --restart always --network cyberates-net ubuntu:20.04-custom > /dev/null
}

instances_info() {
    instances=("server-a", "server-b")
    for i in "${instances[@]}"; do
        hostname=$(docker inspect -f '{{.Config.Hostname}}' $i)
        ip=$(docker inspect -f '{{range .NetworkSettings.Networks}}{{.IPAddress}}{{end}}' $i)
    done

    echo " "
    echo "##### LAB INFO. #####"
    echo "Hostname: $hostname"
    echo "IP Address: $ip"
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
