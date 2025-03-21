pipeline {
    agent any

    environment {
        SERVERS = "10.50.1.130,10.50.1.34"
        SCRIPT_PATH = "C:/Users/Administrator/Desktop/deploy.ps1"
    }

    stages {
        stage('Test Remote Execution on Both Servers') {
            steps {
                withCredentials([usernamePassword(credentialsId: 'WINSCP_CRED', usernameVariable: 'REMOTE_USER', passwordVariable: 'REMOTE_PASSWORD')]) {
                    script {
                        def serverList = env.SERVERS.split(",")
                        for (server in serverList) {
                            echo "Testing remote execution on ${server}..."
                            powershell """
                                \$securePassword = ConvertTo-SecureString '${REMOTE_PASSWORD}' -AsPlainText -Force
                                \$cred = New-Object System.Management.Automation.PSCredential ('${REMOTE_USER}', \$securePassword)

                                Invoke-Command -ComputerName '${server}' -Credential \$cred -ScriptBlock {
                                    Write-Host 'Connection Successful to ${server}!'
                                    powershell -File '${SCRIPT_PATH}'
                                    Write-Host '✅ Script Execution Completed on ${server}!'
                                }
                            """
                        }
                    }
                }
            }
        }
    }
}
