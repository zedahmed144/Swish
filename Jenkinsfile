pipeline {
    agent any

    environment {
        REGISTRY_URL = '381492184593.dkr.ecr.us-east-1.amazonaws.com'
        IMAGE_NAME = 'swish'
    }

    stages {
        stage('Checkout Code') {
            steps {
                checkout scm
            }
        }

        stage('Build Docker Image') {
            steps {
                script {
                    // Building the Docker image from Dockerfile in the project root
                    sh "docker build -t ${IMAGE_NAME}:latest ."
                }
            }
        }

        stage('Tag Docker Image') {
            steps {
                script {
                    // Tagging the Docker image for the ECR repository
                    sh "docker tag ${IMAGE_NAME}:latest ${REGISTRY_URL}/${IMAGE_NAME}:latest"
                }
            }
        }

        stage('Push to ECR') {
            steps {
                script {
                    // Logging into AWS ECR
                    sh "aws ecr get-login-password --region us-east-1 | docker login --username AWS --password-stdin ${REGISTRY_URL}"
                    // Pushing the Docker image to AWS ECR
                    sh "docker push ${REGISTRY_URL}/${IMAGE_NAME}:latest"
                }
            }
        }

        stage('Deploy to Kubernetes') {
            steps {
                script {
                    // Using kubectl to update the deployment in Kubernetes
                    sh """
                        kubectl set image deployment/my-app-deployment my-app-container=${REGISTRY_URL}/${IMAGE_NAME}:latest --record
                    """
                }
            }
        }
    }

    post {
        always {
            script {
                // Optional: Cleanup Docker images from Jenkins agent
                sh "docker rmi ${REGISTRY_URL}/${IMAGE_NAME}:latest ${IMAGE_NAME}:latest"
            }
        }
    }
}
