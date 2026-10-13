pipeline {
    agent any

    environment {
        IMAGE   = "rizwaan1980/flask-cicd-demo"
        TAG     = "${BUILD_NUMBER}"
        APP_IP  = "YOUR_APP_SERVER_IP"
    }

    stages {
        stage('Checkout') {
            steps { checkout scm }
        }

        stage('Test') {
            steps { sh 'python3 -m py_compile app.py' }
        }

        stage('Build Image') {
            steps { sh 'docker build -t $IMAGE:$TAG -t $IMAGE:latest .' }
        }

        stage('Push Image') {
            steps {
                withCredentials([usernamePassword(credentialsId: 'dockerhub',
                                 usernameVariable: 'DH_USER',
                                 passwordVariable: 'DH_PASS')]) {
                    sh 'echo $DH_PASS | docker login -u $DH_USER --password-stdin'
                    sh 'docker push $IMAGE:$TAG'
                    sh 'docker push $IMAGE:latest'
                }
            }
        }

        stage('Deploy') {
            steps {
                sshagent(['app-server-ssh']) {
                    sh """
                    ssh -o StrictHostKeyChecking=no ubuntu@$APP_IP '
                      docker pull $IMAGE:$TAG &&
                      docker rm -f flask-app || true &&
                      docker run -d --name flask-app --restart unless-stopped -p 80:5000 $IMAGE:$TAG
                    '
                    """
                }
            }
        }

        stage('Health Check') {
            steps {
                sh 'sleep 5 && curl -f http://$APP_IP'
            }
        }
    }

    post {
        success { echo "Deployed build ${BUILD_NUMBER} ✅" }
        failure { echo "Pipeline failed ❌ - check console output" }
    }
}