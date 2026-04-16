pipeline {
    agent any

    environment {
        DOCKERHUB_USERNAME     = 'abdulrazzakjakati'
        APP_NAME               = 'food-delivery-eureka-service'
        GITOPS_REPO_URL        = 'git@github.com:abdulrazzakjakati/deployment.git'
        GITOPS_BRANCH          = 'master'
        MANIFEST_PATH          = "helm/restaurant-microservices-project/eureka-service/values.yaml"

        DOCKERHUB_CREDENTIALS  = credentials('DOCKER_HUB_CREDENTIAL')
        VERSION               = "${env.BUILD_ID}"
        DOCKER_IMAGE           = "${DOCKERHUB_USERNAME}/${APP_NAME}:${VERSION}"
    }

    stages {
        stage('Docker Build & Push') {
            steps {
                sh '''
                    # Login to DockerHub
                    echo "$DOCKERHUB_CREDENTIALS_PSW" | docker login -u "$DOCKERHUB_CREDENTIALS_USR" --password-stdin

                    # Setup buildx
                    docker buildx create --name multiarch-builder --use --bootstrap || docker buildx use multiarch-builder

                    # Build and push with remote caching to stay within Free Tier time limits
                    docker buildx build \\
                        --platform linux/amd64,linux/arm64 \\
                        --cache-from=type=registry,ref=${DOCKERHUB_USERNAME}/${APP_NAME}:buildcache \\
                        --cache-to=type=registry,ref=${DOCKERHUB_USERNAME}/${APP_NAME}:buildcache,mode=max \\
                        --tag ${DOCKER_IMAGE} \\
                        --push . 
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
                        # ✅ Best Practice: Target the 'tag' specifically
                        sed -i "s|tag:.*|tag: \\"${VERSION}\\"|" ${MANIFEST_PATH}
                        
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
                sh 'docker buildx rm multiarch-builder || true'
            }
        }
    }

    post {
        always {
            cleanWs()
        }
    }
}