##### Patch Tenant Dial Plans #####
<#
Latest update: 25th September 2020
Author: David Alderman, Telesmart Limited, New Zealand

### Synopsis ###
The purpose of this script is to create tenant dial plans for each geographical area code in New Zealand and Austrlia
The tenant dial plan will allow Microsoft Teams to:
1. Recognize local phone numbers dialed by the user and convert them to e.164
2. Recognize the emergency number and convert it to e.164

## Change Log ##
25th September 2020 - Published to Production
17th September 2020 - Initial Release.


### Naming Conventions used ###
The elements created have a naming convention as follows

TS-$cc-$type-$area

The element will always be prefixed with TS
$cc = Country Code and will be either NZ or AU and applies to the territory that will consume the element.
$type = the type of element which will be either NR=Normalization RUle or TDP=Tenant Dial Plan
$area = The geographic area code within the country covered by the element. See below for a list of geographic area codes in each country.

## Script Settings ##
Set the variables at the top of the script

"default" (or any other value) will configure new Tenant Dial Plan objects in the environment but not change users. It will output configuration commands to modify the users that can be examined copied and executed manually.
"yolo" (exactly this value) will make the changes to the environment but will *not* affect users that have already got some kind of tenant dial plan applied to them.

$scriptmode=default
$scriptmode=yolo


### Execution Plan ###
There are 4 stages to this script.
Stage 1 - Define 11 Normalization rule to cover each geographic area code and emergency number for New Zealand and Australia. These Normalization rules are ephemeral and will only be defined within the script, they are later applied to a Tenant Dial Plan which will be created on the Tenant.
Stage 2 - Identify if there already existing Tenant Dial plans using the same names we plan to use. This step will create a new Tenant Dial Plan for each geographic area if it doesnt already exist.
Stage 3 - Identify a list of target users who meet the criteria to have one of the Tenant Dial Plans applied to them. We are looking for users in NZ or AU only who are configured to use Teams Direct Routing.
Stage 4 - Conditionally apply a Tenant Dial Plan to each target user, as long as a). They don't already have an existing Tenant Dial Plan applied, b). Their phone number applies to one of the geograpic area codes that the Tenant Dial Plans cover.

At the end of the script there will also be a check of the voiceroutes for Australia to confirm that they will recognise Australian service numbers.

### Geographic Area Codes covered by these dial plans ###

## New Zealand geographic area codes ##
03 for the entire South Island and the Chatham Islands
04 for the Wellington metro area and Kapiti Coast district (excluding Otaki)
06 for Taranaki, Manawatū-Whanganui (excluding Taumarunui and National Park), Hawke's Bay, Gisborne, the Wairarapa, and Otaki.
07 for the Waikato (excluding Tuakau and Pokeno) and the Bay of Plenty
09 for Auckland, Northland, Tuakau and Pokeno.


## Australian geographic area codes ##
02 Geographic: Central East region (NSW, ACT)
03 Geographic: South-east region (VIC, TAS)
07 Geographic: North-east region (QLD)
08 Geographic: Central and West region (SA, NT, WA)


### Testing ###
Apply a tenant dial plan to a Teams user who already has teams calling:

## Example:

Grant-CsTenantDialPlan -Identity person@organization.co.nz -PolicyName TS-NZ-TDP-04 

#Then test the local number translation as follows:

#Input 8014640 the output should indicate that 8014640 has been translated to +6448014640 using the TS-NZ-NR-04 normalization rule
Get-CsEffectiveTenantDialPlan -Identity person@organization.co.nz | Test-CsEffectiveTenantDialPlan -DialedNumber 8014640

RunspaceId       : 
TranslatedNumber : +6448014640
MatchingRule     : Description=Wellington metro area and Kapiti Coast district;Pattern=^(\d{7})$;Translation=+644$1;Name=TS-NZ-NR-04;IsInternalExtension=False


#Input 048014640 the output should indicate that 048014640 has been translated to +6448014640 using the "New Zealand National" normalization rule from the built in NZ Dial Plan
Get-CsEffectiveTenantDialPlan -Identity person@organization.co.nz | Test-CsEffectiveTenantDialPlan -DialedNumber 048014640

RunspaceId       : 
TranslatedNumber : +6448014640
MatchingRule     : Description=NZ Long Distance Dialing Rule;Pattern=^0(\d+)$;Translation=+64$1;Name=NZ Long Distance;IsInternalExtension=False

#Input +6448014640 the output should indicate that there has been no translation
Get-CsEffectiveTenantDialPlan -Identity person@organization.co.nz | Test-CsEffectiveTenantDialPlan -DialedNumber 048014640

