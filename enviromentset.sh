#!/bin/bash
# Creator Maji-Shan
# Environment Variables for container

# Env file creation/wipe
echo "Creating or clearing the .env file..."
> .env

# SSH key creation
echo "Enter your SSH key name (default: id_rsa): "
read ssh_key_name
ssh_key_name=${ssh_key_name:-id_rsa}

# Generate the SSH key
echo "Generating SSH key..."
ssh-keygen -t rsa -b 2048 -N "" -f ~/.ssh/$ssh_key_name

# Initial SSH endpoint input
echo "Enter the endpoint IP address of your Manager Server: "
read endpoint
echo "Enter the username for the remote endpoint: "
read username

# Store the first SSH information
echo "SSH_USERNAME=$username" >> .env
echo "SSH_ENDPOINT=$endpoint" >> .env

# Copy the public key to the first endpoint
echo "Copying public key to $username@$endpoint..."
timeout 30 ssh-copy-id -i ~/.ssh/${ssh_key_name}.pub $username@$endpoint
if [ $? -eq 124 ]; then
    echo "Public key failed to send to $username@$endpoint"
else
    echo "Public key successfully added to $username@$endpoint."
fi

# Ask if user wants to add more endpoints
echo "Do you want to add additional SSH endpoints? (Y/N): "
read add_more

counter=2
while [[ "$add_more" == "y" || "$add_more" == "Y" ]]; do
    # Collect additional SSH details
    echo "Enter the endpoint IP address of server $counter: "
    read additional_endpoint
    echo "Enter the username for server $counter: "
    read additional_username

    # Store the additional SSH information
    echo "SSH_USERNAME_$counter=$additional_username" >> .env
    echo "SSH_ENDPOINT_$counter=$additional_endpoint" >> .env

    # Copy the public key to the additional endpoint
    echo "Copying public key to $additional_username@$additional_endpoint..."
    timeout 30 ssh-copy-id -i ~/.ssh/${ssh_key_name}.pub $additional_username@$additional_endpoint
    if [ $? -eq 124 ]; then
        echo "Public key failed to send to $additional_username@$additional_endpoint"
    else
        echo "Public key successfully added to $additional_username@$additional_endpoint."
    fi

    # Ask if they want to add more endpoints
    echo "Do you want to add another SSH endpoint? (Y/N): "
    read add_more

    # Increment counter for the next endpoint
    counter=$((counter + 1))
done

# Ensure that all saved SSH keys are copied to every SSH endpoint that exists
for i in $(seq 1 $((counter-1))); do
    if [[ -n $(eval echo "\$SSH_USERNAME_$i") && -n $(eval echo "\$SSH_ENDPOINT_$i") ]]; then
        # Retrieve usernames and endpoints from .env file
        username=$(eval echo "\$SSH_USERNAME_$i")
        endpoint=$(eval echo "\$SSH_ENDPOINT_$i")
    
        # Copy the public key to each valid endpoint
        echo "Copying public key to $username@$endpoint..."
        timeout 30 ssh-copy-id -i ~/.ssh/${ssh_key_name}.pub $username@$endpoint
        if [ $? -eq 124 ]; then
            echo "Public key failed to send to $username@$endpoint"
        else
            echo "Public key successfully added to $username@$endpoint."
        fi
    fi
done

# Continue with the proxy and other variable collection as before

# Ask for proxy usage
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

# Suricata version and type
echo "What version of Suricata do you need? (ex. 7.0.3): "
read version
echo "SURICATA_VERSION=$version" >> .env
echo "Are you using Suricata OPEN or PRO?: "
read suri_type

# If Suricata Pro, ask for the key
if [ "$suri_type" == "PRO" ]; then
    echo "Enter your Suricata Pro key: "
    read suri_key
    echo "SURICATA_PRO_KEY=$suri_key" >> .env
fi

echo "Environment variables saved successfully!"
