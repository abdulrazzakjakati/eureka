pipeline {
    agent any  // ✅ Docker socket mounted

    environment {
        DOCKERHUB_USERNAME     = 'abdulrazzakjakati'
        APP_NAME               = 'food-delivery-eureka-service'
        GITOPS_REPO_URL        = 'git@github.com:abdulrazzakjakati/deployment.git'
        GITOPS_BRANCH          = 'master'
        MANIFEST_PATH          = "helm/restaurant-microservices-project/eureka-service/values.yaml"
        SONAR_PROJECT_KEY      = 'com.codeddecode:eureka'
        SONAR_URL              = 'http://140.245.14.252:8761'
        COVERAGE_THRESHOLD     = '50.0'

        DOCKERHUB_CREDENTIALS  = credentials('DOCKER_HUB_CREDENTIAL')
        SONAR_TOKEN            = credentials('sonar-token')
        VERSION                = "${env.BUILD_ID}"
        DOCKER_IMAGE           = "${DOCKERHUB_USERNAME}/${APP_NAME}:${VERSION}"
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

        stage('Run Tests') {
            steps {
                sh 'mvn test'
            }
        }

        stage('SonarQube Analysis') {
            steps {
                withCredentials([string(credentialsId: 'sonar-token', variable: 'SONAR_TOKEN')]) {
                    sh '''
                        mvn clean verify sonar:sonar \
                        -Dsonar.host.url="${SONAR_URL}" \
                        -Dsonar.token="$SONAR_TOKEN" \
                        -Dsonar.projectKey="${SONAR_PROJECT_KEY}" \
                        -Dsonar.coverage.jacoco.xmlReportPaths=target/site/jacoco/jacoco.xml
                    '''
                }
            }
        }

        stage('Check Code Coverage') {
            steps {
                script {
                    withCredentials([string(credentialsId: 'sonar-token', variable: 'SONAR_TOKEN')]) {
                        def apiUrl = "${SONAR_URL}/api/measures/component?component=${SONAR_PROJECT_KEY}&metricKeys=coverage"

                        withEnv(["API_URL=${apiUrl}"]) {
                            def response = sh(
                                    script: '''
                                    set +x
                                    test -n "$API_URL"
                                    curl -s -u "$SONAR_TOKEN:" "$API_URL"
                                ''',
                                    returnStdout: true
                            ).trim()

                            echo "SonarQube API response: ${response}"

                            def json = new groovy.json.JsonSlurper().parseText(response)
                            def measures = json?.component?.measures

                            if (!measures || measures.isEmpty()) {
                                error "Coverage metric not returned by SonarQube. Check JaCoCo/test coverage report configuration."
                            }

                            def coverage = measures[0].value.toDouble()
                            echo "Coverage raw value: ${coverage}%"

                            if (coverage < COVERAGE_THRESHOLD.toDouble()) {
                                error "Coverage ${coverage}% < ${COVERAGE_THRESHOLD}% threshold. Fix tests!"
                            }
                        }
                    }
                }
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