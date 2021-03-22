<#  
Run as Domain-Administrator
#>


#  FQDN of Domaincontroller
$domainController = 'Your Domain Controller'


#  Checks for RemoteAD Powershellmodule and installs it if neccesarry
if(Get-Module -ListAvailable -Name RemoteAD){
    "RemoteAD Module already installed"
}
else{
    $S = New-PSSession -ComputerName $domainController
    Export-PSsession -Session $S -Module ActiveDirectory -OutputModule RemoteAD
    Remove-PSSession -Session $S
    Import-Module RemoteAD
}


#  Creates empty variable $data
$data = @()


#  Searches for all domain controllers in domain and executes commands for each
Get-ADDomainController -filter * | foreach {

    
    #  Executes command on each dc and filters for event id 4723 as a job
    Invoke-Command -ComputerName $_.Name -AsJob -JobName $_.Name -ScriptBlock {
        Get-EventLog -Logname Security -InstanceId "4723" | Select EntryType,TimeWritten , @{ Name = 'User'; Expression = {  $_.ReplacementStrings[0] }} 
    }
}


#  Waits until all jobs on every dc are finished
While((Get-Job).State -contains "Running"){
}


#  Colects all data from every job and saves them in $data
Get-ADDomainController -filter * | foreach {
    $data += Receive-Job $_.Name | Select entryType,TimeWritten,User
}


#  Scriptpath 
$scriptPath = split-path -parent $MyInvocation.MyCommand.Definition


#  Location for exported changes
$path = $scriptPath+"\log\PW_changed.csv"
$data | Export-Csv -Path $path -Delimiter ";" -NoTypeInformation