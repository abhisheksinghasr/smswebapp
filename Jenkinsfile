pipeline {
    agent any

    environment {
        DOTNET_CLI_HOME = "C:\\Program Files\\dotnet"
        REMOTE_SERVER = '13.235.65.246' // Application server IP
        REMOTE_APP_PATH = 'C:\\inetpub\\wwwroot\\MyApp' // Deployment path
        ZIP_FILE = "app-${env.BUILD_NUMBER}.zip"
        WINSCP_PATH = "C:\\Program Files (x86)\\WinSCP\\WinSCP.com"
        DEPLOY_SCRIPT = "C:/Deploy/deploy.ps1"
        HOST_KEY_FINGERPRINT = "ssh-ed25519 256 eMn9LBmr1totw0d9aWCdS9xzhFYhxoWNN2erk/TgeJM"
    }

    stages {

        stage('Checkout') {
            steps {
                echo "Checking out source code..."
                checkout scm
            }
        }

        stage('Build') {
            steps {
                echo "Building application..."
                bat "dotnet restore"
                bat "dotnet build --configuration Release"
            }
        }

        stage('Test') {
            steps {
                echo "Running tests..."
                bat "dotnet test --no-restore --configuration Release"
            }
        }

        stage('Publish') {
            steps {
                echo "Publishing application..."
                bat "dotnet publish --no-restore --configuration Release --output .\\publish"
            }
        }

        stage('Package') {
            steps {
                echo "Creating deployment package..."
                bat "powershell Compress-Archive -Path publish\\* -DestinationPath ${ZIP_FILE} -Force"
            }
        }

        stage('Transfer to Server') {
            steps {
                withCredentials([usernamePassword(credentialsId: 'WINSCP_CRED', usernameVariable: 'USERNAME', passwordVariable: 'PASSWORD')]) {
                    echo "Transferring package to remote server using WinSCP..."
                    powershell '''
                    $hostKey = "$env:HOST_KEY_FINGERPRINT"
                    & "$env:WINSCP_PATH" /command `
                    "open sftp://$env:USERNAME:$env:PASSWORD@$env:REMOTE_SERVER/ -hostkey=""$hostKey""" `
                    "put ""$env:ZIP_FILE"" ""C:/Deploy/app-latest.zip""" `
                    "exit"
                    '''
                }
            }
        }

        stage('Deploy on Server') {
            steps {
                withCredentials([usernamePassword(credentialsId: 'SSH_CRED', usernameVariable: 'SSH_USER', passwordVariable: 'SSH_PASS')]) {
                    echo "Executing remote deployment script..."
                    powershell '''
                    sshpass -p "$env:SSH_PASS" ssh "$env:SSH_USER@$env:REMOTE_SERVER" powershell -Command "& '$env:DEPLOY_SCRIPT'"
                    '''
                }
            }
        }
    }

    post {
        success {
            echo 'Deployment successful!'
        }
        failure {
            echo 'Deployment failed!'
        }
    }
}
