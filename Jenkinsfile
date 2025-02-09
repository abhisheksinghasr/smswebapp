pipeline {
    agent any

    environment {
        DOTNET_CLI_HOME = "C:\\Program Files\\dotnet"
        REMOTE_SERVER = '13.203.29.59'  // Remote application server IP
        REMOTE_APP_PATH = 'C:\\inetpub\\wwwroot\\MyApp' // Deployment path on the server
        ZIP_FILE = "app-${env.BUILD_NUMBER}.zip"
        WINSCP_PATH = "\"C:\\Program Files (x86)\\WinSCP\\WinSCP.com\""
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
                echo "📦 Creating ZIP package..."
                bat "powershell Compress-Archive -Path publish\\* -DestinationPath ${ZIP_FILE} -Force"
            }
        }

        stage('Create Deploy Folder on Server') {
            steps {
                withCredentials([usernamePassword(credentialsId: 'WINSCP_CRED', usernameVariable: 'REMOTE_USER', passwordVariable: 'REMOTE_PASSWORD')]) {
                    script {
                        powershell """
                        \$securePassword = ConvertTo-SecureString '${REMOTE_PASSWORD}' -AsPlainText -Force
                        \$cred = New-Object System.Management.Automation.PSCredential ('${REMOTE_USER}', \$securePassword)

                        Invoke-Command -ComputerName '${REMOTE_SERVER}' -Credential \$cred -ScriptBlock {
                            if (!(Test-Path 'C:\\Deploy')) {
                                New-Item -Path 'C:\\Deploy' -ItemType Directory -Force
                            }
                        }
                        """
                    }
                }
            }
        }

        stage('Transfer to Server') {
            steps {
                withCredentials([usernamePassword(credentialsId: 'WINSCP_CRED', usernameVariable: 'USERNAME', passwordVariable: 'PASSWORD')]) {
                    echo "🚀 Transferring package to remote server using WinSCP..."
                    bat """
                        ${WINSCP_PATH} /command ^
                        "open sftp://%USERNAME%:%PASSWORD%@${REMOTE_SERVER}/ -hostkey=*" ^
                        "mkdir /Deploy" ^
                        "put ${ZIP_FILE} /Deploy/${ZIP_FILE}" ^
                        "exit"
                    """
                }
            }
        }

        stage('Deploy on Server') {
            steps {
                withCredentials([usernamePassword(credentialsId: 'WINSCP_CRED', usernameVariable: 'REMOTE_USER', passwordVariable: 'REMOTE_PASSWORD')]) {
                    script {
                        powershell """
                        \$securePassword = ConvertTo-SecureString '${REMOTE_PASSWORD}' -AsPlainText -Force
                        \$cred = New-Object System.Management.Automation.PSCredential ('${REMOTE_USER}', \$securePassword)

                        Invoke-Command -ComputerName '${REMOTE_SERVER}' -Credential \$cred -ScriptBlock {
                            Expand-Archive -Path 'C:\\Deploy\\${ZIP_FILE}' -DestinationPath '${REMOTE_APP_PATH}' -Force
                            Start-Process -FilePath '${REMOTE_APP_PATH}\\MyApp.exe'
                        }
                        """
                    }
                }
            }
        }
    }

    post {
        success {
            echo '✅ Deployment successful!!'
        }
        failure {
            echo '❌ Deployment failed!'
        }
    }
}
