
pipeline {
    agent any

    options {
        timestamps()
        timeout(time: 2, unit: 'HOURS')
        disableConcurrentBuilds()
        skipDefaultCheckout(true)
    }

    environment {
        APP_NAME       = 'rr-demo'
        APP_BRANCH     = 'main'
        DEPLOY_ENV     = 'staging'

        // Deployment targets
        DEMAND_A1      = '10.20.133.231'
        DEMAND_A2      = '10.20.143.220'

        // Application configuration
        REMOTE_USER    = 'ubuntu'
        APP_PATH       = '/var/www/rr-demo/current'
        HEALTH_URL     = 'http://127.0.0.1:3000/health'

        // Downstream Jenkins job
        INFRA_JOB      = 'rr-demo-infra-automation'
    }

    stages {

        // --------------------------------------------------
        // 1. CHECKOUT
        // --------------------------------------------------

        stage('Checkout') {
            steps {
                checkout scm

                script {
                    env.APP_COMMIT = sh(
                        script: 'git rev-parse HEAD',
                        returnStdout: true
                    ).trim()

                    env.APP_SHORT_COMMIT = env.APP_COMMIT.take(7)

                    echo "Application: ${env.APP_NAME}"
                    echo "Branch: ${env.APP_BRANCH}"
                    echo "Commit: ${env.APP_COMMIT}"
                    echo "Short commit: ${env.APP_SHORT_COMMIT}"
                }
            }
        }

        // --------------------------------------------------
        // 2. VERIFY ENVIRONMENT
        // --------------------------------------------------

        stage('Verify Environment') {
            steps {
                sh '''
                    set -e

                    echo "Checking build environment..."

                    command -v ruby
                    command -v bundle
                    command -v git
                    command -v ssh

                    ruby --version
                    bundle --version
                    git --version

                    echo "Environment verification completed."
                '''
            }
        }

        // --------------------------------------------------
        // 3. INSTALL DEPENDENCIES
        // --------------------------------------------------

        stage('Install Dependencies') {
            steps {
                sh '''
                    set -e

                    echo "Installing application dependencies..."

                    bundle config set deployment true

                    # Keep development and test dependencies
                    # available for CI execution.
                    bundle config unset without || true

                    bundle install

                    echo "Verifying installed dependencies..."
                    bundle check

                    echo "Dependencies installed successfully."
                '''
            }
        }

        // --------------------------------------------------
        // 4. RUN RAILS TESTS
        // --------------------------------------------------

        stage('Run Tests') {
            steps {
                sh '''
                    set -e

                    echo "Running Rails tests..."

                    RAILS_ENV=test bundle exec rails test

                    echo "Rails tests completed successfully."
                '''
            }
        }

        // --------------------------------------------------
        // 5. CAPISTRANO PREFLIGHT
        // --------------------------------------------------

        stage('Capistrano Preflight') {
            steps {
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
                    sshagent(credentials: ['demand-app-ssh-key']) {
                        sh '''
                            set -e

                            echo "Running Capistrano deployment preflight..."

                            bundle exec cap staging deploy:check

                            echo "Capistrano preflight completed."
                        '''
                    }
                }
            }
        }

        // --------------------------------------------------
        // 6. MANUAL DEPLOYMENT APPROVAL
        // --------------------------------------------------

        stage('Approve Deployment') {
            steps {
                timeout(time: 30, unit: 'MINUTES') {
                    input(
                        message: """
Deploy application revision ${env.APP_SHORT_COMMIT}?

Full revision:
${env.APP_COMMIT}

Deployment target:
- Demand-a2: ${env.DEMAND_A2}

Excluded:
- Demand-a1: ${env.DEMAND_A1} (intentionally stopped)

Downstream automation:
- ${env.INFRA_JOB}
- Triggered after successful application deployment and verification.
""",
                        ok: 'Approve Deployment',
                        submitter: 'admin'
                    )
                }
            }
        }

        // --------------------------------------------------
        // 7. DEPLOY APPLICATION
        // --------------------------------------------------

        stage('Deploy Application') {
            steps {
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
                    sshagent(credentials: ['demand-app-ssh-key']) {
                        sh '''
                            set -e

                            echo "Starting Capistrano deployment..."
                            echo "Application: ${APP_NAME}"
                            echo "Commit: ${APP_COMMIT}"
                            echo "Target: ${DEMAND_A2}"

                            bundle exec cap staging deploy

                            echo "Capistrano deployment completed."
                        '''
                    }
                }
            }
        }

        // --------------------------------------------------
        // 8. APPLICATION HEALTH CHECK
        // --------------------------------------------------

        stage('Health Check') {
            steps {
                sshagent(credentials: ['demand-app-ssh-key']) {
                    sh '''
                        set -e

                        echo "Checking application on Demand-a2..."

                        ssh \
                            -o BatchMode=yes \
                            -o ConnectTimeout=15 \
                            -o StrictHostKeyChecking=accept-new \
                            ${REMOTE_USER}@${DEMAND_A2} \
                            "set -e
                             echo 'Checking application health...'
                             curl --fail --silent --show-error ${HEALTH_URL}
                             echo
                             echo 'Checking deployed revision...'
                             cd ${APP_PATH}
                             cat REVISION
                            "

                        echo "Health check completed."
                    '''
                }
            }
        }

        // --------------------------------------------------
        // 9. VERIFY DEPLOYED REVISION
        // --------------------------------------------------

        stage('Verify Deployed Revision') {
            steps {
                sshagent(credentials: ['demand-app-ssh-key']) {
                    sh '''
                        set -e

                        echo "Verifying deployed application revision..."

                        DEPLOYED_COMMIT=$(
                            ssh \
                                -o BatchMode=yes \
                                -o ConnectTimeout=15 \
                                -o StrictHostKeyChecking=accept-new \
                                ${REMOTE_USER}@${DEMAND_A2} \
                                "cat ${APP_PATH}/REVISION"
                        )

                        echo "Expected commit: ${APP_COMMIT}"
                        echo "Deployed commit: ${DEPLOYED_COMMIT}"

                        if [ "${DEPLOYED_COMMIT}" != "${APP_COMMIT}" ]; then
                            echo "ERROR: Deployed revision does not match."
                            exit 1
                        fi

                        echo "Revision verification successful."
                    '''
                }
            }
        }

        // --------------------------------------------------
        // 10. TRIGGER DOWNSTREAM INFRASTRUCTURE AUTOMATION
        // --------------------------------------------------

        stage('Infrastructure Automation') {
            steps {
                script {
                    echo "=========================================="
                    echo "Triggering downstream infrastructure job"
                    echo "=========================================="

                    echo "Downstream job: ${env.INFRA_JOB}"
                    echo "Application: ${env.APP_NAME}"
                    echo "Application commit: ${env.APP_COMMIT}"

                    def downstreamBuild = build(
                        job: env.INFRA_JOB,
                        wait: true,
                        propagate: true
                    )

                    echo "=========================================="
                    echo "DOWNSTREAM JOB COMPLETED"
                    echo "=========================================="

                    echo "Job: ${env.INFRA_JOB}"
                    echo "Build number: ${downstreamBuild.number}"
                    echo "Build result: ${downstreamBuild.result}"
                    echo "Build URL: ${downstreamBuild.absoluteUrl}"
                }
            }
        }
    }

    // ------------------------------------------------------
    // POST BUILD ACTIONS
    // ------------------------------------------------------

    post {

        success {
            echo """
            ==========================================
            APPLICATION + INFRASTRUCTURE PIPELINE SUCCESSFUL
            ==========================================
            Application       : ${env.APP_NAME}
            Environment       : ${env.DEPLOY_ENV}
            Branch            : ${env.APP_BRANCH}
            Commit            : ${env.APP_COMMIT}
            Deployment target : ${env.DEMAND_A2}
            Downstream job    : ${env.INFRA_JOB}
            ==========================================
            """
        }

        failure {
            echo """
            ==========================================
            PIPELINE FAILED
            ==========================================
            Application    : ${env.APP_NAME}
            Commit         : ${env.APP_COMMIT}
            Downstream job : ${env.INFRA_JOB}

            Check the failed stage and its console output.
            ==========================================
            """
        }

        aborted {
            echo 'Application and infrastructure pipeline was aborted.'
        }

        always {
            echo 'Cleaning Jenkins workspace...'
            cleanWs()
        }
    }
}
