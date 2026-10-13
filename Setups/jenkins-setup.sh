sudo apt install -y fontconfig openjdk-17-jre
sudo wget -O /usr/share/keyrings/jenkins-keyring.asc \
  https://pkg.jenkins.io/debian-stable/jenkins.io-2023.key
echo "deb [signed-by=/usr/share/keyrings/jenkins-keyring.asc] \
  https://pkg.jenkins.io/debian-stable binary/" | \
  sudo tee /etc/apt/sources.list.d/jenkins.list > /dev/null
sudo apt update && sudo apt install -y jenkins

# Jenkins ko docker chalane ki permission (zaroori!)
sudo usermod -aG docker jenkins
sudo systemctl restart jenkins

# Initial password
sudo cat /var/lib/jenkins/secrets/initialAdminPassword