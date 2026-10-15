# Automated Flask CI/CD Pipeline: Jenkins, Docker & AWS EC2
[![CI/CD](https://img.shields.io/badge/CI%2FCD-Jenkins-red.svg)](https://www.jenkins.io/)
[![Docker](https://img.shields.io/badge/Container-Docker-blue.svg)](https://www.docker.com/)
[![AWS](https://img.shields.io/badge/Cloud-AWS%20EC2-orange.svg)](https://aws.amazon.com/ec2/)
[![Python](https://img.shields.io/badge/Framework-Flask-green.svg)](https://flask.palletsprojects.com/)

An end-to-end continuous integration and continuous deployment (CI/CD) pipeline for a containerized Python Flask application. Code changes pushed to GitHub automatically trigger a Jenkins build, package the application into a Docker image, push the artifact to Docker Hub, deploy it remotely to an AWS EC2 production instance, and execute automated health checks.
---
## Tech Stack
> Jenkins | Docker | GitHub Webhooks | AWS EC2 | Bash | Flask
---
## Architecture Overview
```text
               +-------------------+
               |  Developer Push   |
               +---------+---------+
                         |
                         v (Webhook Trigger)
               +---------+---------+
               |  GitHub Repository |
               +---------+---------+
                         |
                         v
     ================= AWS EC2: Jenkins Server =================
     |  1. Checkout Code                                       |
     |  2. Build Docker Image (Tagged with Build ID)           |
     |  3. Push Image to Docker Hub Registry                   |
     |  4. Trigger Remote Deployment via SSH Agent             |
     ===========================================================
                         |
                         v (SSH Authentication)
     ================= AWS EC2: Production App =================
     |  1. Pull Target Docker Image                            |
     |  2. Gracefully Stop & Remove Existing Container         |
     |  3. Launch New Container on Port 80                     |
     |  4. Run Container Health Verification (curl)            |
     ===========================================================
```

## Pipeline Stages
```text
[ Checkout SCM ] ➔ [ Syntax Check ] ➔ [ Build Docker Image ] ➔ [ Push to Docker Hub ] ➔ [ Deploy to EC2 ] ➔ [ Health Check ]
```
## Repository Structure
```text
flask-cicd-demo/
├── .gitignore
├── Dockerfile
├── Jenkinsfile
├── README.md
├── app.py
├── requirements.txt
├── scripts/
│   ├── setup_docker.sh
│   └── setup_jenkins.sh
└── screenshots/
    ├── AWS-EC2.png
    ├── app.png
    ├── docker-hub.png
    ├── pipeline.png
    └── webhooks.png
```

## Infrastructure & Network Configuration
### EC2 Hardware Specifications
- Jenkins Controller Server: t3.small (2 vCPU, 2GB RAM, 20 GiB gp3 Storage)
- Production App Server: t3.micro (1 vCPU, 1GB RAM, 8 GiB gp3 Storage)
- Base OS: Ubuntu 24.04 LTS (Noble Numbat)

### Security Group Ingress Rules
| Host | Port | Protocol | Source | Purpose |
| :--- | :--- | :--- | :--- | :--- |
| **Jenkins Server** | `22` | TCP | Admin IP (`/32`) | Secure Bastion / SSH Access |
| **Jenkins Server** | `8080` | TCP | `0.0.0.0/0` | Jenkins Web GUI & Webhook |
| **App Server** | `22` | TCP | Jenkins Server SG | Deployment via SSH |
| **App Server** | `80` | TCP | `0.0.0.0/0` | Public App Traffic |

> **Note:** Jenkins port 8080 is open to `0.0.0.0/0` so that GitHub webhooks can reach it.
> In production, restrict this to GitHub's published webhook IP ranges and put Jenkins
> behind a reverse proxy with HTTPS.

## Step-by-Step Implementation Guide 
## Phase 1: Local Setup & GitHub Repository

### Step 1.1: Configure Git user credentials locally:
```bash
git config --global user.name "your-github-username"
git config --global user.email "your-email@example.com"
git config --global init.defaultBranch main
```
### Step 1.2: Initialize the application directory:
```bash
mkdir flask-cicd-demo && cd flask-cicd-demo
git init
```
### Step 1.3: Stage, commit, and link to GitHub:
```bash
git add .
git commit -m "feat: initial commit with app code, dockerfile, and pipeline"
git branch -M main
git remote add origin https://github.com/mr-rizwan-1/flask-cicd-demo.git
git push -u origin main
```
## Phase 2: Jenkins Server Provisioning
### Step 2.1: Configure 2GB Swap Memory (Prevents Out-Of-Memory crashes on t3.small):
```bash
sudo fallocate -l 2G /swapfile
sudo chmod 600 /swapfile
sudo mkswap /swapfile
sudo swapon /swapfile
echo '/swapfile none swap sw 0 0' | sudo tee -a /etc/fstab
free -h
```

### Step 2.2: Install Jenkins, Docker, and OpenJDK 21:
```bash
sudo apt update && sudo apt install -y git
git clone https://github.com/mr-rizwan-1/flask-cicd-demo.git
cd flask-cicd-demo/scripts
ls
# Run the setup scripts
chmod +x <docker-script>.sh <jenkins-script>.sh
./<docker-script>.sh
./<jenkins-script>.sh
```

### Step 2.3: Retrieve the Initial Admin Unlock Key:
```bash
sudo cat /var/lib/jenkins/secrets/initialAdminPassword
```

### Step 2.4: Jenkins Initial Configuration:
- Open `http://<JENKINS_PUBLIC_IP>:8080` in your web browser.
- Paste the initial password.
- Select Install suggested plugins.
- Create an administrative user profile and configure your Jenkins base URL.
- Navigate to **Manage Jenkins ➔ Plugins ➔ Available plugins**, install the **SSH Agent** Plugin, and restart Jenkins.

## Phase 3: Production App Server Setup
### Step 3.1: Connect to the App Server via SSH:
```bash
ssh -i your-key.pem ubuntu@<APP_SERVER_PUBLIC_IP>
```

### Step 3.2: Install the Docker Engine:
```bash
sudo apt update && sudo apt install -y git
git clone https://github.com/mr-rizwan-1/flask-cicd-demo.git
cd flask-cicd-demo/scripts

# Run the setup scripts
chmod +x <docker-script>.sh
./<docker-script>.sh
```
### Step 3.3: Verify Docker execution without sudo:
```bash
ssh -i your-key.pem ubuntu@<APP_SERVER_PUBLIC_IP>
docker run --rm hello-world
```

## Phase 4: SSH Trust & Credentials Management
#### Step 4.1: Generate Deployment Key-Pair (On Jenkins Server)
```bash
ssh-keygen -t ed25519 -f ~/.ssh/jenkins_deploy_key -N ""
cat ~/.ssh/jenkins_deploy_key.pub
```

### Step 4.2: Authorize Public Key (On App Server)
**Append the generated public key to the target server's authorized list:**
```bash
echo "<COPIED_ED25519_PUBLIC_KEY>" >> ~/.ssh/authorized_keys
chmod 600 ~/.ssh/authorized_keys
```
### Step 4.3: Verify Non-Interactive SSH Communication (From Jenkins Server)

```bash
ssh -i ~/.ssh/jenkins_deploy_key -o StrictHostKeyChecking=no ubuntu@<APP_SERVER_PRIVATE_OR_PUBLIC_IP> "docker ps"
```

### Step 4.4: Configure Jenkins Global Credentials
Navigate to **Manage Jenkins ➔ Credentials ➔ System ➔ Global credentials (unrestricted) ➔ Add Credentials**:

| Kind | ID | Details |
| :--- | :--- | :--- |
| Username with password | `dockerhub` | **Username**: Docker Hub ID<br>**Password**: Docker Hub Personal Access Token (Read & Write permissions) |
| SSH Username with private key | `app-server-ssh` | **Username**: `ubuntu`<br>**Private Key**: Check *Enter directly*, paste entire output of `cat ~/.ssh/jenkins_deploy_key` |


## Phase 5: Pipeline & Webhook Integration

### Step 5.1: Create the Jenkins Pipeline Job:
- Go to Jenkins Dashboard ➔ **New Item**.
- Item Name: `flask-cicd-pipeline` **➔ Select Pipeline ➔ Click OK**.
- Under Build Triggers, enable: `GitHub hook trigger for GITScm polling`.
- Under **Pipeline definition**:
  - **Definition**: `Pipeline script from SCM`
  - **SCM**: `Git`
  - **Repository URL**: `https://github.com/<your-username>/flask-cicd-demo.git`
  - **Branch**: `*/main`
  - **Script Path**: `Jenkinsfile`
- Click **Save**.

### Step 5.2: Configure GitHub Push Webhook:
- Go to your repository on **GitHub ➔ Settings ➔ Webhooks ➔ Add webhook**.
- **Payload URL**: `http://<JENKINS_PUBLIC_IP>:8080/github-webhook/`
- **Content type**: `application/json`
- **Trigger events**: `Just the push event`
- Click **Add webhook**.

## Phase 6: Verification & Deployment Walkthrough

### Step 6.1: Manual Pipeline Verification
- Open `flask-cicd-pipeline` in Jenkins and click Build Now.
- Verify all stages complete with a green status badge.
- Access `http://<APP_SERVER_PUBLIC_IP>` in your browser to confirm application responsiveness (`Version 1.0`).

### Step 6.2: Automated Trigger Verification

- Update the application response text in app.py:
```python
return "Continuous Deployment Successful: Version 2.0!"
```

- Commit and push the changes:
```bash
git add app.py
git commit -m "chore: release version 2.0"
git push origin main
```
> Confirm that Jenkins immediately detects the webhook, completes the automated deployment, and refreshes the live endpoint.

## Rollback & Recovery Strategy

> Images are tagged with unique Jenkins build IDs (`${BUILD_NUMBER}`) alongside the `latest` tag during every pipeline run. To instantly roll back to an earlier stable state, execute the run command targeting the verified build identifier:

```bash
docker pull <dockerhub-username>/flask-cicd-demo:<target-build-number>
docker stop flask-app || true && docker rm flask-app || true
docker run -d --name flask-app --restart always -p 80:5000 <dockerhub-username>/flask-cicd-demo:<target-build-number>
```

## Troubleshooting Guide
| Issue | Root Cause | Remediation |
| :--- | :--- | :--- |
| Jenkins apt install failed ("repository is not signed") | Jenkins rotated its repo signing key to a 2026 key | Updated the setup script to use `jenkins.io-2026.key` |
| Build stuck on "Waiting for next available executor" | Jenkins took the node offline: `/tmp` free space (947 MiB) was below the 1 GiB threshold | Lowered the temp-space threshold and brought the node back online |
| `docker push` failed: "access token has insufficient scopes" | Docker Hub token was Read-only | Generated a Read & Write token and updated the Jenkins credential |

## Screenshots
### Pipeline
---
![Pipeline](screenshots/pipeline.png)

### Running App
---
![Running App](screenshots/app.png)

### AWS EC2 Jenkins and App servers
---
![AWS EC2](screenshots/AWS-EC2.png)

### GitHub Webhook
---
![GitHub Webhook](screenshots/webhooks.png)

### Docker Hub 
---
![Docker Hub](screenshots/docker-hub.png)