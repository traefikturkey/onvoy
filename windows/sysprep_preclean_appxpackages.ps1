# VirtuallyInclined.com 2018
# From https://virtuallyinclined.com/2018/02/10/windows-10-appx-removal-script-update/
# updated 3/10/2023 by ilude
# You may have to manually uninstall some Sponsored Apps from the Start Menu.
# This has been tested on Windows 10 Enterprise 1703 and 1709.

# This is the long version of this script with each command explicitly defined.

Import-Module AppX
Import-Module Dism

# Use "#" to comment out apps you don't want to remove.
# You must comment out both commands for each app.  
# The Remove-AppxPackage and Remove-AppXProvisionedPackage must both be commented out.

#Remove AppX Packages for unnecessary Windows 10 AppX Apps
Get-AppxPackage -Allusers *Microsoft.BingNews* | Remove-AppxPackage -Allusers
Get-AppxPackage -Allusers *Microsoft.DesktopAppInstaller* | Remove-AppxPackage -Allusers
Get-AppxPackage -Allusers *Microsoft.GetHelp* | Remove-AppxPackage -Allusers
Get-AppxPackage -Allusers *Microsoft.Getstarted* | Remove-AppxPackage -Allusers
Get-AppxPackage -Allusers *Microsoft.Messaging* | Remove-AppxPackage -Allusers
Get-AppxPackage -Allusers *Microsoft.Microsoft3DViewer* | Remove-AppxPackage -Allusers
Get-AppxPackage -Allusers *Microsoft.MicrosoftOfficeHub* | Remove-AppxPackage -Allusers
Get-AppxPackage -Allusers *Microsoft.MicrosoftSolitaireCollection* | Remove-AppxPackage -Allusers
Get-AppxPackage -Allusers *Microsoft.NetworkSpeedTest* | Remove-AppxPackage -Allusers
Get-AppxPackage -Allusers *Microsoft.Office.OneNote* | Remove-AppxPackage -Allusers
Get-AppxPackage -Allusers *Microsoft.Office.Sway* | Remove-AppxPackage -Allusers
Get-AppxPackage -Allusers *Microsoft.OneConnect* | Remove-AppxPackage -Allusers
Get-AppxPackage -Allusers *Microsoft.People* | Remove-AppxPackage -Allusers
Get-AppxPackage -Allusers *Microsoft.Print3D* | Remove-AppxPackage -Allusers
Get-AppxPackage -Allusers *Microsoft.RemoteDesktop* | Remove-AppxPackage -Allusers
Get-AppxPackage -Allusers *Microsoft.SkypeApp* | Remove-AppxPackage -Allusers
Get-AppxPackage -Allusers *Microsoft.StorePurchaseApp* | Remove-AppxPackage -Allusers
Get-AppxPackage -Allusers *Microsoft.WindowsAlarms* | Remove-AppxPackage -Allusers
Get-AppxPackage -Allusers *Microsoft.WindowsCamera* | Remove-AppxPackage -Allusers
Get-AppxPackage -Allusers *microsoft.windowscommunicationsapps* | Remove-AppxPackage -Allusers
Get-AppxPackage -Allusers *Microsoft.WindowsFeedbackHub* | Remove-AppxPackage -Allusers
Get-AppxPackage -Allusers *Microsoft.WindowsMaps* | Remove-AppxPackage -Allusers
Get-AppxPackage -Allusers *Microsoft.WindowsSoundRecorder* | Remove-AppxPackage -Allusers
Get-AppxPackage -Allusers *Microsoft.Xbox.TCUI* | Remove-AppxPackage -Allusers
Get-AppxPackage -Allusers *Microsoft.XboxApp* | Remove-AppxPackage -Allusers
Get-AppxPackage -Allusers *Microsoft.XboxGameOverlay* | Remove-AppxPackage -Allusers
Get-AppxPackage -Allusers *Microsoft.XboxIdentityProvider* | Remove-AppxPackage -Allusers
Get-AppxPackage -Allusers *Microsoft.XboxSpeechToTextOverlay* | Remove-AppxPackage -Allusers
Get-AppxPackage -Allusers *Microsoft.ZuneMusic* | Remove-AppxPackage -Allusers
Get-AppxPackage -Allusers *Microsoft.ZuneVideo* | Remove-AppxPackage -Allusers

