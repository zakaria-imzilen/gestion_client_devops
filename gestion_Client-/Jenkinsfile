pipeline {
    agent any

    environment {
        DOCKER_CREDENTIALS = 'docker-creds'                    // Jenkins credential ID for Docker registry
        DOCKER_IMAGE = "mydockerhubuser/gestion-client"        // Docker image name
        SONARQUBE = 'SonarQube'                                // SonarQube server ID in Jenkins
    }

    stages {
        stage('Checkout') {
            steps {
                git branch: 'main', url: 'https://github.com/<your-repo>.git'
            }
        }

        stage('Install Dependencies') {
            steps {
                sh 'composer install --no-interaction --prefer-dist'
            }
        }

        stage('Run Tests') {
            steps {
                sh 'vendor/bin/phpunit --log-junit reports/phpunit.xml'
            }
            post {
                always {
                    junit 'reports/phpunit.xml'
                }
            }
        }

        stage('SonarCloud Analysis') {
            agent { 
                docker { 
                    image 'maven:3.9-eclipse-temurin-21'
                    args '-v $HOME/.m2:/root/.m2' 
                } 
            }
            steps {
                withCredentials([string(credentialsId: 'sonarcloud-token', variable: 'SONAR_TOKEN')]) {
                    sh '''
                        ./mvnw -q -DskipTests sonar:sonar \
                        -Dsonar.login=$SONAR_TOKEN \
                        -Dsonar.host.url=https://sonarcloud.io
                    '''
                }
            }
        }

        stage('Docker Build & Push') {
            steps {
                script {
                    docker.withRegistry('https://index.docker.io/v1/', DOCKER_CREDENTIALS) {
                        def image = docker.build(DOCKER_IMAGE + ":${env.BUILD_NUMBER}")
                        image.push()
                        image.push("latest")
                    }
                }
            }
        }
    }

    post {
        success {
            echo 'Pipeline completed successfully!'
        }
        failure {
            echo 'Pipeline failed!'
        }
    }
}
