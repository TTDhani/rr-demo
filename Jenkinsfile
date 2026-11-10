pipeline {
    agent any

    options {
        timestamps()
        disableConcurrentBuilds()
        timeout(time: 30, unit: 'MINUTES')
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
                    echo "Checking Ruby and Bundler versions..."
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
                    bundle config set --local path vendor/bundle
                    bundle install
                '''
            }
        }

        stage('Run Tests') {
            steps {
                sh '''
                    set -eu
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
                        string(credentialsId: 'rr-demo-db-port', variable: 'DB_PORT')
			string(credentialsId: 'rr-demo-db-queue-name', variable: 'DB_QUEUE_NAME'),
			string(credentialsId: 'rr-demo-db-cache-name', variable: 'DB_CACHE_NAME'),
			string(credentialsId: 'rr-demo-db-cable-name', variable: 'DB_CABLE_NAME')
                    ]) {
                        sh '''
                            set -eu
                            bundle exec cap staging deploy:check
                        '''
                    }
                }
            }
        }

        stage('Approve Deployment') {
            steps {
                input message: 'Deploy this revision to both Demand app servers?',
                      ok: 'Deploy'
            }
        }

        stage('Deploy') {
            steps {
                sshagent(credentials: ['demand-app-ssh-key']) {
                    withCredentials([
                        string(credentialsId: 'rr-demo-secret-key-base', variable: 'SECRET_KEY_BASE'),
                        string(credentialsId: 'rr-demo-db-host', variable: 'DB_HOST'),
                        string(credentialsId: 'rr-demo-db-name', variable: 'DB_NAME'),
                        string(credentialsId: 'rr-demo-db-username', variable: 'DB_USERNAME'),
                        string(credentialsId: 'rr-demo-db-password', variable: 'DB_PASSWORD'),
                        string(credentialsId: 'rr-demo-db-port', variable: 'DB_PORT')
			string(credentialsId: 'rr-demo-db-queue-name', variable: 'DB_QUEUE_NAME'),
			string(credentialsId: 'rr-demo-db-cache-name', variable: 'DB_CACHE_NAME'),
			string(credentialsId: 'rr-demo-db-cable-name', variable: 'DB_CABLE_NAME')
                    ]) {
                        sh '''
                            set -eu
                            bundle exec cap staging deploy
                        '''
                    }
                }
            }
        }
    }

    post {
        success {
            echo 'Pipeline completed successfully.'
        }

        failure {
            echo 'Pipeline failed. Check the failed stage and console output.'
        }

        always {
            echo 'Cleaning Jenkins workspace...'
            cleanWs(
                deleteDirs: true,
                disableDeferredWipeout: true,
                notFailBuild: true
            )
            echo 'Workspace cleanup completed.'
            echo 'Pipeline execution finished.'
        }
    }
}
