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

#----------------------Privcilege Escalation----------------------#
# Add the user to the /etc/sudoers file to grant administrative privileges
echo "devops-1 ALL=(ALL:ALL) ALL" | sudo tee -a /etc/sudoers

# Verify that the user has sudo privileges
sudo -l -U devops-1

# Verify that the user can switch to root using sudo
sudo su - devops-1

# Verify that the user can execute commands with sudo
sudo whoami && sudo update && sudo apt-get install -y htop