# Set environment variables manually
$REMOTE_SERVER = "13.235.65.246"  # Server IP
$REMOTE_APP_PATH = "C:\inetpub\wwwroot\MyApp" # Deployment path (for reference)
$ZIP_FILE = "app-43.zip"  # Replace with the actual ZIP file name
$WINSCP_PATH = "C:\Program Files (x86)\WinSCP\WinSCP.com"
$HOST_KEY_FINGERPRINT = "ssh-ed25519 255 eMn9LBmr1totw0d9aWCdS9xzhFYhxoWNN2erk/TgeJM"  # Correct host key
$USERNAME = "administrator"  # Your SSH username
$PASSWORD = "Test12.com"  # Your SSH password (Replace it securely)

# Run the WinSCP command manually
& "$WINSCP_PATH" /command `
    "open sftp://$USERNAME:$PASSWORD@$REMOTE_SERVER/ -hostkey=`"$HOST_KEY_FINGERPRINT`"" `
    "put `"$ZIP_FILE`" `"/C:/Deploy/$ZIP_FILE`"" `
    "exit"