#Remove AppX Packages for Sponsored Windows 10 AppX Apps
Get-AppxPackage -Allusers *EclipseManager* | Remove-AppxPackage -Allusers
Get-AppxPackage -Allusers *ActiproSoftwareLLC* | Remove-AppxPackage -Allusers
Get-AppxPackage -Allusers *AdobeSystemsIncorporated.AdobePhotoshopExpress* | Remove-AppxPackage -Allusers
Get-AppxPackage -Allusers *Duolingo-LearnLanguagesforFree* | Remove-AppxPackage -Allusers
Get-AppxPackage -Allusers *PandoraMediaInc* | Remove-AppxPackage -Allusers
Get-AppxPackage -Allusers *CandyCrush* | Remove-AppxPackage -Allusers
Get-AppxPackage -Allusers *Wunderlist* | Remove-AppxPackage -Allusers
Get-AppxPackage -Allusers *Flipboard* | Remove-AppxPackage -Allusers
Get-AppxPackage -Allusers *Twitter* | Remove-AppxPackage -Allusers
Get-AppxPackage -Allusers *Facebook* | Remove-AppxPackage -Allusers
Get-AppxPackage -Allusers *Spotify* | Remove-AppxPackage -Allusers
Get-AppxPackage -Allusers *Disney* | Remove-AppxPackage -Allusers


Get-AppxProvisionedPackage -Online | where Displayname -EQ "EclipseManager" | Remove-AppxProvisionedPackage -Online -Allusers
Get-AppxProvisionedPackage -Online | where Displayname -EQ "ActiproSoftwareLLC" | Remove-AppxProvisionedPackage -Online -Allusers
Get-AppxProvisionedPackage -Online | where Displayname -EQ "AdobeSystemsIncorporated.AdobePhotoshopExpress" | Remove-AppxProvisionedPackage -Online -Allusers
Get-AppxProvisionedPackage -Online | where Displayname -EQ "Duolingo-LearnLanguagesforFree" | Remove-AppxProvisionedPackage -Online -Allusers
Get-AppxProvisionedPackage -Online | where Displayname -EQ "PandoraMediaInc" | Remove-AppxProvisionedPackage -Online -Allusers
Get-AppxProvisionedPackage -Online | where Displayname -EQ "CandyCrush" | Remove-AppxProvisionedPackage -Online -Allusers
Get-AppxProvisionedPackage -Online | where Displayname -EQ "Wunderlist" | Remove-AppxProvisionedPackage -Online -Allusers
Get-AppxProvisionedPackage -Online | where Displayname -EQ "Flipboard" | Remove-AppxProvisionedPackage -Online -Allusers
Get-AppxProvisionedPackage -Online | where Displayname -EQ "Twitter" | Remove-AppxProvisionedPackage -Online -Allusers
Get-AppxProvisionedPackage -Online | where Displayname -EQ "Facebook" | Remove-AppxProvisionedPackage -Online -Allusers
Get-AppxProvisionedPackage -Online | where Displayname -EQ "Spotify" | Remove-AppxProvisionedPackage -Online -Allusers
Get-AppxProvisionedPackage -Online | where Displayname -EQ "Disney" | Remove-AppxProvisionedPackage -Online -Allusers

#Optional: Typically not removed but you can if you need to for some reason
#Get-AppxPackage -Allusers *Microsoft.Advertising.Xaml_10.1712.5.0_x64__8wekyb3d8bbwe* | Remove-AppxPackage -Allusers
#Get-AppxPackage -Allusers *Microsoft.Advertising.Xaml_10.1712.5.0_x86__8wekyb3d8bbwe* | Remove-AppxPackage -Allusers
#Get-AppxPackage -Allusers *Microsoft.BingWeather* | Remove-AppxPackage -Allusers
#Get-AppxPackage -Allusers *Microsoft.MSPaint* | Remove-AppxPackage -Allusers
#Get-AppxPackage -Allusers *Microsoft.MicrosoftStickyNotes* | Remove-AppxPackage -Allusers
#Get-AppxPackage -Allusers *Microsoft.Windows.Photos* | Remove-AppxPackage -Allusers
#Get-AppxPackage -Allusers *Microsoft.WindowsCalculator* | Remove-AppxPackage -Allusers
#Get-AppxPackage -Allusers *Microsoft.WindowsStore* | Remove-AppxPackage -Allusers



#Use "#" to comment out apps you don't want to remove.
#You must comment out both commands for each app.
#The Remove-AppxPackage -Allusers and Remove-AppXProvisionedPackage must both be commented out.

