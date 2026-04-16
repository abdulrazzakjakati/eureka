pipeline {
    agent any  // ✅ Docker socket mounted

    environment {
        DOCKERHUB_USERNAME     = 'abdulrazzakjakati'
        APP_NAME               = 'food-delivery-eureka-service'
        GITOPS_REPO_URL        = 'git@github.com:abdulrazzakjakati/deployment.git'
        GITOPS_BRANCH          = 'master'
        MANIFEST_PATH          = "helm/restaurant-microservices-project/eureka-service/values.yaml"

        DOCKERHUB_CREDENTIALS  = credentials('DOCKER_HUB_CREDENTIAL')
        DOCKER_IMAGE           = "${DOCKERHUB_USERNAME}/${APP_NAME}:${VERSION}"
    }

    stages {
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

        stage('Update GitOps Manifests') {
            steps {
                checkout scmGit(
                        branches: [[name: "*/${GITOPS_BRANCH}"]],
                        userRemoteConfigs: [[credentialsId: 'git-ssh', url: "${GITOPS_REPO_URL}"]]
                )
                script {
                    sh """
                        sed -i "s|image:.*|image: ${DOCKER_IMAGE}|" ${MANIFEST_PATH}
                        git config user.name "Jenkins"
                        git config user.email "jenkins@local"
                        git add ${MANIFEST_PATH}
                        git commit -m "Update ${APP_NAME} to v${VERSION}"
                    """
                    sshagent(['git-ssh']) {
                        sh "git push origin HEAD:${GITOPS_BRANCH}"
                    }
                }
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