#Initially to use WinSCP with to download java reports that are found in target linux VMs
#can be used to bulk download any file on target VMs by setting $source

Add-Type -Path "C:\Program Files (x86)\WinSCP\WinSCPnet.dll"

$credpath= ""
$servers = import-csv "C:\vms.csv"
$credential = Import-Clixml -path $credpath
$source = "/tmp/*_java_version.txt"
$reportDestination = "" 


function Send-FTP($server) {
    try
    {
     
        # Setup session options
        $sessionOptions = New-Object WinSCP.SessionOptions
        $sessionOptions.Protocol = [WinSCP.Protocol]::Sftp
        $sessionOptions.PortNumber = 22
        $sessionOptions.HostName = $server
        $sessionOptions.UserName = $credential.UserName
        $sessionOptions.Password = $credential.Password
        $sessionOptions.SecurePassword = $credential.Password
        $SessionOptions.GiveUpSecurityAndAcceptAnySshHostKey = "True"
        

        $session = New-Object WinSCP.Session
     
        try
        {
            # Connect
            $session.Open($sessionOptions)
     
            # Upload files
            $transferOptions = New-Object WinSCP.TransferOptions
            $transferOptions.TransferMode = [WinSCP.TransferMode]::Binary
     
            $transferResult = $session.GetFiles("$source", "$reportDestination", $False, $transferOptions)
     
            # Print results
            foreach ($transfer in $transferResult.Transfers)
            {
                Write-Host  -foregroundcolor green ("Download of {0} succeeded" -f $transfer.FileName)
            }
        }
        finally
        {
            # Disconnect, clean up
            $session.Dispose()
        }
     
    }
    catch [Exception]
    {
        Write-Host $_.Exception.Message
    }
}

foreach ($server in $servers){
Send-FTP $server.Name
sleep 1
}