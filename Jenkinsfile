pipeline {
    agent any

    environment {
        DOCKER_HUB_USER = 'musabalaaudu'
        IMAGE_NAME      = 'sillypets'
        IMAGE_TAG       = "${env.BUILD_NUMBER}"
        CONTAINER_NAME  = 'sillypets-live'
        APP_PORT        = '5000'
        // Paste your Discord/Slack Webhook URL here or store it in Jenkins Credentials
        WEBHOOK_URL     = 'https://discord.com/api/webhooks/1532589693160390768/nwvj7fBWaLpwsutCj2yakmhEvZJFrSqPtqWhXdxgI6QMEtcJcJDnSu4KGw491Ns1nsHb'
    }

    stages {
        stage('Checkout') {
            steps {
                checkout scm
            }
        }

        stage('Build Docker Image') {
            steps {
                script {
                    sh "docker build -t ${DOCKER_HUB_USER}/${IMAGE_NAME}:${IMAGE_TAG} ."
                    sh "docker tag ${DOCKER_HUB_USER}/${IMAGE_NAME}:${IMAGE_TAG} ${DOCKER_HUB_USER}/${IMAGE_NAME}:latest"
                }
            }
        }

        stage('Push to Docker Hub') {
            steps {
                script {
                    withCredentials([usernamePassword(credentialsId: 'docker-hub-credentials', usernameVariable: 'DOCKER_USER', passwordVariable: 'DOCKER_PASS')]) {
                        sh "echo \$DOCKER_PASS | docker login -u \$DOCKER_USER --password-stdin"
                        sh "docker push ${DOCKER_HUB_USER}/${IMAGE_NAME}:${IMAGE_TAG}"
                        sh "docker push ${DOCKER_HUB_USER}/${IMAGE_NAME}:latest"
                    }
                }
            }
        }

        stage('Deploy Container (CD)') {
            steps {
                script {
                    sh "docker stop ${CONTAINER_NAME} || true"
                    sh "docker rm ${CONTAINER_NAME} || true"
                    sh "docker pull ${DOCKER_HUB_USER}/${IMAGE_NAME}:latest"
                    sh "docker run -d --name ${CONTAINER_NAME} -p ${APP_PORT}:80 ${DOCKER_HUB_USER}/${IMAGE_NAME}:latest"
                }
            }
        }
    }

    post {
        always {
            sh "docker logout"
        }

        success {
            sh """
                curl -H "Content-Type: application/json" \
                     -X POST \
                     -d '{"content": "✅ **Jenkins Build #${env.BUILD_NUMBER} SUCCESS**\\n**Job:** ${env.JOB_NAME}\\n**Status:** Deployed to http://localhost:${APP_PORT}"}' \
                     ${WEBHOOK_URL}
            """
        }

        failure {
            sh """
                curl -H "Content-Type: application/json" \
                     -X POST \
                     -d '{"content": "🚨 **Jenkins Build #${env.BUILD_NUMBER} FAILED**\\n**Job:** ${env.JOB_NAME}\\n**Console Logs:** ${env.BUILD_URL}console"}' \
                     ${WEBHOOK_URL}
            """
        }
    }
}