Param (
	[string]$Path = "UNC path here",
	[string]$SMTPServer = "smtp.server.com",
	[string]$From = "from@address.com",
	[string]$To = "to@address.com",
	[string]$Subject = "New File Uploaded"
	)

$SMTPMessage = @{
    To = $To
    From = $From
	Subject = "$Subject at $Path"
    Smtpserver = $SMTPServer
}

$File = Get-ChildItem $Path -File | Where { $_.LastWriteTime -ge [datetime]::Now.AddHours(-3) }
If ($File)
{	$SMTPBody = "`nThe following files have recently been added/changed:`n`n"
	$File | ForEach { $SMTPBody += "$($_.Name)`n" }
	Send-MailMessage @SMTPMessage -Body $SMTPBody
	
}