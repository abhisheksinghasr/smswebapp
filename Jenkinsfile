pipeline {
    agent any

    environment {
        DOTNET_CLI_HOME = "C:\\Program Files\\dotnet"
        WINSCP_PATH = "\"C:\\Program Files (x86)\\WinSCP\\WinSCP.com\""
        AWS_REGION = 'ap-south-1'
        TARGET_GROUP_ARN = 'arn:aws:elasticloadbalancing:ap-south-1:354161983344:targetgroup/loadtestapiTG/8ed96c22513d8d2d'
        ZIP_FILE = "app-${env.BUILD_NUMBER}.zip"
    }

    stages {
        stage('Checkout') {
            steps {
                checkout scm
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

        stage('Deploy to Servers Sequentially') {
            steps {
                script {
                    def servers = [
                        [ip: '10.50.1.130', instanceId: 'i-04fcb84dc30dbf4d9'],
                        [ip: '10.50.1.34', instanceId: 'i-0e36bd3304b1008db']
                    ]

                    for (server in servers) {
                        def remoteServer = server.ip
                        def instanceId = server.instanceId

                        stage("Deregister ${remoteServer} from TG") {
                            echo "🚫 Deregistering instance ${instanceId} from Target Group..."
                            bat "aws elbv2 deregister-targets --target-group-arn ${TARGET_GROUP_ARN} --targets Id=${instanceId} --region ${AWS_REGION}"
                            sleep(time: 30)  // Allow time for traffic to drains
                        }

                        stage("Transfer to ${remoteServer}") {
                            withCredentials([usernamePassword(credentialsId: 'WINSCP_CRED', usernameVariable: 'USERNAME', passwordVariable: 'PASSWORD')]) {
                                echo "🚀 Transferring package to ${remoteServer} using WinSCP..."
                                bat """
                                    ${WINSCP_PATH} /command ^
                                    "open sftp://%USERNAME%:%PASSWORD%@${remoteServer}/ -hostkey=*" ^
                                    "put ${ZIP_FILE} C:/inetpub/wwwroot/${ZIP_FILE}" ^
                                    "exit"
                                """
                            }
                        }

                        stage("Deploy on ${remoteServer}") {
                            withCredentials([usernamePassword(credentialsId: 'WINSCP_CRED', usernameVariable: 'REMOTE_USER', passwordVariable: 'REMOTE_PASSWORD')]) {
                                script {
                                    powershell """
                                    \$securePassword = ConvertTo-SecureString '${REMOTE_PASSWORD}' -AsPlainText -Force
                                    \$cred = New-Object System.Management.Automation.PSCredential ('${REMOTE_USER}', \$securePassword)

                                    Invoke-Command -ComputerName '${remoteServer}' -Credential \$cred -ScriptBlock {
                                        Expand-Archive -Path 'C:\\inetpub\\wwwroot\\${ZIP_FILE}' -DestinationPath 'C:\\inetpub\\wwwroot' -Force
                                        Restart-Service -Name W3SVC -Force
                                        Write-Host "✅ Deployment Completed on ${remoteServer}!"
                                    }
                                    """
                                }
                            }
                        }

                        stage("Register ${remoteServer} Back to TG") {
                            echo "🔄 Registering instance ${instanceId} back to Target Group..."
                            bat "aws elbv2 register-targets --target-group-arn ${TARGET_GROUP_ARN} --targets Id=${instanceId} --region ${AWS_REGION}"

                            echo "⏳ Waiting for instance ${instanceId} to become healthy..."
                            bat "aws elbv2 wait target-in-service --target-group-arn ${TARGET_GROUP_ARN} --targets Id=${instanceId} --region ${AWS_REGION}"
                            echo "✅ Instance ${instanceId} is healthy!"
                        }
                    }
                }
            }
        }
    }

    post {
        success {
            echo '✅ Deployment to all servers successful!!'
        }
        failure {
            echo '❌ Deployment failed!'
        }
    }
}
