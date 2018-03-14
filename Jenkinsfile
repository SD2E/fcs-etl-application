#!groovy

pipeline {
    agent any
    environment {
        AGAVE_DATA_URI    = "agave://data-sd2e-community/sample/fcs-tasbe/fcs-etl-reactor-example"
        CONTAINER_REPO    = "fcs-etl"
        CONTAINER_TAG     = "test"
        AGAVE_CACHE_DIR   = "${HOME}/credentials_cache/${JOB_BASE_NAME}"
        AGAVE_TENANTID    = "sd2e"
        AGAVE_APISERVER   = "https://api.sd2e.org"
        AGAVE_USERNAME    = credentials('sd2etest-tacc-username')
        AGAVE_PASSWORD    = credentials('sd2etest-tacc-password')
        REGISTRY_USERNAME = credentials('sd2etest-dockerhub-username')
        REGISTRY_PASSWORD = credentials('sd2etest-dockerhub-password')
        REGISTRY_ORG      = credentials('sd2etest-dockerhub-org')
        PATH = "${HOME}/bin:${HOME}/sd2e-cloud-cli/bin:${env.PATH}"
        }
    stages {

        stage('Create an ephemeral session and Oauth client') { 
            steps {
                sh "make-session-client ${JOB_BASE_NAME} ${JOB_BASE_NAME}-${BUILD_ID}"
            }
        }
        stage('Copy in test data') {
            steps {
                sh "ls -alth"
                sh "files-get -r -S data-sd2e-community /sample/fcs-tasbe/fcs-etl-reactor-example > files-get.log 2>&1"
                sh "ls -alth"
            }
        }
        stage('Build app container') { 
            steps {
                sh "apps-build-container -O ${REGISTRY_USERNAME} --image ${CONTAINER_REPO} --tag ${CONTAINER_TAG}"
            }
        }
        stage('Run functional test(s)') { 
            steps {
                sh "tests/run_functional_test.sh ${REGISTRY_USERNAME}/${CONTAINER_REPO}:${CONTAINER_TAG}"
            }
        }
    }
    post {
        always {
            sh "delete-session-client ${JOB_BASE_NAME} ${JOB_BASE_NAME}-${BUILD_ID}"
        }
        failure {
            slackSend color: 'red', message: 'Failed - ${env.JOB_NAME} ${env.BUILD_NUMBER} (<${env.BUILD_URL}|Open>)'

        }
    }
}