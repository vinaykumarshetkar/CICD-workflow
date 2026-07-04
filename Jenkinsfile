pipeline {
    agent any

    environment {
        PROJECT_DIR   = "/home/azureuser/task/CICD_Ansible_Terraform_Azure"
        TERRAFORM_DIR = "/home/azureuser/task/CICD_Ansible_Terraform_Azure/terraform"
        ANSIBLE_DIR   = "/home/azureuser/task/CICD_Ansible_Terraform_Azure/ansible/playbooks"
        BACKUP_DIR    = "/opt/task_backup"
        ANSIBLE_HOST_KEY_CHECKING = 'False'
        JAVA_HOME = "/usr/lib/jvm/java-8-openjdk-amd64"
        PATH = "${JAVA_HOME}/bin:${env.PATH}"
        AZ_SUBSCRIPTION_ID = '8c841f79-6c82-4290-9d85-3c74f5513d78'
        AZ_TENANT_ID       = 'a76789c5-125b-4cbc-8b50-d6bd349423d3'
    }

    stages {

        stage('Clone Repository') {
            steps {
                git branch: 'candidate/vinay',
                    url: 'https://github.com/vinaykumarshetkar/CICD-workflow.git'
            }
        }

        stage('Build') {
            steps {
                dir("${PROJECT_DIR}") {
                    sh '''
                        set -e
                        mvn clean install
                    '''
                }
            }
        }

        stage('Test') {
            steps {
                dir("${PROJECT_DIR}") {
                    sh '''
                        set -e
                        mvn test
                    '''
                }
            }
        }

        stage('Archive Artifact') {
            steps {
                sh """
                    cp ${PROJECT_DIR}/target/devops-demo-0.3.0.jar ${BACKUP_DIR}/
                    cd ${BACKUP_DIR}
                    bash backup.sh
                """
            }
        }
        stage('Azure Login') {
            steps {
                withCredentials([
                    usernamePassword(
                        credentialsId: 'azure-sp',
                        usernameVariable: 'AZ_CLIENT_ID',
                        passwordVariable: 'AZ_CLIENT_SECRET'
                    )
                ]) {
                    sh '''
                        az login --service-principal \
                          -u "$AZ_CLIENT_ID" \
                          -p "$AZ_CLIENT_SECRET" \
                          --tenant "$AZ_TENANT_ID"

                        az account set --subscription "$AZ_SUBSCRIPTION_ID"
                    '''
                }
            }
        }

        stage('Provision Infrastructure') {
            steps {
                dir("${TERRAFORM_DIR}") {
                    withCredentials([
                        usernamePassword(
                            credentialsId: 'azure-sp',
                            usernameVariable: 'ARM_CLIENT_ID',
                            passwordVariable: 'ARM_CLIENT_SECRET'
                        )
                    ]) {
                        sh '''
                            export ARM_CLIENT_ID=$ARM_CLIENT_ID
                            export ARM_CLIENT_SECRET=$ARM_CLIENT_SECRET
                            export ARM_TENANT_ID=$AZ_TENANT_ID
                            export ARM_SUBSCRIPTION_ID=$AZ_SUBSCRIPTION_ID

                            terraform init
                            terraform apply -auto-approve
                        '''
                    }
                }
            }
        }

        stage('Deploy Application') {
            steps {
                dir("${ANSIBLE_DIR}") {
                    sshagent(credentials: ['newKey']) {
                    sh '''
                        ansible-playbook -i inventory.ini deploy.yml
                    '''
                }
            }
        }
        }

        stage('Health Check') {
            steps {
                dir("${ANSIBLE_DIR}") {
                    sshagent(credentials: ['newKey']) {
                    sh '''
                        ansible-playbook -i inventory.ini health_check.yml
                    '''
                }
            }
        }
    }
    }

    post {

        success {
            echo "Pipeline executed successfully."
        }

        failure {
            echo "Pipeline failed. Check the console logs."
        }

        always {
            cleanWs()
        }
    }
}
