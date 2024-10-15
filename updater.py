import os
import subprocess
from datetime import datetime

def load_env_variables(env_file_path):
    with open(env_file_path) as env_file:
        for line in env_file:
            line = line.strip()
            if not line or line.startswith('#'):
                continue
            key, value = line.split('=', 1)
            os.environ[key] = value.strip()

def handle_ssh_scp():
    usernames = []
    endpoints = []
    for key, value in os.environ.items():
        if key.startswith('SSH_USERNAME'):
            usernames.append(value)
        elif key.startswith('SSH_ENDPOINT'):
            endpoints.append(value)

    if len(usernames) != len(endpoints):
        print("Error: Mismatch between number of SSH usernames and endpoints")
        return

    for username, endpoint in zip(usernames, endpoints):
        try:
            print(f"Running SCP for {username}@{endpoint}")
            subprocess.run(
                ['bash', '-c', 
                 f"scp -r ./new.rules {username}@{endpoint}:/home/{username}/dropoff/emerging-all.rules"], 
                check=True,
                timeout=3600
            )
            print(f"SCP to {username}@{endpoint} succeeded.")
        except subprocess.TimeoutExpired:
            print(f"SCP to {username}@{endpoint} timed out after 1 hour.")
        except subprocess.CalledProcessError as e:
            print(f"SCP to {username}@{endpoint} failed: {e}")

env_file_path = os.path.join(os.getcwd(), ".env")
load_env_variables(env_file_path)

subprocess.run(
    ['bash', '-c', 
     f"export http_proxy={os.getenv('HTTP_PROXY')} https_proxy={os.getenv('HTTPS_PROXY')}; "
     f"curl -O https://rules.emergingthreatspro.com/{os.getenv('SURICATA_PRO_KEY')}/suricata-{os.getenv('SURICATA_VERSION')}/etpro-all.rules.tar.gz && "
     "mv ./new.rules ./old.rules || true && "
     "tar -xf ./etpro-all.rules.tar.gz -C . && "
     "mv ./etpro-all.rules ./new.rules && "
     'diff ./old.rules ./new.rules | grep -E "^\\+?[#]?alert" | wc -l | awk \'{print \"Added \" $1 \" New Rules\"}\' >> ./report'
    ], 
    env=os.environ,
    check=True
)

handle_ssh_scp()

