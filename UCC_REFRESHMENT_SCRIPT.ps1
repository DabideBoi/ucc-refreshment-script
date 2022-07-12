param([switch]$Elevated)

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
    exit
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
$input = read-host "[1] For default program installation [2] For UCC-Standard Windows configuration [3] Reset Windows configuration [X] Exit Script`n`n"
$instpath =  split-path -parent $MyInvocation.MyCommand.Definition
cd $instpath

if ($input -eq '1') {
	#Line of Script for no configuration
	Start-Process -Wait -FilePath '.\asset\installer\ninite.exe' -PassThru
	#Viber not working for global install
	#Start-Process -Wait -FilePath '.\asset\installer\viber.exe' -PassThru
	echo "Press any key to continue..."
	[void][System.Console]::ReadKey($true)
    }
elseif ($input -eq '2') {
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
elseif ($input -eq '2') {
	$path = "C:\Windows\System32\GroupPolicy"

	echo "Copying Machine"
	Copy-Item "C:\Users\papope\Downloads\Test_Folder\Machine" -Destination $path
	echo "Copying Complete"
	echo ""
	echo "Copying User"
	Copy-Item "C:\Users\papope\Downloads\Test_Folder\User" -Destination $path
	echo "Copying Complete"
	echo ""
	echo "Copying User"
	Copy-Item "C:\Users\papope\Downloads\Test_Folder\GPT.INI" -Destination $path
	echo "Copying Complete"
	echo ""
	echo "Press any key to continue..."
	[void][System.Console]::ReadKey($true)
}
elseif ($input -eq '3'){
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
