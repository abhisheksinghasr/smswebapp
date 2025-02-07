pipeline {
    agent any

    environment {
        DOTNET_CLI_HOME = "C:\\Program Files\\dotnet"
        REMOTE_SERVER = '13.235.65.246' // Application server IP
        REMOTE_APP_PATH = 'C:\\inetpub\\wwwroot\\MyApp' // Deployment path on server
        ZIP_FILE = "app-${env.BUILD_NUMBER}.zip"
        WINSCP_PATH = "C:\\Program Files (x86)\\WinSCP\\WinSCP.com"
        HOST_KEY_FINGERPRINT = "ssh-ed25519 255 SHA256:eMn9LBmr1totw0d9aWCdS9xzhFYhxoWNN2erk/TgeJM" // Updated fingerprints
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
                    & "$env:WINSCP_PATH" /command `
                    "open sftp://$env:USERNAME:$env:PASSWORD@$env:REMOTE_SERVER/ -hostkey=\"$env:HOST_KEY_FINGERPRINT\"" `
                    "put $env:ZIP_FILE /C:/Deploy/$env:ZIP_FILE" `
                    "exit"
                    '''
                }
            }
        }

        stage('Deploy on Server') {
            steps {
                withCredentials([usernamePassword(credentialsId: 'WINSCP_CRED', usernameVariable: 'USERNAME', passwordVariable: 'PASSWORD')]) {
                    echo "Deploying application using PowerShell Remoting..."
                    powershell '''
                    $session = New-PSSession -ComputerName $env:REMOTE_SERVER -Credential (New-Object System.Management.Automation.PSCredential ($env:USERNAME, (ConvertTo-SecureString $env:PASSWORD -AsPlainText -Force)))
                    Invoke-Command -Session $session -ScriptBlock {
                        Expand-Archive -Path "C:\\Deploy\\$env:ZIP_FILE" -DestinationPath "$env:REMOTE_APP_PATH" -Force
                        Restart-Service -Name MyDotNetAppService
                    }
                    Remove-PSSession $session
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
