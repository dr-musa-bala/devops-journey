pipeline {
    agent any

    environment {
        IMAGE_NAME = 'musabalaaudu/sillypets-image:V1.0'
        GIT_REPO   = 'https://github.com/dr-musa-bala/devops-journey.git'
    }

    stages {
        stage('1. Fetch Code from GitHub') {
            steps {
                echo "--> Pulling latest source code and Dockerfile..."
                git branch: 'main', url: "${GIT_REPO}"
            }
        }

        stage('2. Bake the App (Build)') {
            steps {
                echo "--> Building Docker image: ${IMAGE_NAME}..."
                sh "docker build -t ${IMAGE_NAME} ."
            }
        }

        stage('3. Taste Test (Test)') {
            steps {
                echo "--> Setting up dynamic container testing..."
                sh '''
                    # Navigated Issue #1: Detect current network context dynamically
                    JENKINS_NET=$(docker inspect -f '{{range $k, $v := .NetworkSettings.Networks}}{{$k}}{{end}}' $(hostname) 2>/dev/null || echo "bridge")
                    echo "Active Network Context: ${JENKINS_NET}"

                    # Navigated Issue #1 & #2: Attach test container to shared network
                    docker run -d --name test-sillypets --network "${JENKINS_NET}" ${IMAGE_NAME}
                    sleep 3

                    # Navigated Issue #2: Health Check via Embedded DNS or IP fallback
                    if [ "${JENKINS_NET}" != "bridge" ]; then
                        echo "Testing via Docker DNS (http://test-sillypets)..."
                        curl -f "http://test-sillypets" || exit 1
                    else
                        echo "Testing via direct IP fallback..."
                        CONTAINER_IP=$(docker inspect -f '{{range .NetworkSettings.Networks}}{{.IPAddress}}{{end}}' test-sillypets)
                        curl -f "http://${CONTAINER_IP}" || exit 1
                    fi
                '''
            }
        }
    }

    post {
        always {
  
            echo "--> Cleaning up test container artifacts..."
            sh "docker stop test-sillypets || true"
            sh "docker rm test-sillypets || true"
        }
        success {
            echo "🎉 YAY! The app was built and tested successfully!"
        }
        failure {
            echo "❌ Build failed. Check execution logs above."
        }
    }
}
//testing