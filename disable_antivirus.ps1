
<# get the script location #>
param (
    [string] $envname,
    [string] $action
)

$envname = $envname.ToUpper()
$action = $action.ToUpper()

if ($PSCommandPath -eq $null) { 
    function GetPSCommandPath() { 
        return $MyInvocation.PSCommandPath; 
    } $PSCommandPath = GetPSCommandPath; 
}

if($PSBoundParameters.Values.Count -eq 0 ) {
    echo "runs like : SCRIPTNAME <ENVIRONMENT> <ACTION>"
    echo "eg : $PSCommandPath AUCSTS2 CHANGE"
    echo "actions : help (get HELP) , LIST (list all files ), CHANGE (list and rename and copy file and restart PIA service)"
}

$scriptPath = split-path -parent $MyInvocation.MyCommand.Definition
$logFileName = "$PSCommandPath.log"
$date = (Get-Date).ToString('yyyy-MM-dd HH:mm:ss')
#$fileDate = (Get-Date).ToString('yyyy-MM-dd')
$psWebDir = "D:\apps\cfghome\$envname\webserv"
$virusScanPath = "applications\peoplesoft\PORTAL.war\WEB-INF\classes\psft\pt8\virusscan"
$virusScanFile = "VirusScan.xml"
$renameFileName = "VirusScan.xml_BKP_beforedisableICAP"
$sourceFile = "$scriptPath\$virusScanFile"
$psService = "peoplesoft"

#D:\apps\cfghome\AUCSTS2\webserv



function logInfo($info){
    "$date Info: $info" | Out-File -Append  $logFileName
}

logInfo "This is sample script to backup the $logFileName"  

if ($action -eq "HELP" ) {
    echo "runs like > SCRIPTNAME <ENVIRONMENT> <ACTION>"
    echo "eg : $PSCommandPath AUCSTS2 CHANGE"
    echo "actions : help (get HELP) , LIST (list all files ), CHANGE (list and rename and copy file and restart PIA service)"

}

# list all files
if ($action -eq "LIST" ) {
   logInfo "list all VirusScan.xml file on $psWebDir" 
   $listDirectory = (Get-ChildItem $psWebDir -Directory).Name
   logInfo "sub folders in $psWebDir are $listDirectory"

   Foreach ($folder in $listDirectory){
    $virusScanFullPath = "$psWebDir\$folder\$virusScanPath"
    $sub = (Get-ChildItem $virusScanFullPath -Directory).Name
    logInfo "all files in $psWebDir\$folder\$virusScanPath are $sub "
    $findFile = $(Get-Childitem -Path $virusScanFullPath -Include $virusScanFile -Recurse)
    if ( $findFile -ne $null ) {
        logInfo "locating file - $findFile"
        echo "locating file - $findFile"
    }
    else{
        logInfo "locating file - File NOT FOUND!!! $virusScanFile in $virusScanFullPath"
    }
   }
}

if ($action -eq "CHANGE" ) {
    logInfo "list all VirusScan.xml file on $psWebDir" 
    $listDirectory = (Get-ChildItem $psWebDir -Directory).Name
    logInfo "sub folders in $psWebDir are $listDirectory"

    Foreach ($folder in $listDirectory){
        $virusScanFullPath = "$psWebDir\$folder\$virusScanPath"
        $sub = (Get-ChildItem $virusScanFullPath -Directory).Name
        logInfo "all files in $psWebDir\$folder\$virusScanPath are $sub "
        $findFile = $(Get-Childitem -Path $virusScanFullPath -Include $virusScanFile -Recurse)
        if ( $findFile -ne $null ) {
            logInfo "locating file - $findFile"
            echo "locating file - $findFile"
        }
        else{
            logInfo "locating file - File NOT FOUND!!! $virusScanFile in $virusScanFullPath"
            echo "locating file - File NOT FOUND!!! $virusScanFile in $virusScanFullPath"
        }

        # rename file
        if (-not ([string]::IsNullOrEmpty($findFile)))
        {
            Rename-Item -Path "$virusScanFullPath\$virusScanFile" -NewName "$renameFileName"
            if ( $? -eq $true ) {
                logInfo "renaming File SUCCESS - $findFile"
                echo "rename $virusScanFullPath\$virusScanFile -NewName $renameFileName"

                # copy file
                $findNewFile = $(Get-Childitem -Path $virusScanFullPath -Include $renameFileName -Recurse)
                if (-not ([string]::IsNullOrEmpty($findNewFile)))
                {
                    Copy-Item $sourceFile -Destination $virusScanFullPath
                    if ( $? -eq $true ) {
                        logInfo "SUCCESS copy File from $sourceFile -Destination $virusScanFullPath"
                        echo "SUCCESS copy File from $sourceFile -Destination $virusScanFullPath"

                        # restart the PS PIA service
                        echo "folder $folder and psService $psService"
                        if ($folder.ToString().ToUpper() -eq $psService.ToString().ToUpper() ) {
                            $psEnv = $envname.Substring(0, 4)
                            if($psEnv.ToUpper() -eq "AUFS"){
                                $getPIA = "- PIA 8"
                            } else {
                                $getPIA = "ADMIN"
                                echo "$psEnv admin $getPIA"
                            }
                        } else {
                            $getPIA = $folder.ToString().ToUpper()
                            echo "other $getPIA"
                        }

                        #echo "RRRRRR - $folder - *PeopleSoft*$envname*$getPIA*"
                        Get-Service -Displayname "*PeopleSoft*$envname*$getPIA*" -Exclude "*PSNT*" | stop-service -force
                        if ( $? -eq $true ) {
                            logInfo "Stop service Success for *PeopleSoft*$envname*$getPIA*"
               
                            Get-Service -Displayname "*PeopleSoft*$envname*$getPIA*" -Exclude "*PSNT*" | start-service
                            if ( $? -eq $true ) {
                                logInfo "Start service Success for *PeopleSoft*$envname*$getPIA*"

                                Get-Service -Displayname "*PeopleSoft*$envname*$getPIA*" -Exclude "*PSNT*"
                                if ( $? -eq $true ) {

                                    sleep -Milliseconds 600
                                    $startTime = $((Get-EventLog -LogName "System" -Source "Service Control Manager" -EntryType "Information" -Message "*PeopleSoft*$envname*$getPIA*" -Newest 1).TimeGenerated.ToString('yyyy-MM-dd HH:mm:ss'))
                                    if ((Get-Date $startTime) -ge (Get-Date $date)) {
                                        logInfo "SUCCESS !!!! Service *PeopleSoft*$envname*$getPIA* on $startTime and script runs on $date"
                                        echo "SUCCESS !!!! Service *PeopleSoft*$envname*$getPIA* on $startTime and script runs on $date"
                                    } 
                                    else {
                                        logInfo "FAILED!!!! Service *PeopleSoft*$envname*$getPIA* on $startTime and script runs on $date"
                                        echo "FAILED!!!! Service *PeopleSoft*$envname*$getPIA* on $startTime and script runs on $date"
                                    }
                                }
                            }
                        }
                    }
                    else {
                        logInfo "FAILED!!! copy File from $sourceFile -Destination $virusScanFullPath"
                        echo "FAILED!!! copy File from $sourceFile -Destination $virusScanFullPath"
                    }        
                }
            }
            else {
                logInfo "renaming File FAILED!!! - $findFile"
                echo "renaming File FAILED!!! - $findFile"
            }
        }
    }
}