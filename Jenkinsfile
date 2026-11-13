
pipeline {
    agent any

    options {
        timestamps()
        timeout(time: 2, unit: 'HOURS')
        disableConcurrentBuilds()
        skipDefaultCheckout(true)
    }

    environment {
        APP_NAME = 'rr-demo'
        APP_BRANCH = 'main'

        // Demand-a1 is intentionally stopped to free EC2 vCPU quota.
        // Do not include it in deployment or health checks.
        DEMAND_A1 = '10.20.133.231'

        // Only active deployment target for this POC.
        DEMAND_A2 = '10.20.143.220'

        DEPLOY_ENV = 'staging'
    }

    stages {

        stage('Checkout') {
            steps {
                echo '========================================'
                echo 'CHECKING OUT APPLICATION SOURCE'
                echo '========================================'

                checkout scm

                sh '''
                    set -eu

                    echo "Repository: rr-demo"
                    echo "Branch: ${APP_BRANCH}"
                    echo "Commit: $(git rev-parse HEAD)"
                    echo "Short SHA: $(git rev-parse --short HEAD)"
                '''
            }
        }

        stage('Verify Environment') {
            steps {
                sh '''
                    set -eu

                    echo "========================================"
                    echo "VERIFYING JENKINS ENVIRONMENT"
                    echo "========================================"

                    ruby --version
                    bundle --version
                    git --version

                    echo "Application: ${APP_NAME}"
                    echo "Deployment environment: ${DEPLOY_ENV}"
                    echo "Deployment target: ${DEMAND_A2}"

                    echo "Demand-a1 ${DEMAND_A1} is intentionally excluded."
                '''
            }
        }

        stage('Install Dependencies') {
            steps {
                sh '''
                    set -eu

                    echo "========================================"
                    echo "INSTALLING RUBY DEPENDENCIES"
                    echo "========================================"

                    bundle config set --local path vendor/bundle
                    bundle install

                    echo "Bundle installation completed."
                '''
            }
        }

        stage('Run Tests') {
            steps {
                sh '''
                    set -eu

                    echo "========================================"
                    echo "RUNNING RAILS TESTS"
                    echo "========================================"

                    bundle exec rails test

                    echo "Rails test command completed successfully."
                '''
            }
        }

        stage('Capistrano Preflight') {
            steps {
                sshagent(credentials: ['demand-app-ssh-key']) {

                    withCredentials([
                        string(
                            credentialsId: 'rr-demo-secret-key-base',
                            variable: 'SECRET_KEY_BASE'
                        ),
                        string(
                            credentialsId: 'rr-demo-db-host',
                            variable: 'DB_HOST'
                        ),
                        string(
                            credentialsId: 'rr-demo-db-name',
                            variable: 'DB_NAME'
                        ),
                        string(
                            credentialsId: 'rr-demo-db-username',
                            variable: 'DB_USERNAME'
                        ),
                        string(
                            credentialsId: 'rr-demo-db-password',
                            variable: 'DB_PASSWORD'
                        ),
                        string(
                            credentialsId: 'rr-demo-db-port',
                            variable: 'DB_PORT'
                        ),
                        string(
                            credentialsId: 'rr-demo-db-queue-name',
                            variable: 'DB_QUEUE_NAME'
                        ),
                        string(
                            credentialsId: 'rr-demo-db-cache-name',
                            variable: 'DB_CACHE_NAME'
                        ),
                        string(
                            credentialsId: 'rr-demo-db-cable-name',
                            variable: 'DB_CABLE_NAME'
                        )
                    ]) {

                        sh '''
                            set -eu

                            echo "========================================"
                            echo "CAPISTRANO DEPLOYMENT PREFLIGHT"
                            echo "========================================"

                            echo "Checking deployment target: ${DEMAND_A2}"
                            echo "Demand-a1 is excluded: ${DEMAND_A1}"

                            bundle exec cap staging deploy:check

                            echo "Capistrano preflight completed successfully."
                        '''
                    }
                }
            }
        }

        stage('Approve Deployment') {
            steps {
                timeout(time: 30, unit: 'MINUTES') {

                    input(
                        message: """
Deploy application revision ${GIT_COMMIT ?: 'from current checkout'}?

Target:
- Demand-a2: ${DEMAND_A2}

Excluded:
- Demand-a1: ${DEMAND_A1} (intentionally stopped)

Infrastructure automation:
- Disabled for this POC run.
""",
                        ok: 'Approve Deployment',
                        submitter: 'admin'
                    )
                }
            }
        }

        stage('Deploy Application') {
            steps {
                sshagent(credentials: ['demand-app-ssh-key']) {

                    withCredentials([
                        string(
                            credentialsId: 'rr-demo-secret-key-base',
                            variable: 'SECRET_KEY_BASE'
                        ),
                        string(
                            credentialsId: 'rr-demo-db-host',
                            variable: 'DB_HOST'
                        ),
                        string(
                            credentialsId: 'rr-demo-db-name',
                            variable: 'DB_NAME'
                        ),
                        string(
                            credentialsId: 'rr-demo-db-username',
                            variable: 'DB_USERNAME'
                        ),
                        string(
                            credentialsId: 'rr-demo-db-password',
                            variable: 'DB_PASSWORD'
                        ),
                        string(
                            credentialsId: 'rr-demo-db-port',
                            variable: 'DB_PORT'
                        ),
                        string(
                            credentialsId: 'rr-demo-db-queue-name',
                            variable: 'DB_QUEUE_NAME'
                        ),
                        string(
                            credentialsId: 'rr-demo-db-cache-name',
                            variable: 'DB_CACHE_NAME'
                        ),
                        string(
                            credentialsId: 'rr-demo-db-cable-name',
                            variable: 'DB_CABLE_NAME'
                        )
                    ]) {

                        sh '''
                            set -eu

                            echo "========================================"
                            echo "DEPLOYING RAILS APPLICATION"
                            echo "========================================"

                            echo "Target server: ${DEMAND_A2}"
                            echo "Excluded server: ${DEMAND_A1}"

                            bundle exec cap staging deploy

                            echo "Capistrano deployment completed."
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

                        echo "========================================"
                        echo "APPLICATION HEALTH VERIFICATION"
                        echo "========================================"

                        echo "Demand-a1 ${DEMAND_A1} is intentionally stopped."
                        echo "Skipping Demand-a1."

                        SERVER="${DEMAND_A2}"

                        echo "Checking application on ${SERVER}"

                        RESPONSE=$(ssh \
                            -o BatchMode=yes \
                            -o ConnectTimeout=10 \
                            -o StrictHostKeyChecking=accept-new \
                            ubuntu@${SERVER} \
                            "curl --fail --silent --show-error --max-time 10 http://127.0.0.1:3000/health")

                        echo "Health response: ${RESPONSE}"

                        if ! printf '%s' "$RESPONSE" | grep -q '"status":"ok"'; then
                            echo "ERROR: Application health check failed."
                            exit 1
                        fi

                        echo "SUCCESS: Demand-a2 application is healthy."

                        echo "========================================"
                        echo "VERIFYING DEPLOYED REVISION"
                        echo "========================================"

                        DEPLOYED_REVISION=$(ssh \
                            -o BatchMode=yes \
                            -o ConnectTimeout=10 \
                            -o StrictHostKeyChecking=accept-new \
                            ubuntu@${SERVER} \
                            "cat /var/www/rr-demo/current/REVISION")

                        EXPECTED_REVISION=$(git rev-parse HEAD)

                        echo "Expected revision: ${EXPECTED_REVISION}"
                        echo "Deployed revision: ${DEPLOYED_REVISION}"

                        if [ "$DEPLOYED_REVISION" != "$EXPECTED_REVISION" ]; then
                            echo "ERROR: Deployed revision does not match Jenkins checkout."
                            exit 1
                        fi

                        echo "SUCCESS: Deployed revision matches Jenkins checkout."

                        echo "========================================"
                        echo "APPLICATION VERIFICATION PASSED"
                        echo "========================================"
                    '''
                }
            }
        }

        stage('Infrastructure Automation') {
            steps {
                echo '========================================'
                echo 'INFRASTRUCTURE AUTOMATION DISABLED'
                echo '========================================'

                echo 'No infrastructure pipeline will be triggered.'
                echo 'No AMI will be created.'
                echo 'No Launch Template version will be created.'
                echo 'No Auto Scaling Group update will be performed.'
                echo 'No Instance Refresh will be started.'

                echo 'Existing ASG refresh must be inspected separately.'
            }
        }
    }

    post {

        success {
            echo '''
========================================
APPLICATION DEPLOYMENT SUCCESSFUL
========================================

Application: rr-demo
Deployment target: Demand-a2
Demand-a1: Intentionally stopped and skipped
Application health: Verified
Git revision: Verified

Infrastructure automation: Disabled
========================================
'''
        }

        failure {
            echo '''
========================================
APPLICATION DEPLOYMENT FAILED
========================================

Please inspect the failed Jenkins stage
and review the console output.

Demand-a1 remains excluded.
Infrastructure automation was not triggered.
========================================
'''
        }

        aborted {
            echo 'Application deployment was aborted.'
        }

        always {
            echo 'Cleaning application Jenkins workspace...'
            cleanWs()
            echo 'Jenkins pipeline execution finished.'
        }
    }
}
