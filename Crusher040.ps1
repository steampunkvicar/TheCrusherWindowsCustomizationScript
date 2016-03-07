<# 

.SYNOPSIS

### THE CRUSHER v0.40###

Powershell script for imaging PCs at Beverly Hospital. v0.40



.DESCRIPTION

We are, regrettably, still on PS2.0, which is not terribly helpful. Even so, here's a 
shot at streamlining our process. This script automates a number of steps from Chrissy 
Knowles' checklist:
	* Sets the Windows Update Service to start automatically
	* Enables password required on recovery from standby
	* Turn off all sleep modes and disable disk shutdown
	* Add the Run Command to the Start Menu for this user and all new users
	* Disables Windows Search and Remote Differential Compression
	* Disables integrations in GroupWise for this user and all new users
	* !Disables IPv6 - we're not doing this anymore, but I left the code in place down there. 
	* Restarts the computer
	
.PARAMETER

There are no parameters. Sorry.


.NOTES

I added some code to force no restarts for DISM - v0.38
Reworked the order of events to allow for editing of default user profiles for Run on Start Menu and Groupwise Integration Disabling - v0.39
Added yet more to allow for disabling Groupwise Integrations and adding Start Menu Run on default profiles. - v0.40


 
In order to run this script on our images, you'll need to set an Execution Policy (we
don't like scripts in Group Policy, apparently). In Powershell, navigate to the directory
containing this script. Then type

Set-ExecutionPolicy Unrestricted -Force

Then, run the script by typing:

.\Crusher040.ps1

Good luck, Starfighter!#>

# Automatically Start Windows Update on Reboot

Set-Service wuauserv -startuptype automatic

# Disable IPv6 - NO LONGER NEEDED!

#New-Item 'HKLM:\SYSTEM\CurrentControlSet\services\TCPIP6\Parameters' -Name 'DisabledComponents' -ItemType 'file'
#New-ItemProperty 'HKLM:\SYSTEM\CurrentControlSet\services\TCPIP6\Parameters' -Name 'DisabledComponents' -Value '0xff' -PropertyType 'DWord'

# Enable Require Password on Standby, disable Hibernation and other sleep modes

powercfg -h off 
powercfg -SETACVALUEINDEX SCHEME_BALANCED SUB_NONE CONSOLELOCK 1
powercfg -SETDCVALUEINDEX SCHEME_BALANCED SUB_NONE CONSOLELOCK 1
powercfg -SETACVALUEINDEX scheme_balanced sub_sleep hybridsleep 0
powercfg -SETDCVALUEINDEX scheme_balanced sub_sleep hybridsleep 0
powercfg -setacvalueindex scheme_balanced sub_disk diskidle 0
powercfg -setdcvalueindex scheme_balanced sub_disk diskidle 0

# Disable Windows Search and Remote Differential Compression

dism /online /disable-feature /FeatureName:SearchEngine-Client-Package /norestart
dism /online /disable-feature /FeatureName:MSRDC-Infrastructure /norestart

# Registry Edits
	# Load the default user profile registry
	$ntuserlocation = "c:\users\Default\ntuser.dat"
	reg load 'HKLM\ntuser' $ntuserlocation

	# Creating path to Groupwise Integrations for new users
	new-item -path hklm:\ntuser\Software\Novell 
	new-item -path hklm:\ntuser\Software\Novell\GroupWise 
	new-item -path hklm:\ntuser\Software\Novell\GroupWise\Client 
	new-item -path hklm:\ntuser\Software\Novell\GroupWise\Client\Library

	# Creating path to Start Menu for new users
	new-item -path hklm:\ntuser\Software
	new-item -path hklm:\ntuser\Software\Microsoft
	new-item -path hklm:\ntuser\Software\Microsoft\Windows
	new-item -path hklm:\ntuser\Software\Microsoft\Windows\CurrentVersion
	new-item -path hklm:\ntuser\Software\Microsoft\Windows\CurrentVersion\Policies
	new-item -path hklm:\ntuser\Software\Microsoft\Windows\CurrentVersion\Policies\Explorer

	# Creating path to Groupwise Integrations for current user
	new-item -path hkcu:\Software\Novell 
	new-item -path hkcu:\Software\Novell\GroupWise 
	new-item -path hkcu:\Software\Novell\GroupWise\Client 
	new-item -path hkcu:\Software\Novell\GroupWise\Client\Library
    
    # Creating path to Add Run Command to Start Menu for new users
    new-item -path hklm:\ntuser\Software
    new-item -path hklm:\ntuser\Software\Microsoft
    new-item -path hklm:\ntuser\Software\Microsoft\Windows
    new-item -path hklm:\ntuser\Software\Microsoft\Windows\CurrentVersion
    new-item -path hklm:\ntuser\Software\Microsoft\Windows\CurrentVersion\Policies
    new-item -path hklm:\ntuser\Software\Microsoft\Windows\CurrentVersion\Policies\Explorer

	# Disabling Groupwise Integrations for current and new users
	new-itemproperty -path HKCU:\Software\Novell\Groupwise\Client\Library\ -name Integrations -propertytype string -value Disabled
	new-itemproperty -path hklm:\ntuser\Software\Novell\Groupwise\Client\Library\ -name Integrations -propertytype string -value Disabled

	# Add Run command to Start Menu
	New-ItemProperty -Path HKCU:\Software\Microsoft\Windows\CurrentVersion\Policies\Explorer -Name ForceRunOnStartMenu -Value '0x00000001' -PropertyType 'DWord'
	New-ItemProperty -Path hklm:\ntuser\Software\Microsoft\Windows\CurrentVersion\Policies\Explorer -Name ForceRunOnStartMenu -Value '0x00000001' -PropertyType 'DWord'

	# Unload that registry I just talked about
	# I get the sense that this doesn't work...either it or the command after it throws an error, but it still does the restart, so who knows. 
	reg unload 'HKLM\ntuser'

# Return the Execution Policy to Undefined
Set-ExecutionPolicy Undefined -Force

# Restart the PC
Restart-Computer