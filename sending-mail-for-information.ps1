<#  
The script needs to be executed as a domain administrator
Change unicode for your language if needed (replace "UTF8")
#>

#  Define if the script should make the changes or just run in debug
$debug = 0

#  Scriptpath 
$scriptPath = split-path -parent $MyInvocation.MyCommand.Definition
#  Define the location for the log file and clear the content of the file
$logfile = $scriptPath+"\log\email_sent_to.log"
Clear-Content $logfile


#  Function for writing information inside a email_sent_to.log with current date and time
Function LogWrite
{
   Param ([string]$logstring)
   Write-Host "$(get-date -format "yyyy-mm-dd H:mm:ss"): $logstring"
   Add-content $Logfile -value "$(get-date -format "yyyy-mm-dd H:mm:ss"): $logstring"
}

#  Define the subject for the informative email, the originator (and bcc if wanted)
$changeDate 		= (Get-Date).AddDays(7).ToString('yyyy-MM-dd')
$subject 			= "Upcoming change of passwords on $changeDate"
$originatorEmail 	= "Administrator <admins@menten.com>"
$bcc 				= "admins@menten.com"
$smtpserver 		= "sophos.menten.com"  

<#  
Contains name, first_name, email, change, salutation and department (for orientation purposes) formatted as a table seperated with "," for every userobject
Example: 
Department,Salutation,Firstname,Lastname,Change,Email
IT-Department,Misses,Ana,Admin,yes,admins@menten.com
#>

#  Define the location for the csv file used to import the needed information for each userobject and wether the userobject's password should be changed ("yes" if yes)
$csvFile = $scriptPath+"\users.csv"

#  Imports the information from the csv and executes for each userobject
Import-Csv $csvFile | ForEach-Object {
   $email 		= ($_.email)
   $salutation  = ($_.salutation)
   $name 		= ($_.name)
   $change 		= ($_.change)
   
   #  Defines the location for the mailbody (and attachment if wanted) u want to use
   $body 		= $scriptPath+"\mailbody.html"
   $body 		= Get-Content $body -Encoding UTF8 | Out-String
   $attachment  = $scriptPath+"\attachment.pdf"

   #  Replaces the variables inside mailbody.html with name and salutation for each userobject for each run
   $body = $body.replace("%salutation%",$salutation)
   $body = $body.replace("%name%",$name)
   $body = $body.replace("%currentDate+7%",$changeDate)

   try {
     #  Checks wether to send an email to the current userobject 
     if($change -eq "yes") {

        #  Writes information in the log
        Logwrite "Use the following information: $salutation, $name"
        LogWrite "Send mail to: $email"
        LogWrite "Send-MailMessage -To $email -from $originatorEmail -bcc $bcc -Subject $subject -Body $body -BodyAsHtml -encoding ([System.Text.Encoding]::UTF8)
		-Attachments $attachment -SmtpServer exchange.koeln.egetuerk.de"
        
        #  Sends the email to current userobject
        if(!$debug){Send-MailMessage -To $email -from $originatorEmail -bcc $bcc -Subject $subject -Body $body -BodyAsHtml -encoding ([System.Text.Encoding]::UTF8)´
		-Attachments $attachment -SmtpServer $smtpServer}
     }
   } catch {
     #  Writes information in the log
     LogWrite "Error while sending the mail to: $email"
   } 
}
