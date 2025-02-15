pipeline {
    agent any

    environment {
        DOTNET_CLI_HOME = "C:\\Program Files\\dotnet"
        REMOTE_SERVER = '15.206.91.119'  // Remote server IP
        REMOTE_APP_PATH = 'C:\\inetpub\\wwwroot' // Deployment path
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
                            if (!(Test-Path 'C:\\inetpub\\wwwroot')) {
                                New-Item -Path 'C:\\inetpub\\wwwroot' -ItemType Directory -Force
                                Write-Host "✅ Folder Created: C:\\inetpub\\wwwroot"
                            } else {
                                Write-Host "✅ Folder Already Exists: C:\\inetpub\\wwwroot"
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
                        "put ${ZIP_FILE} C:/inetpub/wwwroot/${ZIP_FILE}" ^
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
                            Write-Host "✅ Checking if C:\\inetpub\\wwwroot exists..."
                            if (!(Test-Path 'C:\\inetpub\\wwwroot')) {
                                New-Item -Path 'C:\\inetpub\\wwwroot' -ItemType Directory -Force
                                Write-Host "✅ Created Folder: C:\\inetpub\\wwwroot"
                            }

                            Expand-Archive -Path 'C:\\inetpub\\wwwroot\\${ZIP_FILE}' -DestinationPath 'C:\\inetpub\\wwwroot' -Force
                            Write-Host "✅ Extraction Completed!"

                            # Restart IIS
                            Restart-Service -Name W3SVC -Force
                            Write-Host "🔄 IIS Restarted!"
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
