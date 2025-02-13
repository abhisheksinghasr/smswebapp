pipeline {
    agent any

    environment {
        DOTNET_CLI_HOME = "C:\\Program Files\\dotnet"
        WINSCP_PATH = "\"C:\\Program Files (x86)\\WinSCP\\WinSCP.com\""
        REMOTE_APP_PATH = "C:\\inetpub\\wwwroot"
        ZIP_FILE = "app-${env.BUILD_NUMBER}.zip"
        TARGET_GROUP_ARN = "arn:aws:elasticloadbalancing:ap-south-1:381492095921:targetgroup/cicd-jenkins/d742fdbd78cf30bb"
    }

    parameters {
        string(name: 'SERVERS', defaultValue: '3.7.54.74,13.127.150.22,13.201.2.42,3.110.132.242', description: 'Comma-separated list of servers')
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

        stage('Deploy to Servers') {
            steps {
                script {
                    def servers = params.SERVERS.tokenize(',')

                    for (server in servers) {
                        echo "🚀 Starting deployment on ${server}"

                        // Step 1: Deregister the instance from TG
                        withAWS(credentials: 'AWS_CREDENTIALS_ID', region: 'your-region') {
                            sh """
                                aws elbv2 deregister-targets --target-group-arn ${TARGET_GROUP_ARN} --targets Id=${server}
                            """
                        }
                        sleep(time: 30, unit: 'SECONDS')

                        // Step 2: Deploy code
                        withCredentials([usernamePassword(credentialsId: 'WINSCP_CRED', usernameVariable: 'USERNAME', passwordVariable: 'PASSWORD')]) {
                            bat """
                                ${WINSCP_PATH} /command ^
                                "open sftp://%USERNAME%:%PASSWORD%@${server}/ -hostkey=*" ^
                                "put ${ZIP_FILE} C:/Deploy/${ZIP_FILE}" ^
                                "exit"
                            """
                        }

                        withCredentials([usernamePassword(credentialsId: 'WINSCP_CRED', usernameVariable: 'REMOTE_USER', passwordVariable: 'REMOTE_PASSWORD')]) {
                            powershell """
                                \$securePassword = ConvertTo-SecureString '${REMOTE_PASSWORD}' -AsPlainText -Force
                                \$cred = New-Object System.Management.Automation.PSCredential ('${REMOTE_USER}', \$securePassword)

                                Invoke-Command -ComputerName '${server}' -Credential \$cred -ScriptBlock {
                                    Stop-Service W3SVC -Force
                                    Expand-Archive -Path 'C:\\Deploy\\${ZIP_FILE}' -DestinationPath '${REMOTE_APP_PATH}' -Force
                                    Start-Service W3SVC
                                }
                            """
                        }

                        // Step 3: Register instance back to TG
                        withAWS(credentials: 'AWS_CREDENTIALS_ID', region: 'your-region') {
                            sh """
                                aws elbv2 register-targets --target-group-arn ${TARGET_GROUP_ARN} --targets Id=${server}
                            """
                        }

                        // Step 4: Wait until instance is healthy
                        timeout(time: 300, unit: 'SECONDS') {
                            waitUntil {
                                def healthCheck = sh(script: """
                                    aws elbv2 describe-target-health --target-group-arn ${TARGET_GROUP_ARN} --targets Id=${server} --query 'TargetHealthDescriptions[*].TargetHealth.State' --output text
                                """, returnStdout: true).trim()
                                return healthCheck == "healthy"
                            }
                        }

                        echo "✅ Deployment on ${server} completed!"
                    }
                }
            }
        }
    }

    post {
        success {
            echo '✅ Deployment successful on all servers!'
        }
        failure {
            echo '❌ Deployment failed!'
        }
    }
}

