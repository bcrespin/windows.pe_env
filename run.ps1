
$os=@{
"Windows 7 pro 32bit - OEM/RETAIL/VLK license key" = ("win7","x86","win7x86.iso")
"Windows 7 pro SP1 32bit - OEM/RETAIL/VLK license key" = ("win7","x86","win7x86sp1.iso")
"Windows 7 pro 64bit - OEM/RETAIL/VLK license key" = ("win7","amd64","win7amd64.iso")
"Windows 7 pro SP1 64bit - OEM/RETAIL/VLK license key" = ("win7","amd64","win7amd64sp1.iso")
"Windows 7 32bit EDITON TO CHOOSE - NEED KEY" = ("win7","x86","win7all_editions_32bit.iso")
"Windows 7 64bit EDITON TO CHOOSE - NEED KEY" = ("win7","amd64","win7all_editions_64bit.iso")
"Windows 8 pro 32bit - VLK license key" = ("win8","x86","win8x86.iso")
"Windows 8 pro 64bit - VLK license ley" = ("win8","amd64","win8x86.iso")
"Windows 8.1 pro 32bit - VLK license key" = ("win81","x86","win81x86.iso")
"Windows 8.1 pro 64bit - VLK license key" = ("win81","amd64","win81amd64.iso")
"Windows 10 Treshold2 32bit - OEM/RETAIL/VLK key" = ("win10","x86","Windows_10_fr_treshold2_32bit.iso")
"Windows 10 Treshold2 64bit - OEM/RETAIL/VLK key" = ("win10","amd64","Windows_10_fr_treshold2_x64.iso")
}

$ossetup=@{
"win7" = "Windows 7 Pro SP1 32bit - OEM/RETAIL/VLK license key"
"win8" = "Windows 8 pro 32bit - VLK license key"
"win81" = "Windows 8.1 pro 32bit - VLK license key" 
"win10" = "Windows 10 Treshold2 32bit - OEM/RETAIL/VLK key"
}



$scriptPath = split-path -parent $MyInvocation.MyCommand.Definition


[void] [System.Reflection.Assembly]::LoadWithPartialName("System.Windows.Forms")
[void] [System.Reflection.Assembly]::LoadWithPartialName("System.Drawing") 

$objForm = New-Object System.Windows.Forms.Form 
$objForm.Text = "Windows Installation"
$objForm.Size = New-Object System.Drawing.Size(400,250) 
$objForm.StartPosition = "CenterScreen"

$objForm.KeyPreview = $True
$objForm.Add_KeyDown({if ($_.KeyCode -eq "Enter") 
    {$x=$objListBox.SelectedItem;$objForm.Close()}})
$objForm.Add_KeyDown({if ($_.KeyCode -eq "Escape") 
    {$objForm.Close()}})


$CancelButton = New-Object System.Windows.Forms.Button
$CancelButton.Location = New-Object System.Drawing.Size(150,180)
$CancelButton.Size = New-Object System.Drawing.Size(75,23)
$CancelButton.Text = "Cancel"
$CancelButton.Add_Click({$global:x="";$objForm.Close()})
$objForm.Controls.Add($CancelButton)

$OKButton = New-Object System.Windows.Forms.Button
$OKButton.Location = New-Object System.Drawing.Size(75,180)
$OKButton.Size = New-Object System.Drawing.Size(75,23)
$OKButton.Text = "OK"
$OKButton.Add_Click({$global:x=$objListBox.SelectedItem;$objForm.Close()})
$objForm.Controls.Add($OKButton)


$objLabel = New-Object System.Windows.Forms.Label
$objLabel.Location = New-Object System.Drawing.Size(10,15) 
$objLabel.Size = New-Object System.Drawing.Size(280,15) 
$objLabel.Text = "Select version:"
$objForm.Controls.Add($objLabel) 

$objListBox = New-Object System.Windows.Forms.ListBox 
$objListBox.Location = New-Object System.Drawing.Size(10,30) 
$objListBox.Size = New-Object System.Drawing.Size(320,30) 
$objListBox.Height = 140


# populate OS list
$liste=@()
foreach ($h in $os.GetEnumerator()) {
    $liste+=$h.name
}
$liste= $liste | Sort
foreach ($h in $liste) {  
    [void] $objListBox.Items.Add($h)
}



$objForm.Controls.Add($objListBox) 
$objForm.Topmost = $True
$objForm.Add_Shown({$objForm.Activate()})
[void] $objForm.ShowDialog()

if ( $x -eq "")
{
	exit 0
}
write-host "*** INFO *** Selected: $x" 

if ( ($os.get_item($x))[1] -eq "amd64" )
{
    #we need to run the x86 iso to start the amd64 install..
    $osBaseSelected=($os.get_item($x))[0]
    $osx86BaseSelected=$ossetup.get_item($osBaseSelected)
    $isosetup=($os.get_item($osx86BaseSelected))[2]
    $isosetup="$scriptPath\$isosetup" 
}
else
{ 
    #we can use the iso to launch the process
    $isosetup=($os.get_item($x))[2]
    $isosetup="$scriptPath\$isosetup" 
}


$iso=($os.get_item($x))[2]
$iso="$scriptPath\$iso" 

# need ot add !
if ( !(test-path $isosetup ))
{
    write-host "**** ERROR *** No iso file  : $iso"
    exit 1
}
if ( ! (test-path $iso) )
{
    write-host "**** ERROR *** No iso file  : $iso"
    exit 1
}


# TODO error handling :)
$mount=mount-diskimage $isosetup -passthru
$mount
$driveLetter1 = ($mount | Get-Volume).DriveLetter
write-host "$isosetup mounted on $driveLetter1"

#bug need to add the drive
#new-psdrive -name $driveletter1 -PSProvider Filesystem -Root "$($driveLetter1):\"

write-host $iso
$mount=mount-diskimage $iso -passthru
$mount
$driveLetter2 = ($mount | Get-Volume).DriveLetter
write-host "$iso mounted on $driveLetter2"
#bug need to add the drive
#new-psdrive -name $driveletter2 -PSProvider Filesystem -Root "$($driveLetter2):\"

$cmd=$driveLetter1+":\setup.exe"
$arg1="/InstallFrom:"+$driveLetter2+":\sources\install.wim"
write-host $cmd $arg1
 & $cmd $arg1

 