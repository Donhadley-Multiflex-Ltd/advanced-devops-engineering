#----------------------User Management----------------------#
# Create the dedicated engineering group
sudo groupadd devops-engeering

# Create the dedicated engineering user and add it to the group
sudo useradd -m -s /bin/bash -g devops-engeering devops-1

# verify uid and gid
id devops-1

# Check /etc/passwd and /etc/group for the new user and group
cat /etc/passwd | grep -i devops-1
cat /etc/group | grep -i devops-engeering

#----------------------Privilege Escalation----------------------#
# Add the user to the /etc/sudoers file to grant administrative privileges
echo "devops-1 ALL=(ALL:ALL) ALL" | sudo tee -a /etc/sudoers

# Verify that the user has sudo privileges
sudo -l -U devops-1

# Verify that the user can switch to root using sudo
sudo su - devops-1

# Verify that the user can execute commands with sudo
sudo whoami && sudo update && sudo apt-get install -y htop

#----------------------SSH Key Management----------------------#
# Generate SSH neww key pair for the user or copy the existing public key to the user's authorized_keys file
# New key pair generation
ssh-keygen -t ed25519 -f ~/.ssh/id_ed25519_ubuntu
# Copy existing public key to the user's authorized_keys file
ssh-copy-id -i ~/.ssh/id_ed25519_ubuntu.pub devops-1@<server_ip>
ssh-copy-id -i ~/.ssh/id_ed25519_ubuntu.pub devops-2@<server_ip>

# Verify that the user can log in to the server using SSH with the private key without a password prompt
ssh -i ~/.ssh/id_ed25519_ubuntu devops-1@<server_ip>
ssh -i ~/.ssh/id_ed25519_ubuntu devops-2@<server_ip>

