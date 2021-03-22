<# 
The script needs to be executed as a domain administrator
#>

#  Latest Powershell found at:    https://github.com/PowerShell/PowerShell/releases/tag/v7.1.3
#  Powershell Modules found at:   https://www.microsoft.com/en-us/download/details.aspx?id=45520
#  Using PSRemoting for using Powershell Module installed on Domaincontroller (Enable the next lines if you do not have the module installed)
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

#  Define if the script should make the changes or just run in debug
$debug = 0
#  Scriptpath 
$scriptPath = split-path -parent $MyInvocation.MyCommand.Definition
# Define the location for the log file and clear the content of the file
$logfile = $scriptPath+"\log\user_passwordchange_activation.log"
Clear-Content $logfile

# Function for writing information inside a user_passwordchange_activation.log with current date and time
Function LogWrite
{
   Param ([string]$logstring)
   Write-Host  "$(get-date -format "yyyy-mm-dd H:mm:ss"): $logstring"
   Add-content $Logfile -value "$(get-date -format "yyyy-mm-dd H:mm:ss"): $logstring"
}

<# 
Contains name, firstname, email, change, salutation and department (for orientation purposes) formatted as a table seperated with "," for every userobject
Example: 
Department,Salutation,firstname,name,Change,Email
IT-Department,Misses,Ana,Admin,yes,admins@menten.com
#>
# Define the location for the csv file used to import the needed information for each userobject and wether the userobject's password should be changed ("yes" if yes)
$csvFile = $scriptPath+"\users.csv" 

# Imports the information from the csv and executes for each userobject
Import-Csv $csvFile | ForEach-Object {
    
   $email = ($_.Email)
   $salutation = ($_.Salutation)
   $name = ($_.Name)
   $change = ($_.Change)

   # Checks if email for current userobject is available
   if($email -eq ""){
        return
   }

   # Build samaccountname from userobject's attribute emailadress
   $samaccountname = (Get-ADUser -filter * -Properties * | where emailaddress -like $email).samaccountname

    # Checks wether to change the options or not
    if($change -eq "yes"){
        try{

            # Deactivates Password never expires 
            Logwrite "Change user login option in active directory for $samaccountname"
            if(!$debug){Set-ADUser -Identity $samaccountname -PasswordNeverExpires $false}    
            
            # Writes changes for current userobject in log file
            Logwrite "Uncheck checkbox ""Password never expires"" for Account: $samaccountname"

            # Sets Change password at next login
            Logwrite "Force $samaccountname user to change password with checkbox ""Change pasword at next logon"""
            #  Make the Change that user needs to change password at next logon
            if(!$debug){Set-ADUser -Identity $samaccountname -ChangePasswordAtLogon $true}
        }catch{
            # Logs error while changing the options
            LogWrite "Error while changing the options: $samaccountname"
        } 
    }
}
