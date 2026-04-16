pipeline {
    agent any  // ✅ Docker socket mounted

    environment {
        DOCKERHUB_USERNAME     = 'abdulrazzakjakati'
        APP_NAME               = 'food-delivery-eureka-service'
//        GITOPS_REPO_URL        = 'git@github.com:abdulrazzakjakati/deployment.git'
        GITOPS_BRANCH          = 'master'
        MANIFEST_PATH          = "helm/restaurant-microservices-project/eureka-service/values.yaml"
//        SONAR_PROJECT_KEY      = 'com.codeddecode:eureka'
//        SONAR_URL              = 'http://140.245.14.252:8761'
//        COVERAGE_THRESHOLD     = '50.0'

        DOCKERHUB_CREDENTIALS  = credentials('DOCKER_HUB_CREDENTIAL')
//        SONAR_TOKEN            = credentials('sonar-token')
//        VERSION                = "${env.BUILD_ID}"
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

                    docker build -t ${DOCKER_IMAGE} .
                    docker push ${DOCKER_IMAGE}
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