#!/bin/bash
# Creator Maji-Shan
# Environment Variables for container

echo "Creating or clearing the .env file..."
> .env

echo "Enter your SSH key name (default: id_rsa): "
read ssh_key_name
ssh_key_name=${ssh_key_name:-id_rsa}

echo "Generating SSH key..."
ssh-keygen -t rsa -b 2048 -N "" -f ~/.ssh/$ssh_key_name

echo "Enter the endpoint IP address of your Manager Server: "
read endpoint
echo "Enter the username for the remote endpoint: "
read username

echo "SSH_USERNAME=$username" >> .env
echo "SSH_ENDPOINT=$endpoint" >> .env

echo "Copying public key to $username@$endpoint..."
timeout 30 ssh-copy-id -i ~/.ssh/${ssh_key_name}.pub $username@$endpoint
if [ $? -eq 124 ]; then
    echo "Public key failed to send to $username@$endpoint"
else
    echo "Public key successfully added to $username@$endpoint."
fi

echo "Do you want to add additional SSH endpoints? (Y/N): "
read add_more

counter=2
while [[ "$add_more" == "y" || "$add_more" == "Y" ]]; do
    echo "Enter the endpoint IP address of server $counter: "
    read additional_endpoint
    echo "Enter the username for server $counter: "
    read additional_username

    echo "SSH_USERNAME_$counter=$additional_username" >> .env
    echo "SSH_ENDPOINT_$counter=$additional_endpoint" >> .env

    echo "Copying public key to $additional_username@$additional_endpoint..."
    timeout 30 ssh-copy-id -i ~/.ssh/${ssh_key_name}.pub $additional_username@$additional_endpoint
    if [ $? -eq 124 ]; then
        echo "Public key failed to send to $additional_username@$additional_endpoint"
    else
        echo "Public key successfully added to $additional_username@$additional_endpoint."
    fi

    echo "Do you want to add another SSH endpoint? (Y/N): "
    read add_more

    counter=$((counter + 1))
done

for i in $(seq 1 $((counter-1))); do
    if [[ -n $(eval echo "\$SSH_USERNAME_$i") && -n $(eval echo "\$SSH_ENDPOINT_$i") ]]; then
        username=$(eval echo "\$SSH_USERNAME_$i")
        endpoint=$(eval echo "\$SSH_ENDPOINT_$i")
    
        echo "Copying public key to $username@$endpoint..."
        timeout 30 ssh-copy-id -i ~/.ssh/${ssh_key_name}.pub $username@$endpoint
        if [ $? -eq 124 ]; then
            echo "Public key failed to send to $username@$endpoint"
        else
            echo "Public key successfully added to $username@$endpoint."
        fi
    fi
done


echo "Are you using a proxy server for HTTP/HTTPS? (Y/N): "
read use_proxy
if [[ "$use_proxy" == "y" || "$use_proxy" == "Y" ]]; then
    echo "Enter your HTTP proxy server (ex, http://proxy.example.com:8080/): "
    read http_proxy

    echo "Enter your HTTPS proxy server (ex, https://proxy.example.com:8080/): "
    read https_proxy

    echo "HTTP_PROXY=$http_proxy" >> .env
    echo "HTTPS_PROXY=$https_proxy" >> .env
fi

echo "What version of Suricata do you need? (ex. 7.0.3): "
read version
echo "SURICATA_VERSION=$version" >> .env
echo "Are you using Suricata OPEN or PRO?: "
read suri_type

if [ "$suri_type" == "PRO" ]; then
    echo "Enter your Suricata Pro key: "
    read suri_key
    echo "SURICATA_PRO_KEY=$suri_key" >> .env
fi

echo "Environment variables saved successfully!"
