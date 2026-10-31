# Create the dedicated engineering group
sudo groupadd devops-engeering

# Create the dedicated engineering user and add it to the group
sudo useradd -m -s /bin/bash -g devops-engeering devops-1

# verify uid and gid
id devops-1

# Check /etc/passwd and /etc/group for the new user and group
cat /etc/passwd | grep -i devops-1
cat /etc/group | grep -i devops-engeering
