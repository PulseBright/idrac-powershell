$idraclist = @()
$idraclist = Import-Csv .\serverlist.csv

$acceptableAnswer = $null
$url = $null
$addServer = $false

while($acceptableAnswer -eq $null) {
    
    $count = 1
    foreach($server in $idraclist){

        if($(Test-Connection $server.url -Count 1 -quiet)){ $status = "Green" }
        else { $status = "Red"; $server.status = "down" }
    
        Write-host -NoNewline "[$count]" -ForegroundColor $status
        Write-host -NoNewline " $($server.name) - $($server.model) ("
        Write-host -NoNewline "$($server.os)" -ForegroundColor Cyan 
        Write-Host ")"
    
        $count++
    }

    write-host "[$count] Add a server to this list." -ForegroundColor Cyan
    
    [uint16]$number = Read-Host -prompt "Choose server to connect to [1-$count]"

    

    if($number -eq $count){
        $acceptableAnswer = $true
        $addServer = $true
    } elseif(($number -ge $count) -or ($number -le 0)){

    } elseif ($idraclist[$number-1].status -eq "up") {
        $acceptableAnswer = $true
        $url = $idraclist[$number-1].url
    }
}


if($addServer) {
    $server_url = Read-Host -Prompt "What is the server's iDRAC address (e.g. 'idrac.domain.com')"
    $server_name = Read-Host -Prompt "What is the server's name (e.g. 'My server')"
    $server_model = Read-Host -Prompt "What is the server's model (e.g. 'Dell PowerEdge R610')"
    
    $os_list = @(
        "Windows Server 2016",
        "Windows Server 2012R2",
        "ESXi 6.5",
        "ESXi 6.0",
        "XCP-NG 7.5.0",
        "XCP-NG")

    $os_count = 1

    foreach($choice in $os_list) {
        Write-host "[$os_count] $choice"
        $os_count++
    }

    [uint16]$server_os = Read-host -Prompt "What is the server's OS [1-$os_count]"
  
    Add-Content -Value "$server_name,$server_model,$($os_list[$server_os-1]),$server_url,up" -Path .\serverlist.csv

}
else {
    $creds = Get-Credential -Message "Credentials to connect to $url"

    Write-host "Connecting to $url"

    Start-Process ".\jre\bin\java" -Argumentlist "-cp avctKVM.jar -Djava.library.path=.\lib com.avocent.idrac.kvm.Main ip=$url kmport=5900 vport=5900 user=$($creds.GetNetworkCredential().UserName) passwd=$($creds.GetNetworkCredential().Password) apcp=1 version=2 vmprivilege=true helpurl=https://$($url):443/help/contents.html"
}
