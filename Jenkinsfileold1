
pipeline {
    agent any

    options {
        timestamps()
        disableConcurrentBuilds()
        timeout(time: 120, unit: 'MINUTES')
        buildDiscarder(logRotator(numToKeepStr: '30'))
    }

    stages {

        stage('Checkout') {
            steps {
                checkout scm
            }
        }

        stage('Verify Environment') {
            steps {
                sh '''
                    set -eu

                    echo "===================================="
                    echo "VERIFYING ENVIRONMENT"
                    echo "===================================="

                    ruby --version
                    bundle --version
                    git rev-parse --short HEAD
                '''
            }
        }

        stage('Install Dependencies') {
            steps {
                sh '''
                    set -eu

                    echo "Installing Ruby dependencies..."

                    bundle config set --local path vendor/bundle
                    bundle install
                '''
            }
        }

        stage('Run Tests') {
            steps {
                sh '''
                    set -eu

                    echo "Running Rails tests..."

                    bundle exec rails test
                '''
            }
        }

        stage('Capistrano Preflight') {
            steps {
                sshagent(credentials: ['demand-app-ssh-key']) {
                    withCredentials([
                        string(credentialsId: 'rr-demo-secret-key-base', variable: 'SECRET_KEY_BASE'),
                        string(credentialsId: 'rr-demo-db-host', variable: 'DB_HOST'),
                        string(credentialsId: 'rr-demo-db-name', variable: 'DB_NAME'),
                        string(credentialsId: 'rr-demo-db-username', variable: 'DB_USERNAME'),
                        string(credentialsId: 'rr-demo-db-password', variable: 'DB_PASSWORD'),
                        string(credentialsId: 'rr-demo-db-port', variable: 'DB_PORT'),
                        string(credentialsId: 'rr-demo-db-queue-name', variable: 'DB_QUEUE_NAME'),
                        string(credentialsId: 'rr-demo-db-cache-name', variable: 'DB_CACHE_NAME'),
                        string(credentialsId: 'rr-demo-db-cable-name', variable: 'DB_CABLE_NAME')
                    ]) {
                        sh '''
                            set -eu

                            echo "Running Capistrano deploy check..."

                            bundle exec cap staging deploy:check
                        '''
                    }
                }
            }
        }

        stage('Approve Deployment') {
            steps {
                timeout(time: 30, unit: 'MINUTES') {
                    input(
                        message: 'Deploy this application revision to both Demand servers?',
                        ok: 'Approve Deployment'
                    )
                }
            }
        }

        stage('Deploy Application') {
            steps {
                sshagent(credentials: ['demand-app-ssh-key']) {
                    withCredentials([
                        string(credentialsId: 'rr-demo-secret-key-base', variable: 'SECRET_KEY_BASE'),
                        string(credentialsId: 'rr-demo-db-host', variable: 'DB_HOST'),
                        string(credentialsId: 'rr-demo-db-name', variable: 'DB_NAME'),
                        string(credentialsId: 'rr-demo-db-username', variable: 'DB_USERNAME'),
                        string(credentialsId: 'rr-demo-db-password', variable: 'DB_PASSWORD'),
                        string(credentialsId: 'rr-demo-db-port', variable: 'DB_PORT'),
                        string(credentialsId: 'rr-demo-db-queue-name', variable: 'DB_QUEUE_NAME'),
                        string(credentialsId: 'rr-demo-db-cache-name', variable: 'DB_CACHE_NAME'),
                        string(credentialsId: 'rr-demo-db-cable-name', variable: 'DB_CABLE_NAME')
                    ]) {
                        sh '''
                            set -eu

                            echo "Deploying application to Demand servers..."

                            bundle exec cap staging deploy
                        '''
                    }
                }
            }
        }

        stage('Verify Application Health') {
            steps {
                sshagent(credentials: ['demand-app-ssh-key']) {
                    sh '''
                        set -eu

                        SERVERS="10.20.133.231 10.20.143.220"

                        for SERVER in $SERVERS; do

                            echo "===================================="
                            echo "Checking application on ${SERVER}"
                            echo "===================================="

                            RESPONSE=$(ssh \
                                -o BatchMode=yes \
                                -o ConnectTimeout=10 \
                                -o StrictHostKeyChecking=accept-new \
                                ubuntu@"${SERVER}" \
                                'curl --fail --silent --show-error http://127.0.0.1:3000/health')

                            echo "Health response: ${RESPONSE}"

                            echo "$RESPONSE" | grep -Eq '"status"[[:space:]]*:[[:space:]]*"ok"' || {
                                echo "ERROR: Application health check failed on ${SERVER}"
                                exit 1
                            }

                            echo "Application is healthy on ${SERVER}."

                        done

                        echo "Both Demand servers are healthy."
                    '''
                }
            }
        }

        stage('Trigger Infrastructure Pipeline') {
            steps {
                echo 'Application deployment and health checks succeeded.'
                echo 'Triggering infrastructure automation...'

                build(
                    job: 'rr-demo-infra-automation',
                    wait: true,
                    propagate: true
                )

                echo 'Infrastructure rollout completed successfully.'
            }
        }
    }

    post {
        success {
            echo 'Application deployment and infrastructure rollout completed successfully.'
        }

        failure {
            echo 'Pipeline failed. Check the failed stage and console output.'
        }

        always {
            echo 'Cleaning application workspace...'

            cleanWs(
                deleteDirs: true,
                disableDeferredWipeout: true,
                notFailBuild: true
            )

            echo 'Application pipeline execution finished.'
        }
    }
}
