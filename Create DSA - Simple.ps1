# Author: Ian D. Hanley | LinkedIn: /in/ianhanley/ | Twitter: @IanDHanley
# Github: https://github.com/EEN421
# Website: www.hanleycloudsolutions.com
# Blog: Hanley.cloud / DevSecOpsDad.com

# Description: This script is helpful for simple deployments on a single domain. It creates a gMSA and grants it the required read privileges for use as a DSA in Defender for Identity

# Step 1: Prompt the user for the domain and a name for the DSA that will be created in step 3.
# Validate that the domain and gMSA account name are provided and meet the naming conventions.
$domain = Read-Host -Prompt "Please enter the domain"
$gmsaAccountName = Read-Host -Prompt "Please enter the gMSA account name"

# Step 2: Set HostsGroup to Default Domain Controllers OU (this way, this automatically applies to newly added DCs and reduces overhead)
$gMSA_HostsGroup = Get-ADGroup -Identity 'Domain Controllers'

# Step 3: Create new gMSA using Read-Host input from above statements:
New-ADServiceAccount -Name "$gmsaAccountName" -DNSHostName "$gmsaAccountName.$domain" -PrincipalsAllowedToRetrieveManagedPassword $gMSA_HostsGroup

# Step 4: Grab distinguished name for Deleted Objects
$distinguishedName = ([adsi]'').distinguishedName.Value
$deletedObjectsDN = "CN=Deleted Objects,$distinguishedName"

# Step 5: Make current user the Owner of Deleted Objects (required for next step)
dsacls.exe "$deletedObjectsDN" /takeOwnership

# Step 6: Assign read permissions for Deleted Objects to DSA account
# This requires current user account to have ownership (see previous command)
dsacls.exe "$deletedObjectsDN" /G "$domain\$gmsaAccountName:LCRP"
