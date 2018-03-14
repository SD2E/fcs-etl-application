#!groovy​

pipeline {
    agent any
    environment {
        AGAVE_DATA_URI  = "agave://data-sd2e-community/sample/fcs-tasbe/fcs-etl-reactor-example"
        CONTAINER_REPO  = "fcs-etl"
        CONTAINER_TAG   = "test"
        AGAVE_CACHE_DIR = "${HOME}/credentials_cache/${JOB_BASE_NAME}"
        AGAVE_TENANTID  = 'sd2e'
        AGAVE_APISERVER = 'https://api.sd2e.org'
        AGAVE_USERNAME    = credentials('sd2etest-tacc-username')
        AGAVE_PASSWORD    = credentials('sd2etest-tacc-password')
        REGISTRY_USERNAME = credentials('sd2etest-dockerhub-username')
        REGISTRY_PASSWORD = credentials('sd2etest-dockerhub-password')
        REGISTRY_ORG      = credentials('sd2etest-dockerhub-org')
        REGISTRY_ORGANIZATION = credentials('sd2etest-tacc-password')
        PATH = "${WORKSPACE}/bin:${WORKSPACE}/sd2e-cloud-cli/bin:${env.PATH}"
        }
    stages {

        stage('Install latest Agave CI Support') { 
            steps {
                git credentialsId: 'c959426e-e0cc-4d0f-aca2-3bd586e56b56', url: 'git@gitlab.sd2e.org:sd2program/agave-ci-support.git'
                sh "make install"
            }
        }
        stage('Create an ephemeral session and Oauth client') { 
            steps {
                sh "make-session-client ${JOB_BASE_NAME} ${JOB_BASE_NAME}-${BUILD_ID}"
            }
        }
        stage('Copy in test data') {
            steps {
                sh "files-get -q -r -S data-sd2e-community /sample/fcs-tasbe/fcs-etl-reactor-example"
            }
        }
        stage('Build app container') { 
            steps {
                sh "apps-build-container -O ${REGISTRY_USERNAME} --image ${CONTAINER_REPO} --tag ${CONTAINER_TAG}"
            }
        }
        stage('Run local functional test') { 
            steps {
                sh "tests/run_functional_test.sh ${REGISTRY_USERNAME}/${CONTAINER_REPO}:${CONTAINER_TAG}"
            }
        }
        stage('Delete the Oauth client and associated session') { 
            steps {
               sh "delete-session-client ${JOB_BASE_NAME} ${JOB_BASE_NAME}-${BUILD_ID}"
            }
        }
    }
    post {
        always {
            slackSend color: 'green', message: 'Build Complete - ${env.JOB_NAME} ${env.BUILD_NUMBER} (<${env.BUILD_URL}|Open>)'

        }
        failure {
            slackSend color: 'red', message: 'Failed - ${env.JOB_NAME} ${env.BUILD_NUMBER} (<${env.BUILD_URL}|Open>)'

        }
    }
}