pipeline {
    agent any

    environment {
        DOTNET_CLI_HOME = "C:\\Program Files\\dotnet"
        REMOTE_SERVER = '10.50.1.130'  // Remote server IP
        REMOTE_APP_PATH = 'C:\\inetpub\\wwwroot' // Deployment path
        ZIP_FILE = "app-${env.BUILD_NUMBER}.zip"
        WINSCP_PATH = "\"C:\\Program Files (x86)\\WinSCP\\WinSCP.com\""
        AWS_REGION = 'ap-south-1'   // Change to your AWS region
        TARGET_GROUP_ARN = 'arn:aws:elasticloadbalancing:ap-south-1:354161983344:targetgroup/loadtestapiTG/8ed96c22513d8d2d'
        INSTANCE_ID = 'i-04fcb84dc30dbf4d9'  // Retrieve dynamically if using Auto Scaling
    }

    stages {
        stage('Checkout') {
            steps {
                checkout scm
            }
        }

        stage('Deregister from Target Group') {
            steps {
                script {
                    echo "🚫 Deregistering instance ${INSTANCE_ID} from Target Group..."
                    def deregisterCmd = """
                        aws elbv2 deregister-targets --target-group-arn ${TARGET_GROUP_ARN} --targets Id=${INSTANCE_ID} --region ${AWS_REGION}
                    """
                    bat deregisterCmd
                    sleep(time: 30)  // Wait for traffic to drain
                }
            }
        }

        stage('Build & Package') {
            steps {
                bat "dotnet restore"
                bat "dotnet build --configuration Release"
                bat "dotnet test --no-restore --configuration Release"
                bat "dotnet publish --no-restore --configuration Release --output .\\publish"
                bat "powershell Compress-Archive -Path publish\\* -DestinationPath ${ZIP_FILE} -Force"
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
                            Expand-Archive -Path 'C:\\inetpub\\wwwroot\\${ZIP_FILE}' -DestinationPath 'C:\\inetpub\\wwwroot' -Force
                            Restart-Service -Name W3SVC -Force
                            Write-Host "✅ Deployment Completed!"
                        }
                        """
                    }
                }
            }
        }

        stage('Register Back to Target Group') {
            steps {
                script {
                    echo "🔄 Registering instance ${INSTANCE_ID} back to Target Group..."
                    def registerCmd = """
                        aws elbv2 register-targets --target-group-arn ${TARGET_GROUP_ARN} --targets Id=${INSTANCE_ID} --region ${AWS_REGION}
                    """
                    bat registerCmd

                    echo "⏳ Waiting for instance to become healthy..."
                    def waitForHealthyCmd = """
                        aws elbv2 wait target-in-service --target-group-arn ${TARGET_GROUP_ARN} --targets Id=${INSTANCE_ID} --region ${AWS_REGION}
                    """
                    bat waitForHealthyCmd
                    echo "✅ Instance is healthy!"
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
