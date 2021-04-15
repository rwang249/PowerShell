#report to get # of RHEL licenses on satellite server

Function Decrypt-String{
Param(
    [Parameter(
        Mandatory=$True,
        Position=0,
        ValueFromPipeLine=$true
    )]
    [Alias("String")]
    [String]$EncryptedString,

    [Parameter(
        Mandatory=$True,
        Position=1
    )]
    [Alias("Key")]
    [byte[]]$EncryptionKey
)
    Try{
        $SecureString = ConvertTo-SecureString $EncryptedString -Key $EncryptionKey
        $bstr = [Runtime.InteropServices.Marshal]::SecureStringToBSTR($SecureString)
        [string]$String = [Runtime.InteropServices.Marshal]::PtrToStringAuto($bstr)
        [Runtime.InteropServices.Marshal]::ZeroFreeBSTR($bstr)

        Return $String
    }
    Catch{Throw $_}

}

$encryptedString=get-content "#pass"
[Byte[]]$Key = 117,9,103,192,133,20,53,149,81,95,108,34,81,224,226,220,56,68,133,120,139,241,176,239,171,54,231,205,83,57,51,255

###Define Credentials + Initialize Result Variables###
$user = "user"
$serverHost = ""
$pass=Decrypt-String -EncryptedString $EncryptedString -EncryptionKey $Key
$pair = "${user}:${pass}"
$prem_available = $null
$std_available = $null

###Convert Credentials to base64 to add to header###
$bytes = [System.Text.Encoding]::ASCII.GetBytes($pair)
$base64 = [System.Convert]::ToBase64String($bytes)
$basicAuthValue = "Basic $base64"
$headers = @{ Authorization = $basicAuthValue }

###Make Rest Call, parse JSON response and store into variable depending on subscription level###
$rest=Invoke-WebRequest -Uri "https://$serverhost.blah.com/katello/api/v2/subscriptions" -Headers $headers -Method Get
$json = ConvertFrom-Json $rest.content
$prem_results=$json.results | where-object { $_.name -match "^Red.*Premium"}
$std_results=$json.results | where-object {$_.name -match "^Red.*Standard"}

###Add all Premium Licenses###
foreach($result in $prem_results){

$prem_available += $result.available

}

###Add all Standard Licenses###
foreach($result in $std_results){

$std_available += $result.available

}

###Output Results###
write-host "Number of RHEL Premium Licenses Available: $prem_available"
write-host "Number of RHEL Standard Licenses Available: $std_available"
