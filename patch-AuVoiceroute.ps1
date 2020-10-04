##### Patch Austraila Service Voice Route #####
<#
Latest update: 25th September 2020
Author: David Alderman, Telesmart Limited, New Zealand

### Synopsis ###
The purpose of this script is to confirm that the the voice route for service numbers in Australia is correct.
There are historical deployments where there was a typographical error in the regex string which would result in service numbers not matching and therefore would not route.
The correct string is:
"^\+61(000|1[0125]\d{1,8})$"
This will match the following patterns:
000
Any number up to 10 digits long beginning 10, 11, 12, 15
The service number pattern does not include toll free numbers beginning 1800 and 1300, these are handled by a different rule for toll free numbers.


## Change Log ##
25th September 2020 - Published to Production
18th September 2020 - Initial Release.


### Naming Conventions used ###
The elements amended have the following naming conventions

TS-$cc-$type-[Route]

The element will always be prefixed with TS
$cc = Country Code and will be either NZ or AU and applies to the territory that will consume the element.
$type = the type of element which in this script is always "Service"
[Route] = This specifies that the element is a route, historically this suffix may not have been appied but was added more recently to make reading confguration by eye easier. The script will identify either with or without the suffix.

## Script Settings ##
Set the variables at the top of the script

"default" (or any other value) will configure new Tenant Dial Plan objects in the environment but not change users. It will output configuration commands to modify the users that can be examined copied and executed manually.
"yolo" (exactly this value) will make the changes to the environment but will *not* affect users that have already got some kind of tenant dial plan applied to them.

$scriptmode=default
$scriptmode=yolo


### Execution Plan ###
There are 3 stages to this script.
Stage 1 - Define the variables
Stage 2 - Identify potentially affected voice routes
Stage 3 - Update the service route, this will either output the commands to be run manually which will update the route, or optionally run the commands if the script is in "yolo" mode.


#>

#### Script Mode to determine the behaviour of this script ####

# default will output configuration commands to modify the affected voice route(s) so that they can be examined, copied and executed manually.
# yolo will make changes to the environment without intervention.

#$scriptmode="yolo"
# Comment out the line below if you want this script to make changes to your environment.
#$scriptmode="default"


## Stage 1 - Define the variables used later ###
$timestamp = Get-Date -Format o | ForEach-Object { $_ -replace ":", "." }

$AUServicePattern = "^\+61(000|1[0125]\d{1,8})$" # This string is the current best version, if the existing string doesnt match then it will be updated to look like this.
$AUServiceDescription = "Service routing for Australia Dial String Version: 1.2"

## Stage 2 - Identify potenially affected voice routes ##

$AffectedRoutes = Get-CsOnlineVoiceRoute | Where-Object {$_.Identity -match "^TS-AU-Service"}

## Stage 3 - Update the service route(s) ##

#First check if there are any affected routes and bale out if none found.
If ($AffectedRoutes.Count -eq 0) {
    Write-Host "There were no affected routes found" -ForegroundColor Magenta
}else{
     # Output a message about whether or not the commands will execute or only be displayed.  
    Switch($ScriptMode){
        "yolo" {
            Write-Host "## yolo mode engaged, changes will be applied ##`n" -ForegroundColor Yellow
                        
        }
        Default {
            Write-Host "## default mode, commands will be output but not executed ##`n" -ForegroundColor DarkGreen
            
            
        }
    }
    #Step through each affected voice route and determine if it has the correct regex pattern as defined in $AUServicePattern
    ForEach ($Route in $AffectedRoutes){
        $Identity = $route.Identity
        Switch($Route.NumberPattern){
            $AUServicePattern { ## The NumberPattern matches $AUServicePattern
                $color = "Green"
                $message = "## $Identity Looks OK, Run the command below to timestamp the description with this audit"
                $command = "Set-CsOnlineVoiceRoute -Identity $Identity -Description `"$AUServiceDescription  Audited: $timestamp`""
            
            }
            Default { ## The NumberPattern does not match $AUServicePattern
                $color = "Yellow"
                $message = "## $Identity Looks wrong, Run the command below to update it to the correct string"
                $command = "Set-CsOnlineVoiceRoute -Identity $Identity -NumberPattern '$AUServicePattern' -Description `"$AUServiceDescription Updated: $timestamp`""
            
            }
        }
        #Either output the commands or invoke them to make changes depending on the value of $ScriptMode
        Switch($ScriptMode){
            "yolo" {
                Write-Host $message -ForegroundColor Yellow
                Invoke-Expression $command
            
            }
            Default {
                Write-Host $message -ForegroundColor $color
                write-host $command
            
            }
        }          
    }
}


### Finished ###