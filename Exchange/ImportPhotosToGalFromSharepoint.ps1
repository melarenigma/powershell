Add-PSSnapin Microsoft.Exchange.Management.Powershell.Support -ErrorAction SilentlyContinue 
Add-PSSnapin Microsoft.Exchange.Management.PowerShell.E2010 -ErrorAction SilentlyContinue

# get the list of people from exchange gal (filter out system mailboxes and only include staff user mailboxes)
$Recipients = Get-Recipient | where {($_.RecipientType -eq "UserMailbox") -and !($_.OrganizationalUnit.Contains("System")) -and ($_.OrganizationalUnit.Contains("Staff"))}

$clnt = new-object System.Net.WebClient
$cred = new-object System.Net.NetworkCredential

# Use an account with read access to the photos library on sharepoint mysite
$cred.Username = 'Username'
$cred.Domain = 'Domain'
$cred.Password = 'Password'

# used to build the photo filename based on sharepoint mysite naming rules
$domain = 'UserDomain'

# base url for mysites
$mysiteurl = 'https://my.domain.com'

$clnt.Credentials = $cred

foreach ($Recipient in $Recipients)
{

	$photopath = $mysiteurl + "/User%20Photos/Profile%20Pictures/_w/" + $domain + "_" + $Recipient.SamAccountName + "_MThumb_jpg.jpg"
	$file = "C:\Scripts\tmp\" + $Recipient.SamAccountName + ".jpg"

	try
    {
		# download the file
		$clnt.DownloadFile($photopath,$file)
	}
	catch [Net.WebException]
	{
		# if we cant download a file, import a default photo (for people who have removed thier picture)
        $photopath = $mysiteurl+"/User%20Photos/Profile%20Pictures/nopic.jpg"
		$clnt.DownloadFile($photopath,$file)
	}
	
    write-host 'Downloaded from:' $photopath ' to:' $file ' import to:' $Recipient.SamAccountName

	# import the photo into the gal (stream the photo from the file)
	Import-RecipientDataProperty -Identity $Recipient.Identity -Picture -FileData ([Byte[]]$(Get-Content -Path $file -Encoding Byte -ReadCount 0)) -WarningAction SilentlyContinue
	
	# clean up the file when you're done
    del $file

}

# update the addressbook
Update-OfflineAddressBook "Default Offline Address List"

Remove-PSSnapin Microsoft.Exchange.Management.Powershell.Support -ErrorAction SilentlyContinue
Remove-PSSnapin Microsoft.Exchange.Management.PowerShell.E2010 -ErrorAction SilentlyContinue