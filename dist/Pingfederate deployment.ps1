add-type @"
    using System.Net;
    using System.Security.Cryptography.X509Certificates;
    public class TrustAllCertsPolicy : ICertificatePolicy {
        public bool CheckValidationResult(
            ServicePoint srvPoint, X509Certificate certificate,
            WebRequest request, int certificateProblem) {
            return true;
        }
    }
"@


function GetMachineFQDN
{
    return $env:computername+"."+$env:userdnsdomain
}



function GetPingFedHeartbeatUrl
{
  # $machineFQDN = $[System.Net.Dns]::GetHostByName(($env:computerName)) | FL HostName | Out-String | %{ "{0}" -f $_.Split(':')[1].Trim() };
  $machineFQDN = GetMachineFQDN
  $heartbeatUrl = "https://"+$machineFQDN+"/pf/heartbeat.ping"
  return $heartbeatUrl;
}


function GetPingFedAdminUrl
{
    $machineFQDN = GetMachineFQDN
    $adminUrl = "https://"+$machineFQDN+":9999/pingfederate/app"
    return $adminUrl
}


function IsPingFedHeartbeatOK
{

    [System.Net.ServicePointManager]::CertificatePolicy = New-Object TrustAllCertsPolicy
    $webClient = new-object System.Net.WebClient -EA SilentlyContinue
    $webClient.Headers.Add("user-agent", "PowerShell Script")
    $MaxNumberOfAttempts = 20
    $TotalNumberOfAttempts = 0
    $heartbeatURL = $args[0]
    "Heartbeat check for " + $heartbeatURL + " started"
    $output = ""
    $startTime = get-date
    while ($MaxNumberOfAttempts -gt $TotalNumberOfAttempts) {
       try{
           $output = $webClient.DownloadString($heartbeatURL) 
       }
       catch
       {
       }
       $endTime = get-date

       if ($output -like "*OK*") {
          Write-Host -foregroundcolor Green "PingFed Engine Heartbeat UP! :"   ($endTime - $startTime).TotalSeconds " seconds elapsed"
          break;
       } else {
          Write-Host -foregroundcolor Gray "PingFed Engine Heartbeat coming up : " ($endTime - $startTime).TotalSeconds " seconds elapsed"
       }
       $TotalNumberOfAttempts = $TotalNumberOfAttempts + 1
       sleep(6)
    }

    return $output
}


function IsPingFederateAdminOK
{

    [System.Net.ServicePointManager]::CertificatePolicy = New-Object TrustAllCertsPolicy

    $heartbeatURL = $args[0]
    

    "Heartbeat check for Admin on " + $heartbeatURL + " started"

    $MaxNumberOfAttempts = 20
    $TotalNumberOfAttempts = 0
    $startTime = get-date
    while ($MaxNumberOfAttempts -gt $TotalNumberOfAttempts) {
        $req=[system.Net.HttpWebRequest]::Create($heartbeatURL) 
        $res = $req.getresponse();
        $stat = $res.statuscode;
        $res.Close();
        "Status is " + $stat
       $endTime = get-date
       if ($stat -eq "OK") {
          Write-Host -foregroundcolor Green "PingFed Admin UP! :"   ($endTime - $startTime).TotalSeconds " seconds elapsed"
          break;
       } else {
          Write-Host -foregroundcolor Gray "PingFed Admin coming up : " ($endTime - $startTime).TotalSeconds " seconds elapsed"
       }

       $TotalNumberOfAttempts = $TotalNumberOfAttempts + 1
       sleep(6)
    }
    return $stat
}

<#
The below function reads the run.properties file and looks for the "pf.operational.mode"
This property indicates the operational mode of the runtime server (protocol
engine) from a clustering standpoint. 

 Valid values are:
     STANDALONE        - This server is a standalone instance that runs both 
                       the UI console and protocol engine (default).
     CLUSTERED_CONSOLE - This server is part of a cluster and runs only the 
                       administration console.
     CLUSTERED_ENGINE  - This server is part of a cluster and runs only the 
                      protocol engine. 
#>
function GetPingFederateOperationalMode
{
    $runPropertiesPath = $args[0]
    $runPropertiesContents = Get-Content $runPropertiesPath | Where { $_ -match "^pf.operational.mode=" -and $_.trim() -ne "" }
    # $runPropertiesContents
    $serverMode = ""
    # $runPropertiesContents.Length
    if ($runPropertiesContents.Length -gt 0 )
    {
        $serverMode = $runPropertiesContents.Split("=")[1]
    }
    return $serverMode
    # $hashTable = convertfrom-stringdata -stringdata $runPropertiesContents
    # $hashTable[0]
}