RunspaceId       : 
TranslatedNumber : 
MatchingRule     : 


#Then test the emergency number translation: Input 111 the output should indicae that 111 has been translated to +64111
Get-CsEffectiveTenantDialPlan -Identity person@organization.co.nz | Test-CsEffectiveTenantDialPlan -DialedNumber 111

RunspaceId       : 
TranslatedNumber : +64111
MatchingRule     : Description=Emergency number normalization for New Zealand;Pattern=^(111)$;Translation=+64111;Name=NZ Emergency Number;IsInternalExtension=False


#>


#### Script Mode to determine the behaviour of script ####

# default will configure new Tenant Dial Plan objects in the environment but not change users. It will output configuration commands to modify the users that can be examined copied and executed manually.
# yolo will make the changes to the environment but will not affect users that have already got some kind of tenant dial plan applied to them.

# Uncomment out the line below if you want this script to make changes to your environment.
# $scriptmode="yolo"
# Comment out the line below if you want this script to make changes to your environment.
$scriptmode="default"

#### Stage 1 ####
## defines the Normalization Rules for each geographical area in New Zealand ##
$NRNZEmergency = New-CsVoiceNormalizationRule -InMemory `
    -Parent "NZ"`
    -Name 'NZ Emergency Number' `
    -Pattern '^(111)$' `
    -Translation '+64111' `
    -Description "Emergency number normalization for New Zealand"

$NRNZ03 = New-CsVoiceNormalizationRule  -InMemory `
    -Parent "NZ"`
    -Name "TS-NZ-NR-03"`
    -Description "South Island and the Chatham Islands"`
    -Pattern "^(\d{7})$"`
    -Translation '+643$1'

$NRNZ04 = New-CsVoiceNormalizationRule -InMemory `
    -Parent "NZ"`
    -Name "TS-NZ-NR-04"`
    -Description  "Wellington metro area and Kapiti Coast district"`
    -Pattern "^(\d{7})$"`
    -Translation '+644$1'

$NRNZ06  = New-CsVoiceNormalizationRule -InMemory `
    -Parent "NZ"`
    -Name "TS-NZ-NR-06"`
    -Description "Taranaki, Manawatū-Whanganui"`
    -Pattern "^(\d{7})$"`
    -Translation '+646$1'

$NRNZ07  = New-CsVoiceNormalizationRule  -InMemory `
     -Parent "NZ"`
     -Name "TS-NZ-NR-07"`
     -Description "The Waikato"`
     -Pattern "^(\d{7})$"`
     -Translation '+647$1'

$NRNZ09  = New-CsVoiceNormalizationRule -InMemory `
     -Parent "NZ"`
     -Name "TS-NZ-NR-09"`
     -Description "Auckland, Northland, Tuakau and Pokeno."`
     -Pattern "^(\d{7})$"`
     -Translation '+649$1'

## defines the Normalization Rules for each geographical area in Australia ##
$NRAUEmergency = New-CsVoiceNormalizationRule -InMemory `
    -Parent "AU"`
    -Name 'AUEmergency'`
    -Pattern '^(000|112)$' `
    -Translation '+61000'`
    -Description "Emergency number normalization for Australia"

$NRAU02 = New-CsVoiceNormalizationRule -InMemory `
     -Parent "AU"`
     -Name  "TS-AU-NR-02"`
     -Description  "Central East region (NSW, ACT)"`
     -Pattern  "^([2-9]\d{7})$"`
     -Translation  '+612$1'

$NRAU03 = New-CsVoiceNormalizationRule -InMemory `
     -Parent "AU"`
     -Name  "TS-AU-NR-03"`
     -Description  "South-east region (VIC, TAS)"`
     -Pattern  "^([2-9]\d{7})$"`
     -Translation  '+613$1'

$NRAU07 = New-CsVoiceNormalizationRule -InMemory `
     -Parent "AU"`
     -Name  "TS-AU-NR-07"`
     -Description  "North-east region (QLD)"`
     -Pattern  "^([2-9]\d{7})$"`
     -Translation  '+617$1'