#Remove AppX Provisioning for unnecessary Windows 10 AppX apps
Get-AppxProvisionedPackage -Online | where Displayname -EQ "Microsoft.DesktopAppInstaller" | Remove-AppxProvisionedPackage -Online -Allusers
Get-AppxProvisionedPackage -Online | where Displayname -EQ "Microsoft.GetHelp" | Remove-AppxProvisionedPackage -Online -Allusers
Get-AppxProvisionedPackage -Online | where Displayname -EQ "Microsoft.Getstarted" | Remove-AppxProvisionedPackage -Online -Allusers
Get-AppxProvisionedPackage -Online | where Displayname -EQ "Microsoft.Messaging" | Remove-AppxProvisionedPackage -Online -Allusers
Get-AppxProvisionedPackage -Online | where Displayname -EQ "Microsoft.Microsoft3DViewer" | Remove-AppxProvisionedPackage -Online -Allusers
Get-AppxProvisionedPackage -Online | where Displayname -EQ "Microsoft.MicrosoftOfficeHub" | Remove-AppxProvisionedPackage -Online -Allusers
Get-AppxProvisionedPackage -Online | where Displayname -EQ "Microsoft.MicrosoftSolitaireCollection" | Remove-AppxProvisionedPackage -Online -Allusers
Get-AppxProvisionedPackage -Online | where Displayname -EQ "Microsoft.Office.OneNote" | Remove-AppxProvisionedPackage -Online -Allusers
Get-AppxProvisionedPackage -Online | where Displayname -EQ "Microsoft.OneConnect" | Remove-AppxProvisionedPackage -Online -Allusers
Get-AppxProvisionedPackage -Online | where Displayname -EQ "Microsoft.People" | Remove-AppxProvisionedPackage -Online -Allusers
Get-AppxProvisionedPackage -Online | where Displayname -EQ "Microsoft.Print3D" | Remove-AppxProvisionedPackage -Online -Allusers
Get-AppxProvisionedPackage -Online | where Displayname -EQ "Microsoft.SkypeApp" | Remove-AppxProvisionedPackage -Online -Allusers
Get-AppxProvisionedPackage -Online | where Displayname -EQ "Microsoft.StorePurchaseApp" | Remove-AppxProvisionedPackage -Online -Allusers
Get-AppxProvisionedPackage -Online | where Displayname -EQ "Microsoft.WindowsAlarms" | Remove-AppxProvisionedPackage -Online -Allusers
Get-AppxProvisionedPackage -Online | where Displayname -EQ "Microsoft.WindowsCamera" | Remove-AppxProvisionedPackage -Online -Allusers
Get-AppxProvisionedPackage -Online | where Displayname -EQ "microsoft.windowscommunicationsapps" | Remove-AppxProvisionedPackage -Online -Allusers
Get-AppxProvisionedPackage -Online | where Displayname -EQ "Microsoft.WindowsFeedbackHub" | Remove-AppxProvisionedPackage -Online -Allusers
Get-AppxProvisionedPackage -Online | where Displayname -EQ "Microsoft.WindowsMaps" | Remove-AppxProvisionedPackage -Online -Allusers
Get-AppxProvisionedPackage -Online | where Displayname -EQ "Microsoft.WindowsSoundRecorder" | Remove-AppxProvisionedPackage -Online -Allusers
Get-AppxProvisionedPackage -Online | where Displayname -EQ "Microsoft.Xbox.TCUI" | Remove-AppxProvisionedPackage -Online -Allusers
Get-AppxProvisionedPackage -Online | where Displayname -EQ "Microsoft.XboxApp" | Remove-AppxProvisionedPackage -Online -Allusers
Get-AppxProvisionedPackage -Online | where Displayname -EQ "Microsoft.XboxGameOverlay" | Remove-AppxProvisionedPackage -Online -Allusers
Get-AppxProvisionedPackage -Online | where Displayname -EQ "Microsoft.XboxIdentityProvider" | Remove-AppxProvisionedPackage -Online -Allusers
Get-AppxProvisionedPackage -Online | where Displayname -EQ "Microsoft.XboxSpeechToTextOverlay" | Remove-AppxProvisionedPackage -Online -Allusers
Get-AppxProvisionedPackage -Online | where Displayname -EQ "Microsoft.ZuneMusic" | Remove-AppxProvisionedPackage -Online -Allusers
Get-AppxProvisionedPackage -Online | where Displayname -EQ "Microsoft.ZuneVideo" | Remove-AppxProvisionedPackage -Online -Allusers

#Sponsored Windows 10 AppX apps don't have corresponding provisioning packages

#Optional: Typically not removed but you can if you need to for some reason
#Get-AppxProvisionedPackage -Online | where Displayname -EQ "Microsoft.BingWeather" | Remove-AppxProvisionedPackage -Online -Allusers
#Get-AppxProvisionedPackage -Online | where Displayname -EQ "Microsoft.MSPaint" | Remove-AppxProvisionedPackage -Online -Allusers
#Get-AppxProvisionedPackage -Online | where Displayname -EQ "Microsoft.MicrosoftStickyNotes" | Remove-AppxProvisionedPackage -Online -Allusers
#Get-AppxProvisionedPackage -Online | where Displayname -EQ "Microsoft.Windows.Photos" | Remove-AppxProvisionedPackage -Online -Allusers
#Get-AppxProvisionedPackage -Online | where Displayname -EQ "Microsoft.WindowsCalculator" | Remove-AppxProvisionedPackage -Online -Allusers
#Get-AppxProvisionedPackage -Online | where Displayname -EQ "Microsoft.WindowsStore" | Remove-AppxProvisionedPackage -Online -Allusers
