# Author: Ian D. Hanley | LinkedIn: /in/ianhanley/ | Twitter: @IanDHanley
# Github: https://github.com/EEN421
# Website: www.hanleycloudsolutions.com
# Blog: Hanley.cloud / DevSecOpsDad.com

# Description: This script prompts for the gMSA used as the Directory Service Account (DSA) for your domain in Defender for Identity (MDI)

# Install & import DFI module:
Install-Module DefenderForIdentity
Import-Module DefenderForIdentity

# Print new line to console:
Write-Host "`n"
 
# Prompt for gMSA to test:
$identity = Read-Host -Prompt 'Please specify gMSA to test against'

# Test on this DC: 
Write-Host "`nDoes this gMSA work on this DC (true/false)?" 
Test-ADServiceAccount -Identity $identity

# Return a list of other principles/DC's that can use this gMSA:
Write-Host "`nPrinciples allowed to retrieve the PW for this gMSA?"
(Get-ADServiceAccount -Identity $identity -Properties *).PrincipalsAllowedToRetrieveManagedPassword
 
# Test DSA Identity with -Detailed switch:
Write-Host "`nThe following is applicable only to Directory Service Accounts (DSA):" 
Test-MDIDSA -Identity $identity -Detailed 
