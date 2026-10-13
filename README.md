# Flask CI/CD Pipeline: Jenkins + Docker + AWS EC2

Automated pipeline: GitHub push triggers Jenkins, which builds a Docker image,
pushes it to Docker Hub, and deploys it to an AWS EC2 server.

## Tech Stack
Jenkins | Docker | GitHub Webhooks | AWS EC2 | Bash | Flask

## Pipeline Stages
Checkout → Test → Build Image → Push Image → Deploy → Health Check

(Architecture diagram and screenshots coming soon)



CI/CD Project Flow: Jenkins + Docker + AWS EC2 

Developer git push
      ↓
GitHub Webhook ──► Jenkins (EC2 #1)
                      ↓
        Checkout → Test → Docker Build → Push to Docker Hub
                      ↓
              SSH into App Server (EC2 #2)
                      ↓
        docker pull → stop old container → run new container
                      ↓
              Health check (curl) ✅

Server	Port	Source
Jenkins	22	My IP
Jenkins	8080	0.0.0.0/0 (GitHub webhook ke liye, strong password rakhna)
App	22	Jenkins server ka SG
App	80	0.0.0.0/0