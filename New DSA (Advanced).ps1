# Author: Ian D. Hanley | LinkedIn: /in/ianhanley/ | Twitter: @IanDHanley
# Github: https://github.com/EEN421
# Website: www.hanleycloudsolutions.com
# Blog: Hanley.cloud / DevSecOpsDad.com

# Description: This script facilitates a custom setup for more advanced, multi-domain environments by allowing the user specify a HostGroup and DC's with the MDI sensor installed.
# Note: In a multi-domain environment, it's best practice to leverage separate gMSA's per domain to act as DSA's for MDI.

# Step 1: Prompt the user for the domain and a name for the DSA that will be created in step 4:
$domain = Read-Host -Prompt "Please enter the domain"
$DSA_HostsGroupName = Read-Host -Prompt "Please enter a name for your group of DC's"
$DSA_AccountName = Read-Host -Prompt "Please enter a name for your gMSA account"

# Step 2: Prompt the user for the principals allowed to retrieve the password (principals will be your domain controllers with the MDI sensor installed):
$principals = Read-Host -Prompt "Please enter the principals (separated by a comma)"
$principalsArray = $principals -split ',' | ForEach-Object { $_.Trim() }

# Step 3: Import the required PowerShell module:
Import-Module ActiveDirectory

# Step 4: Create the group and add the members
$DSA_HostsGroup = New-ADGroup -Name $DSA_HostsGroupName -GroupScope Global -PassThru
$principalsArray | ForEach-Object { Get-ADComputer -Identity $_ } |
    ForEach-Object { Add-ADGroupMember -Identity $DSA_HostsGroupName -Members $_ }

# Step 5: Create the gMSA and associate it with the group:
New-ADServiceAccount -Name $DSA_AccountName -DNSHostName "$DSA_AccountName.$domain" -PrincipalsAllowedToRetrieveManagedPassword $DSA_HostsGroup
