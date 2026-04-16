pipeline {
    agent any  // ✅ Docker socket mounted

    environment {
        DOCKERHUB_USERNAME     = 'abdulrazzakjakati'
        APP_NAME               = 'food-delivery-eureka-service'
        GITOPS_REPO_URL        = 'git@github.com:abdulrazzakjakati/deployment.git'
        GITOPS_BRANCH          = 'master'
        MANIFEST_PATH          = "helm/restaurant-microservices-project/eureka-service/values.yaml"

        DOCKERHUB_CREDENTIALS  = credentials('DOCKER_HUB_CREDENTIAL')
        DOCKER_IMAGE           = "${DOCKERHUB_USERNAME}/${APP_NAME}:latest"
    }

    tools {
        maven 'Maven'
    }

    stages {
        stage('Maven Build') {
            steps {
                sh 'mvn clean package -DskipTests'
            }
        }

        stage('Docker Build & Push') {
            steps {
                sh '''
                    echo "Workspace contents:"
                    ls -la

                    echo "Dockerfile exists:"
                    test -f Dockerfile && echo "✓ Found" || echo "✗ Missing!"

                    # Login to DockerHub
                    echo "$DOCKERHUB_CREDENTIALS_PSW" | docker login -u "$DOCKERHUB_CREDENTIALS_USR" --password-stdin

                    # Setup buildx for multi-arch support
                    docker buildx create --name multiarch-builder --use --bootstrap || docker buildx use multiarch-builder

                    # Build and push for both amd64 and arm64
                    docker buildx build \
                        --platform linux/amd64,linux/arm64 \
                        --tag ${DOCKER_IMAGE} \
                        --push \
                        .

                    # Cleanup builder
                    docker buildx rm multiarch-builder || true
                '''
            }
        }

        stage('Cleanup') {
            steps {
                deleteDir()
            }
        }
    }

    post {
        always {
            cleanWs()
        }
    }
}