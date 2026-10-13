#!/bin/bash
set -e

# 1. Install Java (Important for Jenkins)
sudo apt update
sudo apt install -y fontconfig openjdk-21-jre

# 2. Clean old broken entries
sudo rm -f /etc/apt/sources.list.d/jenkins.list
sudo rm -f /usr/share/keyrings/jenkins-keyring.asc

# 3. New 2026 signing key + repo
sudo wget -O /usr/share/keyrings/jenkins-keyring.asc \
  https://pkg.jenkins.io/debian-stable/jenkins.io-2026.key
echo "deb [signed-by=/usr/share/keyrings/jenkins-keyring.asc] https://pkg.jenkins.io/debian-stable binary/" | \
  sudo tee /etc/apt/sources.list.d/jenkins.list > /dev/null

# 4. Jenkins install
sudo apt update
sudo apt install -y jenkins

# 5. Permission to run Docker
sudo usermod -aG docker jenkins
sudo systemctl enable --now jenkins
sudo systemctl restart jenkins

# 6. Initial password
sudo cat /var/lib/jenkins/secrets/initialAdminPassword
