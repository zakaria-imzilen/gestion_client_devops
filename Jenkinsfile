pipeline {
  agent none
  options { timestamps(); ansiColor('xterm') }

  environment {
    DOCKER_CREDENTIALS = 'docker-creds'                 // Jenkins credential ID for your registry
    DOCKER_IMAGE       = 'meriemrima/gestion-client'
  }

  stages {
    stage('Checkout') {
      agent any
      steps {
        git branch: 'master', url: 'https://github.com/zakaria-imzilen/gestion_client_devops.git'
        script { env.COMMIT_SHA = sh(script: 'git rev-parse --short HEAD', returnStdout: true).trim() }
      }
    }

    stage('Install Dependencies & Test (PHP)') {
      agent {
        docker {
          image 'composer:2'                            // PHP + Composer preinstalled
          args  '-u 0:0'                                // run as root to avoid perms issues in Docker volumes
        }
      }
      steps {
        sh '''
          mkdir -p reports
          composer install --no-interaction --prefer-dist
          vendor/bin/phpunit --log-junit reports/phpunit.xml --coverage-clover reports/coverage.xml
        '''
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
          image 'sonarsource/sonar-scanner-cli:latest'
        }
      }
      steps {
        withCredentials([string(credentialsId: 'sonarcloud-token', variable: 'SONAR_TOKEN')]) {
          sh '''
            sonar-scanner \
              -Dsonar.login=$SONAR_TOKEN \
              -Dsonar.host.url=https://sonarcloud.io
          '''
        }
      }
    }

    stage('Quality Gate (SonarCloud)') {
      // Poll SonarCloud API to enforce the gate
      agent { docker { image 'alpine:3.20' } }
      steps {
        withCredentials([string(credentialsId: 'sonarcloud-token', variable: 'SONAR_TOKEN')]) {
          sh '''
            set -e
            apk add --no-cache curl jq >/dev/null
            REPORT="reports/task.txt"
            # locate report-task.txt written by sonar-scanner
            REPORT_PATH=$( (ls -1 **/report-task.txt 2>/dev/null || true) | head -n1 )
            [ -n "$REPORT_PATH" ] || { echo "report-task.txt not found"; exit 1; }
            ceTaskUrl=$(grep '^ceTaskUrl=' "$REPORT_PATH" | cut -d= -f2)

            # wait for compute
            for i in $(seq 1 30); do
              json=$(curl -s -u "$SONAR_TOKEN": "$ceTaskUrl")
              status=$(echo "$json" | jq -r '.task.status')
              [ "$status" = "SUCCESS" -o "$status" = "FAILED" ] && break
              sleep 2
            done
            [ "$status" = "SUCCESS" ] || { echo "Compute status: $status"; exit 1; }

            analysisId=$(echo "$json" | jq -r '.task.analysisId')
            qg=$(curl -s -u "$SONAR_TOKEN": \
              "https://sonarcloud.io/api/qualitygates/project_status?analysisId=$analysisId")
            qgstatus=$(echo "$qg" | jq -r '.projectStatus.status')
            echo "Quality Gate: $qgstatus"
            [ "$qgstatus" = "OK" ] || { echo "Quality Gate failed"; exit 1; }
          '''
        }
      }
    }

    stage('Docker Build & Push') {
      agent { docker { image 'docker:26-cli'; args '-v /var/run/docker.sock:/var/run/docker.sock' } }
      steps {
        withCredentials([usernamePassword(credentialsId: DOCKER_CREDENTIALS, usernameVariable: 'U', passwordVariable: 'P')]) {
          sh """
            echo 'Logging into registry'
            docker login -u "$U" -p "$P"
            echo 'Building image'
            docker build -t ${DOCKER_IMAGE}:${COMMIT_SHA} -t ${DOCKER_IMAGE}:latest .
            echo 'Pushing image'
            docker push ${DOCKER_IMAGE}:${COMMIT_SHA}
            docker push ${DOCKER_IMAGE}:latest
          """
        }
      }
    }
  }

  post {
    success { echo "Pipeline OK — image tag: ${COMMIT_SHA}" }
    failure { echo "Pipeline FAILED" }
  }
}
