#!groovy

pipeline {
    agent any
    environment {
        AGAVE_DATA_URI    = "agave://data-sd2e-community/sample/fcs-etl-application/test_data"
        CONTAINER_REPO    = "fcs-etl"
        CONTAINER_TAG     = "test"
        AGAVE_CACHE_DIR   = "${HOME}/credentials_cache/${JOB_BASE_NAME}"
        AGAVE_JSON_PARSER = "jq"
        AGAVE_TENANTID    = "sd2e"
        AGAVE_APISERVER   = "https://api.sd2e.org"
        AGAVE_USERNAME    = "sd2etest"
        AGAVE_PASSWORD    = credentials('sd2etest-tacc-password')
        REGISTRY_USERNAME = "sd2etest"
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
        stage('Conditionally, copy in test data') {
            when { not {
                    expression { fileExists('test_data') }
                   }
            }
            steps {
                sh "ls -alth"
                sh "files-get -r -S data-sd2e-community /sample/fcs-etl-application/test_data > files-get.log 2>&1"
                sh "ls -alth"
            }
        }
        stage('Build app container') { 
            steps {
                sh "apps-build-container -V -O ${REGISTRY_USERNAME} --image ${CONTAINER_REPO} --tag ${CONTAINER_TAG}"
            }
        }
        stage('Run functional test(s)') { 
            steps {
                sh "tests/run_functional_test.sh ${REGISTRY_USERNAME}/${CONTAINER_REPO}:${CONTAINER_TAG} test_data || true"
            }
        }
        stage('Deploy app to TACC.cloud') { 
            steps {
                sh "apps-deploy -V -T -O ${REGISTRY_USERNAME} --image ${CONTAINER_REPO} --tag ${CONTAINER_TAG} fcs-etl-0.3.3 || true"
                sh "ls -alth"
                sh "cat deploy-*"
            }
        }
        stage('Run a test job against deployed app') { 
            steps {
                sh "tests/run_agave_job_test.sh deploy-${AGAVE_USERNAME}-job.json || true"
                sh "cat deploy-*"
            }
        }
    }
    post {
        always {
           sh "delete-session-client ${JOB_BASE_NAME} ${JOB_BASE_NAME}-${BUILD_ID}"
        }
    }
}