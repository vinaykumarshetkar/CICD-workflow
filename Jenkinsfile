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
                stage('Provision Infrastructure') {
            steps {
                echo 'Provisioning Azure Infrastructure...'

                dir("${TERRAFORM_DIR}") {
                    sh '''
                        set -e
                        terraform init
                        terraform apply -auto-approve 
                    '''
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
