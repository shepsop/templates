function Get-ADGroupMembers ($ADGroup) {
    #$_
    Get-ADGroup $ADGroup -properties Members | select -ExpandProperty Members | foreach {
        $user=get-aduser $_ -Server (get-dc -name $_) -Properties Manager | select Name, Manager
        $manager=Get-ADUser $user.manager -server (get-dc -name $_) | select -ExpandProperty Name
        $tmpObject=New-Object -TypeName psobject
        $tmpObject | Add-Member -NotePropertyName "User" -NotePropertyValue $user.Name
        $tmpObject | Add-Member -NotePropertyName "Manager" -NotePropertyValue $manager
        $tmpObject | Add-Member -NotePropertyName "Group" -NotePropertyValue $ADGroup
        return $tmpObject
        
    }
    #"==============================="
}

function Get-MembersAndExpirationDate ($ADGroup) {
        $tmpUsers=@()
        Get-ADGroup $ADGroup -properties Members | select -ExpandProperty Members | foreach {
        $tmpUser=Get-ADUser $_ -server (get-dc -name $_)-Properties AccountExpirationDate, Manager | select Name, AccountExpirationDate, Manager
        $tmpUserObject=New-Object -TypeName psobject
        $tmpUserObject | Add-Member -NotePropertyName "User" -NotePropertyValue $tmpUser.Name
        $tmpUserObject | Add-Member -NotePropertyName "Account Expiration" -NotePropertyValue $tmpUser.AccountExpirationDate
        $tmpUserObject | Add-Member -NotePropertyName "Manager" -NotePropertyValue $(get-aduser $tmpUser.Manager -server (get-dc -name $tmpUser.Manager) -ea SilentlyContinue| select -ExpandProperty Name)
        $tmpUsers+=$tmpUserObject
        }
        return $tmpUsers
  
}
function Get-DC ($name) {
    
    switch -Wildcard ($name) 
    {
    "*domain1*" {(Get-ADDomainController -Discover -DomainName domain1 -Service ADWS).Name}
    "*domain2*" {(Get-ADDomainController -Discover -DomainName domain2 -Service ADWS).Name}
    "*domain3*" {(Get-ADDomainController -Discover -DomainName domain3 -Service ADWS).Name}
    }

}
Set-Content -Path "C:\Script\ADGroupMembershipReport\report.csv" -Value "" -Force -Confirm:$false
$groups="group1","group2","group3"
#get-date | out-file "C:\Script\ADGroupMembershipReport\report.txt" -Append:$false

$groups | foreach {
    $members+=Get-ADGroupMembers -ADGroup $_ 
    
}
$members | Export-Csv "C:\Script\ADGroupMembershipReport\report.csv"  -NoTypeInformation -Force
Send-MailMessage -Subject "Monthly Group Membership Report" -To "to@address.com" -Attachments "C:\Script\ADGroupMembershipReport\report.csv" -SmtpServer smtp.server.com -From from@address.com
$group="group1","group2","group3"    
 $group | foreach {
    Get-MembersAndExpirationDate -ADGroup $_ | Export-csv "C:\Script\ADGroupMembershipReport\$_.csv" -NoTypeInformation -Force 
}
$attachments=@()
$group | foreach {$attachments+="C:\Script\ADGroupMembershipReport\$_.csv"}
Send-MailMessage -Subject "Monthly Group Membership Report - Locus" -To "to@address.com>"-Attachments $attachments -SmtpServer smtp.server.com -From from@address.com
#$attachments