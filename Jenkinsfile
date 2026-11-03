
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
                sh 'bundle exec rails test'
            }
        }

        stage('Capistrano Preflight') {
            steps {
                sshagent(credentials: ['demand-app-ssh-key']) {
                    sh 'bundle exec cap staging deploy:check'
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
                    sh 'bundle exec cap staging deploy'
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
            echo 'Pipeline execution finished.'
        }
    }
}
