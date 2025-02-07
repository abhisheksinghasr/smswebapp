pipeline {
    agent any

    environment {
        DOTNET_CLI_HOME = "C:\\Program Files\\dotnet"
        REMOTE_SERVER = '13.235.65.246'  // Updated server IP
        REMOTE_APP_PATH = 'C:\\inetpub\\wwwroot\\MyApp' // Deployment path on the server
        ZIP_FILE = "app-${env.BUILD_NUMBER}.zip"
        WINSCP_PATH = "C:\\Program Files (x86)\\WinSCP\\WinSCP.com"
        HOST_KEY_FINGERPRINT = "ssh-ed25519 255 eMn9LBmr1totw0d9aWCdS9xzhFYhxoWNN2erk/TgeJM" // Correct host key
    }

    stages {
        stage('Checkout') {
            steps {
                checkout scm
            }
        }

        stage('Build') {
            steps {
                bat "dotnet restore"
                bat "dotnet build --configuration Release"
            }
        }

        stage('Test') {
            steps {
                bat "dotnet test --no-restore --configuration Release"
            }
        }

        stage('Publish') {
            steps {
                bat "dotnet publish --no-restore --configuration Release --output .\\publish"
            }
        }

        stage('Package') {
            steps {
                echo "Creating ZIP package..."
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
                    "open sftp://$env:USERNAME:$env:PASSWORD@$env:REMOTE_SERVER/ " `  # Correct host key format
                    "put ""$env:ZIP_FILE"" ""/C:/Deploy/$env:ZIP_FILE""" `  # Fixed path format
                    "exit"
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

