#!/bin/bash
set -e

# 1. Java (Jenkins ke liye zaroori)
sudo apt update
sudo apt install -y fontconfig openjdk-21-jre

# 2. Purani broken entries saaf karo
sudo rm -f /etc/apt/sources.list.d/jenkins.list
sudo rm -f /usr/share/keyrings/jenkins-keyring.asc

# 3. Naya 2026 signing key + repo
sudo wget -O /usr/share/keyrings/jenkins-keyring.asc \
  https://pkg.jenkins.io/debian-stable/jenkins.io-2026.key
echo "deb [signed-by=/usr/share/keyrings/jenkins-keyring.asc] https://pkg.jenkins.io/debian-stable binary/" | \
  sudo tee /etc/apt/sources.list.d/jenkins.list > /dev/null

# 4. Jenkins install
sudo apt update
sudo apt install -y jenkins

# 5. Docker chalane ki permission
sudo usermod -aG docker jenkins
sudo systemctl enable --now jenkins
sudo systemctl restart jenkins

# 6. Initial password
sudo cat /var/lib/jenkins/secrets/initialAdminPassword