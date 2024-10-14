# Author: Ian D. Hanley | LinkedIn: /in/ianhanley/ | Twitter: @IanDHanley
# Github: https://github.com/EEN421
# Website: www.hanleycloudsolutions.com
# Blog: Hanley.cloud / DevSecOpsDad.com

# Description: This script is helpful for simple deployments on a single domain.
# It creates a gMSA for use as an Action account in MDI and adds the default domain controllers OU as principles allowed to retrieve the gMSA password.

# Still need to manually add the following privileges in the GUI (for now): 

#	To enable force password reset:
#	  Permissions:
#  	    Reset password
#   Properties:
#      Read pwdLastSet
#      Write pwdLastSet

#	To disable user:
#  Properties:
#      Read userAccountControl
#      Write userAccountControl


# Step 1: Prompt the user for the domain and a name for the DSA that will be created in step 3.
# Validate that the domain and gMSA account name are provided and meet the naming conventions.
$domain = Read-Host -Prompt "Please enter the domain"
$gmsaAccountName = Read-Host -Prompt "Please enter the gMSA account name"

# Step 2: Set HostsGroup to Default Domain Controllers OU (this way, this automatically applies to newly added DCs and reduces overhead)
$gMSA_HostsGroup = Get-ADGroup -Identity 'Domain Controllers'

# Step 3: Create new gMSA using Read-Host input from above statements:
New-ADServiceAccount -Name "$gmsaAccountName" -DNSHostName "$gmsaAccountName.$domain" -PrincipalsAllowedToRetrieveManagedPassword $gMSA_HostsGroup
