param([switch]$Elevated,
    [string]$User = "",
    [int]$MDMvalue = 0,
    [int]$ValidityPeriod = 240
)

function Test-Admin {
    $currentUser = New-Object Security.Principal.WindowsPrincipal $([Security.Principal.WindowsIdentity]::GetCurrent())
    $currentUser.IsInRole([Security.Principal.WindowsBuiltinRole]::Administrator)
}

if ((Test-Admin) -eq $false)  {
    if ($elevated) {
        # tried to elevate, did not work, aborting
    } else {
        Start-Process powershell.exe -Verb RunAs -ArgumentList ('-noprofile -noexit -file "{0}" -elevated' -f ($myinvocation.MyCommand.Definition))
    }
    #exit
}


$input = 0
While ($name -ne "X" -or $name -ne "x") {
clear
echo "============================================================================================"
echo "============================================================================================"
echo "============================================================================================"
echo "			           UCC Refreshment Script"
echo "============================================================================================"
echo "============================================================================================"
echo "============================================================================================"
echo ""
echo "What would you like to do?"
echo ""
$input = read-host "[1] For default program installation [2] For GCPW installation`n [3] For UCC-Standard Windows configuration [4] Reset Windows configuration [<blank>] Exit Script`n`n"
$instpath =  split-path -parent $MyInvocation.MyCommand.Definition
cd $instpath

#install programs
if ($input -eq '1') {
	#Line of Script for no configuration
	Start-Process -Wait -FilePath '.\asset\installer\ninite.exe' -PassThru
	#Viber not working for global install
	#Start-Process -Wait -FilePath '.\asset\installer\viber.exe' -PassThru
	echo "Press any key to continue..."
	[void][System.Console]::ReadKey($true)
    }

#install gcpw
elseif($input -eq '2'){
	<# This script downloads Google Credential Provider for Windows from
https://tools.google.com/dlpage/gcpw/, then installs and configures it.
Windows administrator access is required to use the script.
If Chrome enterprise is not present, it will also download and install it
and it will enroll them to the Chrome Enterprise
#>

<# Specify a -user parameter if you want to bind the current user account to a Google account.
-User name.lastname@domain.com -> to specify email to enroll current windows account
-MDMvalue 1 -> to enable automatic MDM Enrollment to Google Endpoint Management
-ValidityPeriod 30 -> To change the number of days an account can be used without connecting to Google
Run the script like below, make sure you check the parameters:
powershell.exe -ExecutionPolicy Unrestricted -NoLogo -NoProfile -Command "& '.\gcpw_enrollment.ps1' -User name.lastname@domain.com -MDMvalue 1"
#>

<# Add domains to restrict here #>
$domainsAllowedToLogin = "ucc.ph"
<# Faster downloads with Invoke-WebRequest #>
$ProgressPreference = 'SilentlyContinue'

Add-Type -AssemblyName System.Drawing
Add-Type -AssemblyName PresentationFramework

<# Check if one or more domains are set #>
if ($domainsAllowedToLogin.Equals('')) {
    # $msgResult = [System.Windows.MessageBox]::Show('The list of domains cannot be empty! Please edit this script.', 'GCPW', 'OK', 'Error')
    Write-Output 'The list of domains cannot be empty! Please edit this script.'
    exit 5
}

function Is-Admin() {
    $admin = [bool](([System.Security.Principal.WindowsIdentity]::GetCurrent()).groups -match 'S-1-5-32-544')
    return $admin
}

<# Check if the current user is an admin and exit if they aren't. #>
if (-not (Is-Admin)) {
    # $result = [System.Windows.MessageBox]::Show('Please run as administrator!', 'GCPW', 'OK', 'Error')
    Write-Output 'Please run as administrator!'
    exit 5
}

if (!(Get-ItemProperty -Path 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\*' | Where-Object { $_.DisplayName -match "Google Credential Provider for Windows" })) {
    <# Choose the GCPW file to download. 32-bit and 64-bit versions have different names #>
    $gcpwFileName = 'gcpwstandaloneenterprise.msi'
    if ([Environment]::Is64BitOperatingSystem) {
        $gcpwFileName = 'gcpwstandaloneenterprise64.msi'
    }

    <# Download the GCPW installer. #>
    $gcpwUrlPrefix = 'https://dl.google.com/credentialprovider/'
    $gcpwUri = $gcpwUrlPrefix + $gcpwFileName
    Write-Host 'Downloading GCPW from' $gcpwUri
    Invoke-WebRequest -Uri $gcpwUri -OutFile "$env:temp\$gcpwFileName"

    <# Run the GCPW installer and wait for the installation to finish #>
    $arguments = "/i `"$env:temp\$gcpwFileName`" /quiet"
    $installProcess = (Start-Process msiexec.exe -ArgumentList $arguments -PassThru -Wait)

    <# Check if installation was successful #>
    if ($installProcess.ExitCode -ne 0) {
        # $result = [System.Windows.MessageBox]::Show('Installation failed!', 'GCPW', 'OK', 'Error')
        Write-Output 'Installation failed!'
        exit $installProcess.ExitCode
    }
    else {
        # $result = [System.Windows.MessageBox]::Show('Installation completed successfully!', 'GCPW', 'OK', 'Info')
        Write-Output 'Installation completed successfully!'
    }
} else {
    Write-Output 'GCPW alreaday installed. Skipping...'
}

<# Set the required registry key with the allowed domains #>
$registryPath = 'HKEY_LOCAL_MACHINE\Software\Google\GCPW'
$name = 'domains_allowed_to_login'
[microsoft.win32.registry]::SetValue($registryPath, $name, $domainsAllowedToLogin)

$domains = Get-ItemPropertyValue HKLM:\Software\Google\GCPW -Name $name

if ($domains -eq $domainsAllowedToLogin) {
    # $msgResult = [System.Windows.MessageBox]::Show('Configuration completed successfully!', 'GCPW', 'OK', 'Info')
    Write-Output 'Domain configuration completed successfully!'
}
else {
    # $msgResult = [System.Windows.MessageBox]::Show('Could not write to registry. Configuration was not completed.', 'GCPW', 'OK', 'Error')
    Write-Output "Could not write domain configuration to registry. Configuration was not completed. ($domains - $domainsAllowedToLogin)"
}

<# Set the validity, time accounts are allowed to be offline #>
$name = 240
$value = $ValidityPeriod
[microsoft.win32.registry]::SetValue($registryPath, $name, $value)

$validity = Get-ItemPropertyValue HKLM:\Software\Google\GCPW -Name $name

if ($validity -eq $value) {
    # $msgResult = [System.Windows.MessageBox]::Show('Configuration completed successfully!', 'GCPW', 'OK', 'Info')
    Write-Output 'Validity configuration completed successfully!'
}
else {
    # $msgResult = [System.Windows.MessageBox]::Show('Could not write to registry. Configuration was not completed.', 'GCPW', 'OK', 'Error')
    Write-Output "Could not write validity to registry. Configuration was not completed. ($domains - $domainsAllowedToLogin)"
}

<# Set MDM enrollment #>
Write-Output "Setting MDM value to $MDMvalue"
$name = 'enable_dm_enrollment'
[microsoft.win32.registry]::SetValue($registryPath, $name, $MDMvalue)

$validity = Get-ItemPropertyValue HKLM:\Software\Google\GCPW -Name $name

if ($validity -eq $MDMvalue) {
    # $msgResult = [System.Windows.MessageBox]::Show('Configuration completed successfully!', 'GCPW', 'OK', 'Info')
    Write-Output 'MDM enrollment configuration completed successfully!'
}
else {
    # $msgResult = [System.Windows.MessageBox]::Show('Could not write to registry. Configuration was not completed.', 'GCPW', 'OK', 'Error')
    Write-Output "Could not write MDM enrollment to registry. Configuration was not completed. (MDM -> $MDMvalue)"
}

<# if $User is set to a valid Google email account, the current account will be tied to it #>
if ($User) {
    Write-Output "Setting user to $User"
    $currentSid = Get-CimInstance Win32_UserAccount -Filter "Name = '$env:USERNAME'" | Select-Object -ExpandProperty SID
    $registryPath = "HKEY_LOCAL_MACHINE\Software\Google\GCPW\Users\" + $currentSid
    $name = 'email'
    [microsoft.win32.registry]::SetValue($registryPath, $name, $User)

    $path = "HKLM:\Software\Google\GCPW\Users\" + $currentSid
    $userCheck = Get-ItemPropertyValue $path -Name $name

    if ($userCheck -eq $User) {
        # $msgResult = [System.Windows.MessageBox]::Show('Configuration completed successfully!', 'GCPW', 'OK', 'Info')
        Write-Output 'User configuration completed successfully!'
    }
    else {
        # $msgResult = [System.Windows.MessageBox]::Show('Could not write to registry. Configuration was not completed.', 'GCPW', 'OK', 'Error')
        Write-Output "Could not write User to registry. Configuration was not completed. (User -> $User)"
    }
}

Start-Process -Wait -FilePath '.\asset\set_gcpw_token.reg' -PassThru
}

#Install Windows Configuration
elseif ($input -eq '3') {
	$path = "C:\Windows\System32\GroupPolicy"

	echo "Copying Machine"
	Copy-Item "\asset\config\Machine\" -Destination $path
	echo "Copying Complete"
	echo ""
	echo "Copying User"
	Copy-Item "\asset\config\User\" -Destination $path
	echo "Copying Complete"
	echo ""
	echo "Copying User"
	Copy-Item "\asset\config\GPT.INI" -Destination $path
	echo "Copying Complete"
	echo ""
	echo "Updating"
	gpupdate /force
	echo "Press any key to continue..."
	[void][System.Console]::ReadKey($true)
}

elseif ($input -eq '4'){
	RD /S /Q "%WinDir%\System32\GroupPolicy"
	gpupdate /force
	echo "Reset Complete"
	echo "Restart to apply changes"
	echo "Press any key to continue..."
	[void][System.Console]::ReadKey($true)
}
elseif ($input -ne "X" -or $input -ne "x"){
	exit
	$input = "X"
}
}