$NRAU08 = New-CsVoiceNormalizationRule -InMemory `
     -Parent "AU"`
     -Name  "TS-AU-NR-08"`
     -Description  "Central and West region (SA, NT, WA)"`
     -Pattern  "^([2-9]\d{7})$"`
     -Translation  '+618$1'


#### Stage 2 ####
## Create the TenantDialPlan for each geographical area in New Zealand and add the Normalization rules for that area. First check if the tenant dial plan already exists. ##
If((Get-CsTenantDialPlan "TS-NZ-TDP-03") 2>$null){
        Write-Host "# TS-NZ-TDP-03 Already exists, skipping"  -ForegroundColor Blue

    }else{
        write-host "# Creating Tenant Dial Plan TS-NZ-TDP-03"  -ForegroundColor DarkGreen
        New-CsTenantDialPlan -Identity "TS-NZ-TDP-03" -Description "Tenant Dial Plan for New Zealand: South Island and the Chatham Islands" -NormalizationRules @{add=$NRNZ03, $NRNZEmergency}
}

If((Get-CsTenantDialPlan "TS-NZ-TDP-04") 2>$null){
        write-host "# TS-NZ-TDP-04 Already exists, skipping"  -ForegroundColor Blue

    }else{
        write-host "# Creating Tenant Dial Plan TS-NZ-TDP-04"  -ForegroundColor DarkGreen
        New-CsTenantDialPlan -Identity "TS-NZ-TDP-04" -Description "Tenant Dial Plan for New Zealand: Wellington metro area and Kapiti Coast district" -NormalizationRules @{add=$NRNZ04, $NRNZEmergency}
}
If((Get-CsTenantDialPlan "TS-NZ-TDP-06" ) 2>$null){
        write-host "# TS-NZ-TDP-06 Already exists, skipping"  -ForegroundColor Blue

    }else{
        write-host "# Creating Tenant Dial Plan TS-NZ-TDP-06"  -ForegroundColor DarkGreen
        New-CsTenantDialPlan -Identity "TS-NZ-TDP-06" -Description "Tenant Dial Plan for New Zealand: Taranaki, Manawatū-Whanganui" -NormalizationRules @{add=$NRNZ06, $NRNZEmergency}
}
If((Get-CsTenantDialPlan "TS-NZ-TDP-07") 2>$null){
        write-host "# TS-NZ-TDP-07 Already exists, skipping"  -ForegroundColor Blue

    }else{
        write-host "# Creating Tenant Dial Plan TS-NZ-TDP-07"  -ForegroundColor DarkGreen
        New-CsTenantDialPlan -Identity "TS-NZ-TDP-07" -Description "Tenant Dial Plan for New Zealand: The Waikato" -NormalizationRules @{add=$NRNZ07, $NRNZEmergency}
}
If((Get-CsTenantDialPlan "TS-NZ-TDP-09") 2>$null){
        write-host "# TS-NZ-TDP-09 Already exists, skipping"  -ForegroundColor Blue

    }else{
        write-host "# Creating Tenant Dial Plan TS-NZ-TDP-09" -ForegroundColor DarkGreen
        New-CsTenantDialPlan -Identity "TS-NZ-TDP-09" -Description "Tenant Dial Plan for New Zealand: Auckland, Northland, Tuakau and Pokeno." -NormalizationRules @{add=$NRNZ09, $NRNZEmergency}
}

## Create the TenantDialPlan for each geographical area in Australia and add the Normalization rules for that area. First check if the tenant dial plan already exists. ##

If((Get-CsTenantDialPlan "TS-AU-TDP-02") 2>$null){
        write-host "# TS-AU-TDP-02 Already exists, skipping" -ForegroundColor Blue

    }else{
        write-host "# Creating Tenant Dial Plan TS-AU-TDP-02" -ForegroundColor DarkGreen
        New-CsTenantDialPlan -Identity "TS-AU-TDP-02" -Description "Tenant Dial Plan for Australia: Central East region (NSW, ACT)" -NormalizationRules @{add=$NRAU02, $NRAUEmergency}
}
If((Get-CsTenantDialPlan "TS-AU-TDP-03") 2>$null){
        write-host "# TS-AU-TDP-03 Already exists, skipping"  -ForegroundColor Blue

    }else{
        write-host "# Creating Tenant Dial Plan TS-AU-TDP-03"  -ForegroundColor DarkGreen
        New-CsTenantDialPlan -Identity "TS-AU-TDP-03" -Description "Tenant Dial Plan for Australia: South-east region (VIC, TAS)"  -NormalizationRules @{add=$NRAU03, $NRAUEmergency}
}
If((Get-CsTenantDialPlan "TS-AU-TDP-07") 2>$null){
        write-host "# TS-AU-TDP-07 Already exists, skipping"  -ForegroundColor Blue

    }else{
        write-host "# Creating Tenant Dial Plan TS-AU-TDP-07"  -ForegroundColor DarkGreen
        New-CsTenantDialPlan -Identity "TS-AU-TDP-07" -Description "Tenant Dial Plan for Australia: North-east region (QLD)"  -NormalizationRules @{add=$NRAU07, $NRAUEmergency}
}
If((Get-CsTenantDialPlan "TS-AU-TDP-08") 2>$null){
        write-host "# TS-AU-TDP-08 Already exists, skipping"  -ForegroundColor Blue

    }else{
        write-host "# Creating Tenant Dial Plan TS-AU-TDP-08" -ForegroundColor DarkGreen
        New-CsTenantDialPlan -Identity "TS-AU-TDP-08" -Description "Tenant Dial Plan for Australia: Central and West region (SA, NT, WA)"  -NormalizationRules @{add=$NRAU08, $NRAUEmergency}
}


#### Stage 3 ####
# Get a list of target users who meet the criteria for a Tenant Dial Plan #
$TargetUsers = Get-CsOnlineUser | Where-Object {$_.OnlineVoiceRoutingPolicy -match "^TS-" -and $_.EnterpriseVoiceEnabled -eq $true -and $_.OnPremLineURI -ne "" -and $_.UsageLocation -match "^(NZ)|(AU)$"} 
Write-Host "#### The following users will be considered for a Tenant Dial Plan ####" -ForegroundColor Yellow
$TargetUsers | Select-Object -Property UserPrincipalName, OnPremLineURI, EnterpriseVoiceEnabled, HostedVoiceMail, OnlineVoiceRoutingPolicy, DialPlan, TenantDialPlan, TeamsCallingPolicy | ft


#### Stage 4 ####
# Loop through the target users and check that they don't already have a TenantDialPlan, if they don't then look at the first three digits of their DID number and apply the relevant plan. #

Switch($scriptmode){
    "yolo" {
        Write-Host "### I am totally going to run Grant-CsTenantDialPlan on each user that meets the crteria ###" -ForegroundColor Yellow
    }
    Default{
        Write-Host "### This script will not made any changes to users, to apply the changes please copy the lines below and execute them ###" -ForegroundColor Cyan
    }
}

ForEach($User in $TargetUsers){
    $TenantDialPlan = $null
    Switch ($User.TenantDialPlan){
        $null {
            Switch (((($User.OnPremLineURI).Split("+")[1]).Split(";")[0]).Substring(0,3)){
                "643"{
                    $TenantDialPlan = "TS-NZ-TDP-03"
                }
                "644"{
                    $TenantDialPlan = "TS-NZ-TDP-04"
                }
                "646"{
                    $TenantDialPlan = "TS-NZ-TDP-06"
                }
                "647"{
                    $TenantDialPlan = "TS-NZ-TDP-07"
                }
                "649"{
                    $TenantDialPlan = "TS-NZ-TDP-09"
                }
                "612"{
                    $TenantDialPlan = "TS-AU-TDP-02"
                }
                "613"{
                    $TenantDialPlan = "TS-AU-TDP-03"
                }
                "617"{
                    $TenantDialPlan = "TS-AU-TDP-07"
                }
                "618"{
                    $TenantDialPlan = "TS-AU-TDP-08"
                }
                Default{
                    Write-Host "# " $user.UserPrincipalName  " Has this phone number " $user.OnPremLineURI  "Which is not covered by one of our tenant dial plans" -ForegroundColor Magenta
                }
            }
            If($TenantDialPlan){
                
                
                Switch($scriptmode){
                    "yolo" {
                        write-host "# " $user.UserPrincipalName " With URI " $user.OnPremLineURI " will now have Tenant Dial Plan "$TenantDialPlan "Applied" -ForegroundColor Yellow
                        Grant-CsTenantDialPlan -Identity"$user.UserPrincipalName"-PolicyName $TenantDialPlan
                    }
                    Default{
                        write-host "# " $user.UserPrincipalName " With URI " $user.OnPremLineURI " Run the command below to have Tenant Dial Plan "$TenantDialPlan "Applied" -ForegroundColor DarkGreen
                        write-host "Grant-CsTenantDialPlan -Identity"$user.UserPrincipalName"-PolicyName $TenantDialPlan"
                    }
                }
            }
        }
        Default {
            Write-Host "# " $user.UserPrincipalName " Is already configured with TenantDialPlan "  $user.TenantDialPlan "Uncomment the line below to apply the suggested Dial Plan anyway" -ForegroundColor Magenta
            write-host "# Grant-CsTenantDialPlan -Identity"$user.UserPrincipalName"-PolicyName $TenantDialPlan" -ForegroundColor DarkGreen
        }
    }
}
Switch($scriptmode){
    "yolo" {
        Write-Host "### Commands were run, please examine the output above for any problems ###" -ForegroundColor Yellow
        
    }
    Default{
        Write-Host "### This script has not made any changes to users, to apply the changes please copy the lines above and execute them ###" -ForegroundColor Cyan
    }
}

. $PSScriptRoot\patch-AuVoiceRoute.ps1

### The End ###