<#
This function pings the heartbeat URL or the admin console URL If the current PingFederate machine is an ENGIN 
or ADMIN console respectively (in case of clustered environment) 
or both the URLs if the machine has both the engine and admin console (e.g. in case of local development machine)
#>
function CheckPingFederateStatusAfterServiceStart
{

$PingFedOperationalMode = $args[0]

switch ($PingFedOperationalMode){
     STANDALONE 
     {
        "STANDALONE mode"
        $adminURL = GetPingFedAdminUrl 
        $heartbeatURL = GetPingFedHeartbeatUrl
        IsPingFederateAdminOK $adminURL
        IsPingFedHeartbeatOK $heartbeatURL
        break
     }
     CLUSTERED_CONSOLE 
     {
        "CLUSTERED_CONSOLE mode"
        $adminURL = GetPingFedAdminUrl 
        IsPingFederateAdminOK $adminURL
        break
     }
     CLUSTERED_ENGINE 
     { 
        "CLUSTERED_ENGINE mode"
        $heartbeatURL = GetPingFedHeartbeatUrl
        IsPingFedHeartbeatOK $heartbeatURL
        break
     }
     default {"Unrecognized mode"; break}
     }

}
Set-ExecutionPolicy Unrestricted

Set-Location $PSScriptRoot


$backupFolderPathPrefix = "Backup"
$deploysourceserverfolderlocation = Join-Path $PSScriptRoot server
$deploysourceserverfolderlocation

"############## Looking for PingFederate service ############"
$pingfederateserviceexecutablepath
$pingfederateserviceexecutablepath = gwmi win32_service|?{$_.name -like "pingfederate*"}|select pathname
$pingfederateservicename = gwmi win32_service|?{$_.name -like "pingfederate*"}|select displayname


if(!$pingfederateserviceexecutablepath) { throw "PingFederate service IS NOT installed on this machine. Script will not continue!"} else {"PingFederate service IS installed on this machine. Proceeding..."}

"############## Stopping PingFederate Service. ##############"
$pingfederateservicename
Stop-Service -displayname $pingfederateservicename.displayname
"############## PingFederate Service Stopped. ##############"

$pos = $pingfederateserviceexecutablepath.pathname.IndexOf(" -s ")
$pingfederateserviceexecutablepathstring = $pingfederateserviceexecutablepath.pathname.Substring(0, $pos)


"############## PingFederate service - Path to executable with -s onwards removed ##############"
$pingfederateserviceexecutablepathstring = $pingfederateserviceexecutablepathstring.Replace("`"","")
$pingfederateserviceexecutablepathstring


$pingfedexeexactlocation
$pingfedexeexactlocation = Get-Item $pingfederateserviceexecutablepathstring | Select-Object Directory

"############## PingFederate root folder ############## "
$pingfederaterootfolder
$pingfederaterootfolder = $pingfedexeexactlocation.Directory.Parent.Parent.FullName
$pingfederaterootfolder


"############## PingFederate 'server' folder path ##############"
$pingfederateserverfolder = Join-Path $pingfederaterootfolder server
$pingfederateserverfolder



# $backupPath = Join-Path $backupFolderPathPrefix $(get-date -f MM-dd-yyyy_HH_mm_ss) 
# "############## Copying the server folder to a backup folder "+$backupPath+" ##############"
# copy-item $pingfederateserverfolder -destination $backuppath -recurse
# "############## Copy complete to backup folder "+$backupPath+" ##############"

"############## PingFederate 'default' folder path ############## "
$pingfederatedefaultfolder = Join-Path $pingfederateserverfolder default
$pingfederatedefaultfolder

"############## PingFederate 'deploy' folder path ############## "
$pingfederatedeployfolder = Join-Path $pingfederatedefaultfolder deploy
$pingfederatedeployfolder

Set-Location $pingfederatedeployfolder

"############## Getting all the existing custom .jar files to be deleted ############## "
Get-ChildItem $pingfederatedeployfolder -name -filter pingfederate*.jar

"############## All custom *.jar files deleted ##############"

Write-Host "$($deploysourceserverfolderlocation) deploying to $($pingfederateserverfolder)"

Copy-Item -Path $deploysourceserverfolderlocation $pingfederaterootfolder -recurse -force
"############## Deployment completed ##############"

"############## Starting PingFederate Service. ##############"
$pingfederateservicename
Start-Service -displayname $pingfederateservicename.displayname
"############## PingFederate Service Started. ##############"

$PingFedRunPropertiesFilePath = $pingfederaterootfolder + "/bin/run.properties"
$PingFedOperationalMode = GetPingFederateOperationalMode $PingFedRunPropertiesFilePath
CheckPingFederateStatusAfterServiceStart $PingFedOperationalMode

<#
$adminURL = GetPingFedAdminUrl
$adminURL
$heartbeatURL = GetPingFedHeartbeatUrl
$heartbeatURL
IsPingFederateAdminOK $adminURL
IsPingFedHeartbeatOK $heartbeatURL
#>
pause

