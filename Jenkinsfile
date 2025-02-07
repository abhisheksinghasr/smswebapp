pipeline {
    agent any

    environment {
        DOTNET_CLI_HOME = "C:\\Program Files\\dotnet"
        REMOTE_SERVER = '65.1.73.66' // Replace with your application server IP
        REMOTE_USER = 'Administrator' // Use an appropriate user with SSH/WinRM access
        REMOTE_PASSWORD = 'Test12.com&&' // Securely manage credentials
        REMOTE_APP_PATH = 'C:\\inetpub\\wwwroot\\MyApp' // Path on remote server
        ZIP_FILE = "app-${env.BUILD_NUMBER}.zip"
    }

    stages {
        stage('Checkout') {
            steps {
                checkout scm
            }
        }

        stage('Build') {
            steps {
                script {
                    bat "dotnet restore"
                    bat "dotnet build --configuration Release"
                }
            }
        }

        stage('Test') {
            steps {
                script {
                    bat "dotnet test --no-restore --configuration Release"
                }
            }
        }

        stage('Publish') {
            steps {
                script {
                    bat "dotnet publish --no-restore --configuration Release --output .\\publish"
                }
            }
        }

        stage('Package') {
            steps {
                script {
                    echo "Creating ZIP package..."
                    bat "powershell Compress-Archive -Path publish\\* -DestinationPath ${ZIP_FILE} -Force"
                }
            }
        }

        stage('Transfer to Server') {
            steps {
                script {
                    echo "Transferring package to remote server..."
                    bat """
                    scp -pw "${REMOTE_PASSWORD}" "${ZIP_FILE}" "${REMOTE_USER}@${REMOTE_SERVER}:C:\\Deploy\\${ZIP_FILE}"
                    """
                }
            }
        }

        stage('Deploy on Server') {
            steps {
                script {
                    echo "Deploying on remote server..."
                    bat """
                    plink -pw ${REMOTE_PASSWORD} ${REMOTE_USER}@${REMOTE_SERVER} ^
                    powershell -Command "Expand-Archive -Path C:\\Deploy\\${ZIP_FILE} -DestinationPath ${REMOTE_APP_PATH} -Force"
                    """
                    
                    echo "Restarting application..."
                    bat """
                    plink -pw ${REMOTE_PASSWORD} ${REMOTE_USER}@${REMOTE_SERVER} ^
                    powershell -Command "Restart-Service -Name MyDotNetAppService"
                    """
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
