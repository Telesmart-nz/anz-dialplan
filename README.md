# anz-dialplan
Basic tenant dial plans to use with Telesmart Cloud Calling for Microsoft Teams in Australia/New Zealand including Emergency Calls and local number dialing without area code.

# Patch Tenant Dial Plans #

Latest update: 5th October 2020

Author: David Alderman, Telesmart Limited, New Zealand

## Synopsis ##
The purpose of this script is to create tenant dial plans for each geographical area code in New Zealand and Austrlia
The tenant dial plan will allow Microsoft Teams to:
1. Recognize local phone numbers dialed by the user and convert them to e.164
2. Recognize the emergency number and convert it to e.164

## Change Log ##
- 5th October 2020 - Published to Github / telesmart-nz/anz-dialplan
- 25th September 2020 - Published to Production
- 17th September 2020 - Initial Release.

# Naming Conventions used #
The elements created have a naming convention as follows

TS-$cc-$type-$area

The element will always be prefixed with TS
$cc = Country Code and will be either NZ or AU and applies to the territory that will consume the element.
$type = the type of element which will be either NR=Normalization RUle or TDP=Tenant Dial Plan
$area = The geographic area code within the country covered by the element. See below for a list of geographic area codes in each country.

# Script Settings #
Set the variables at the top of the script

- "default" (or any other value) will configure new Tenant Dial Plan objects in the environment but not change users. It will output configuration commands to modify the users that can be examined copied and executed manually.
- "yolo" (exactly this value) will make the changes to the environment but will *not* affect users that have already got some kind of tenant dial plan applied to them.
```
$scriptmode=default
$scriptmode=yolo
```
# Execution Plan #

There are 4 stages to this script.
- Stage 1 - Define 11 Normalization rule to cover each geographic area code and emergency number for New Zealand and Australia. These Normalization rules are ephemeral and will only be defined within the script, they are later applied to a Tenant Dial Plan which will be created on the Tenant.
- Stage 2 - Identify if there already existing Tenant Dial plans using the same names we plan to use. This step will create a new Tenant Dial Plan for each geographic area if it doesnt already exist.
- Stage 3 - Identify a list of target users who meet the criteria to have one of the Tenant Dial Plans applied to them. We are looking for users in NZ or AU only who are configured to use Teams Direct Routing.
- Stage 4 - Conditionally apply a Tenant Dial Plan to each target user, as long as a). They don't already have an existing Tenant Dial Plan applied, b). Their phone number applies to one of the geograpic area codes that the Tenant Dial Plans cover.

At the end, the script there will call ./patch-AuVoiceRoute.ps1 which will check of the voiceroutes for Australia this will confirm that they will recognise Australian service numbers, in some older deployments of Cloud Calling for Microsoft Teams there was an error in the voice route which could result in calls to service numbers failing. 

# How to use this script #

- Clone the repository to your local computer.
- Open patch-TenantDialPlans.ps1 in PowerShell ISE. 
- Use New-CsOnlineSession and import-PSSession to connect to SkypeOnline
- run patch-TenantDialPlans.ps1 top to bottom

The script will create the Tenant Dial Plans if they don't exist.
The script will skip creating the Tenant Dial plans if they already exist.

The script will locate user accounts that are configured with calling in Australian or New Zealand. It will output commands that can be run to apply a tenant dial plan to each user. If a user already has a tenant dial plan, then the command to update them to the suggested dial plan will be output.

# Geographic Area Codes covered by these dial plans #

## New Zealand geographic area codes ##
- 03 for the entire South Island and the Chatham Islands
- 04 for the Wellington metro area and Kapiti Coast district (excluding Otaki)
- 06 for Taranaki, Manawatū-Whanganui (excluding Taumarunui and National Park), Hawke's Bay, Gisborne, the Wairarapa, and Otaki.
- 07 for the Waikato (excluding Tuakau and Pokeno) and the Bay of Plenty
- 09 for Auckland, Northland, Tuakau and Pokeno.


## Australian geographic area codes ##
- 02 Geographic: Central East region (NSW, ACT)
- 03 Geographic: South-east region (VIC, TAS)
- 07 Geographic: North-east region (QLD)
- 08 Geographic: Central and West region (SA, NT, WA)


### Testing ###
Apply a tenant dial plan to a Teams user who already has teams calling:

## Example: ##
```
Grant-CsTenantDialPlan -Identity person@organization.co.nz -PolicyName TS-NZ-TDP-04 
```
  Then test the local number translation as follows:

  #Input 8014640 the output should indicate that 8014640 has been translated to +6448014640 using the TS-NZ-NR-04 normalization rule
```
Get-CsEffectiveTenantDialPlan -Identity person@organization.co.nz | Test-CsEffectiveTenantDialPlan -DialedNumber 8014640
```
```
  RunspaceId       : 

  TranslatedNumber : +6448014640
  
  MatchingRule     : Description=Wellington metro area and Kapiti Coast district;Pattern=^(\d{7})$;Translation=+644$1;Name=TS-NZ-NR-04;IsInternalExtension=False
```

  #Input 048014640 the output should indicate that 048014640 has been translated to +6448014640 using the "New Zealand National" normalization rule from the built in NZ Dial Plan
```
Get-CsEffectiveTenantDialPlan -Identity person@organization.co.nz | Test-CsEffectiveTenantDialPlan -DialedNumber 048014640
```
```
  RunspaceId       : 

  TranslatedNumber : +6448014640

  MatchingRule     : Description=NZ Long Distance Dialing Rule;Pattern=^0(\d+)$;Translation=+64$1;Name=NZ Long Distance;IsInternalExtension=False
```

  #Input +6448014640 the output should indicate that there has been no translation
```
Get-CsEffectiveTenantDialPlan -Identity person@organization.co.nz | Test-CsEffectiveTenantDialPlan -DialedNumber 048014640
```
```
  RunspaceId       : 

  TranslatedNumber : 

  MatchingRule     : 
```
  #Then test the emergency number translation: Input 111 the output should indicae that 111 has been translated to +64111
```
Get-CsEffectiveTenantDialPlan -Identity person@organization.co.nz | Test-CsEffectiveTenantDialPlan -DialedNumber 111
```
```
  RunspaceId       : 

  TranslatedNumber : +64111

  MatchingRule     : Description=Emergency number normalization for New Zealand;Pattern=^(111)$;Translation=+64111;Name=NZ Emergency Number;IsInternalExtension=False
```

