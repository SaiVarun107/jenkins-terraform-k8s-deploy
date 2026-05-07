pipeline {
    agent any

    environment {
        DOCKER_IMAGE = "glacierknight/myapp"
    }

    stages {

        stage('Clone') {
            steps {
                git 'https://github.com/SaiVarun107/jenkins-terraform-k8s-deploy.git'
            }
        }

        stage('Build') {
            steps {
                dir('app') {
                    sh 'docker build -t $DOCKER_IMAGE:latest .'
                }
            }
        }

        stage('Push') {
            steps {
                withCredentials([usernamePassword(
                    credentialsId: 'docker-creds',
                    usernameVariable: 'USER',
                    passwordVariable: 'PASS'
                )]) {
                    sh '''
                    echo $PASS | docker login -u $USER --password-stdin
                    docker push $DOCKER_IMAGE:latest
                    '''
                }
            }
        }

        stage('Terraform') {
            steps {
                dir('terraform') {
                    sh '''
                    terraform init
                    terraform apply -auto-approve
                    '''
                }
            }
        }

        stage('Get IP') {
            steps {
                dir('terraform') {
                    script {
                        env.EC2_IP = sh(
                            script: "terraform output -raw ec2_ip",
                            returnStdout: true
                        ).trim()
                    }
                }
            }
        }

        stage('Deploy') {
            steps {
                withCredentials([sshUserPrivateKey(
                    credentialsId: 'ec2-key',
                    keyFileVariable: 'KEY'
                )]) {
                    sh '''
                    sleep 60

                    ssh -o StrictHostKeyChecking=no -i $KEY ubuntu@$EC2_IP << EOF

                    docker pull $DOCKER_IMAGE:latest

                    kubectl apply -f ~/k8s/deployment.yaml || true
                    kubectl apply -f ~/k8s/service.yaml || true

                    kubectl rollout restart deployment myapp
                    kubectl rollout status deployment myapp

                    EOF
                    '''
                }
            }
        }
    }
}