
pipeline {
    agent any

    options {
        timestamps()
        timeout(time: 2, unit: 'HOURS')
        disableConcurrentBuilds()
        skipDefaultCheckout(true)
    }

    environment {
        APP_NAME   = 'rr-demo'
        APP_BRANCH = 'main'
        DEPLOY_ENV = 'staging'

        DEMAND_A1  = '10.20.133.231'
        DEMAND_A2  = '10.20.143.220'

        REMOTE_USER = 'ubuntu'
        APP_PATH    = '/var/www/rr-demo/current'
        HEALTH_URL  = 'http://127.0.0.1:3000/health'

        INFRA_JOB = 'rr-demo-infra-automation'
    }

    stages {
        stage('Checkout') {
            steps {
                checkout scm
                script {
                    env.APP_COMMIT = sh(
                        script: 'git rev-parse HEAD',
                        returnStdout: true
                    ).trim()
                }
            }
        }

        stage('Verify Environment') {
            steps {
                sh '''
                    set -eu
                    command -v ruby
                    command -v bundle
                    command -v git
                    command -v ssh
                '''
            }
        }

        stage('Install Dependencies') {
            steps {
                sh '''
                    set -eu
                    bundle config set deployment true
                    bundle config unset without || true
                    bundle install
                    bundle check
                '''
            }
        }

        stage('Run Tests') {
            steps {
                sh 'RAILS_ENV=test bundle exec rails test'
            }
        }

        stage('Capistrano Preflight') {
            steps {
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
                    sshagent(credentials: ['demand-app-ssh-key']) {
                        sh 'bundle exec cap staging deploy:check'
                    }
                }
            }
        }

        stage('Approve Deployment') {
            steps {
                timeout(time: 30, unit: 'MINUTES') {
                    input(
                        message: "Deploy rr-demo build #${env.BUILD_NUMBER}?",
                        ok: 'Approve',
                        submitter: 'admin'
                    )
                }
            }
        }

        stage('Deploy Application') {
            steps {
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
                    sshagent(credentials: ['demand-app-ssh-key']) {
                        sh 'bundle exec cap staging deploy'
                    }
                }
            }
        }

        stage('Health Check') {
            steps {
                sshagent(credentials: ['demand-app-ssh-key']) {
                    sh '''
                        set -eu
                        ssh -o BatchMode=yes \
                            -o ConnectTimeout=15 \
                            -o StrictHostKeyChecking=accept-new \
                            ${REMOTE_USER}@${DEMAND_A2} \
                            "curl --fail --silent --show-error ${HEALTH_URL}"
                    '''
                }
            }
        }

        stage('Verify Deployed Revision') {
            steps {
                sshagent(credentials: ['demand-app-ssh-key']) {
                    sh '''
                        set -eu
                        DEPLOYED_COMMIT=$(ssh \
                            -o BatchMode=yes \
                            -o ConnectTimeout=15 \
                            -o StrictHostKeyChecking=accept-new \
                            ${REMOTE_USER}@${DEMAND_A2} \
                            "cat ${APP_PATH}/REVISION")

                        test "$DEPLOYED_COMMIT" = "$APP_COMMIT"
                    '''
                }
            }
        }

        stage('Infrastructure Automation') {
            steps {
                build(
                    job: "${INFRA_JOB}",
                    parameters: [
                        string(name: 'APP_BUILD_NUMBER', value: env.BUILD_NUMBER),
                        string(name: 'APP_GIT_COMMIT', value: env.APP_COMMIT)
                    ],
                    wait: true,
                    propagate: true
                )
            }
        }
    }

    post {
        success {
            echo "rr-demo build #${env.BUILD_NUMBER} deployed successfully."
        }
        failure {
            echo 'Application deployment or infrastructure automation failed.'
        }
        aborted {
            echo 'Application deployment aborted.'
        }
        always {
            cleanWs()
        }
    }
}
