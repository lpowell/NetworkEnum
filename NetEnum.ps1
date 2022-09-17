# Network enumeration and information gathering
# Liam Powell

Param($Interface, $Conn, [switch]$Help, [switch]$Verbose, [switch]$Colorblind)

function GlobalSettings{
    $global:ErrorActionPreference="SilentlyContinue"
    $global:BadColor = 'Red'
    $global:GoodColor = 'Green'
    if($Colorblind){
        $global:BadColor = 'Magenta'
        $global:GoodColor = 'Cyan'
    }
}

function Gather{

    if($Interface){
        $Adapter = Get-CimInstance Win32_NetworkAdapterConfiguration | ? Description -match $Interface
    }else{
        $Adapter = Get-CimInstance Win32_NetworkAdapterConfiguration
    }
    foreach($x in $Adapter){
        echo "<-----$x----->"
        ft -InputObject $x -Property Description, IPAddress, IPSubnet, DefaultIPGateway, DNSHostName, DNSServerSearchOrder -AutoSize
        echo "<-----Connections----->"
        try{
            $Connections = Get-NetTCPConnection -LocalAddress $x.IPAddress[0]
            ft -InputObject $Connections -Property LocalAddress, LocalPort, RemoteAddress, RemotePort -AutoSize
            if($Verbose){
                try{
                    $DNSList=@()
                    echo "<-----Resolving DNS Names----->"
                    foreach($x in $connections){
                        $IsDNS = Resolve-DNSName $x.RemoteAddress
                        if($IsDNS){
                            $DNSList += $IsDNS
                        }
                    }
                    ft -InputObject $DNSList -Property Name, Server, Type
                }catch{

                }
                try{
                    $TestPort =@()
                    echo "<-----Testing Connections----->"
                    foreach($x in $connections){
                        $strx = (Out-String -InputObject $x.RemoteAddress).Trim()
                        $TestPort += Get-CimInstance Win32_PingStatus -filter "Address='$strx' AND Timeout=1000"
                    }
                    ft -InputObject $TestPort -Property Address, IPV4Address, IPV6Address, ResponseTime, StatusCode -AutoSize
                    }catch{

                    }
            }
            }catch{
                echo "No connections on $x"
                Write-Host
            }
    }



}

if($help){
    Write-Host "Network Enumeration Tool"
    Write-Host "Use -Verbose to get DNS Resolution and connection testing"
    Write-Host "Use -Interface to specify a specific interface"
    exit
}
GlobalSettings
Gather