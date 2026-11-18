pipeline {
    agent any

    options {
        timestamps()
        disableConcurrentBuilds()
        buildDiscarder(logRotator(numToKeepStr: '20'))
    }

    triggers {
        pollSCM('H/2 * * * *')
    }

    environment {
        AWS_REGION      = 'us-east-1'
        ECR_REPO        = 'barakah-app'
        ECS_CLUSTER     = 'barakah-cluster'
        STAGING_SERVICE = 'barakah-app-staging'
        PROD_SERVICE    = 'barakah-app-svc'
    }

    stages {
        stage('Checkout') {
            steps {
                checkout scm
                script {
                    env.IMAGE_TAG  = sh(script: 'git rev-parse --short=7 HEAD', returnStdout: true).trim()
                    env.ACCOUNT_ID = sh(script: 'aws sts get-caller-identity --query Account --output text', returnStdout: true).trim()
                    env.REGISTRY   = "${env.ACCOUNT_ID}.dkr.ecr.${env.AWS_REGION}.amazonaws.com"
                    env.IMAGE_URI  = "${env.REGISTRY}/${env.ECR_REPO}:${env.IMAGE_TAG}"
                }
                echo "Commit ${env.IMAGE_TAG}, image ${env.IMAGE_URI}"
            }
        }

        stage('Lint') {
            steps {
                sh '''
                    python3 -m venv .venv
                    . .venv/bin/activate
                    pip install -q -r requirements-dev.txt
                    flake8
                    echo "Lint passed"
                '''
            }
        }

        stage('Unit Tests') {
            steps {
                sh '''
                    . .venv/bin/activate
                    pytest -q --junitxml=reports/junit.xml
                '''
            }
            post {
                always {
                    junit 'reports/junit.xml'
                }
            }
        }

        stage('SAST Scan') {
            steps {
                withCredentials([string(credentialsId: 'synk-token', variable: 'SNYK_TOKEN')]) {
                    sh 'bash sast.sh'
                }
            }
        }

        stage('Docker Build') {
            steps {
                sh 'docker build -t "$IMAGE_URI" .'
            }
        }

        stage('Push to Registry') {
            steps {
                sh '''
                    if aws ecr describe-images --region "$AWS_REGION" --repository-name "$ECR_REPO" --image-ids imageTag="$IMAGE_TAG" >/dev/null 2>&1; then
                        echo "Image $IMAGE_URI already in ECR, skipping push"
                    else
                        aws ecr get-login-password --region "$AWS_REGION" | docker login --username AWS --password-stdin "$REGISTRY"
                        docker push "$IMAGE_URI"
                        docker logout "$REGISTRY"
                    fi
                '''
            }
        }

        stage('Deploy to Staging') {
            steps {
                sh 'bash deploy-ecs.sh "$STAGING_SERVICE"'
                script {
                    env.TASKDEF_ARN = readFile('taskdef-arn.txt').trim()
                }
                echo "Staging is running ${env.TASKDEF_ARN}"
            }
        }

        stage('Approve Production') {
            steps {
                timeout(time: 30, unit: 'MINUTES') {
                    input message: "Deploy ${env.IMAGE_TAG} to production?",
                          ok: 'Deploy to Production',
                          submitter: 'admin'
                }
            }
        }

        stage('Deploy to Production') {
            steps {
                sh 'bash deploy-ecs.sh "$PROD_SERVICE" "$TASKDEF_ARN"'
            }
        }
    }

    post {
        always {
            sh 'if [ -n "${IMAGE_URI:-}" ]; then docker image rm "$IMAGE_URI" >/dev/null 2>&1 || true; fi'
        }
        success {
            echo "Released ${env.IMAGE_TAG} to production"
        }
        aborted {
            echo "Production deploy was not approved. Staging keeps ${env.IMAGE_TAG}."
        }
        failure {
            echo 'Pipeline failed. Check the stage that turned red.'
        }
    }
}
