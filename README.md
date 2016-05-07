## Some scripts to select, then install the windows iso you want when booting in PXE 

version supported 7, 8, 8.1, 10(only enterprise iso or some hacked iso to provide install.wil )

Notes: installing windows from PXE is only for fresh install, not upgrade !

## Required : 

** a running web server 
to store windows PE iso (winPE_x86.iso generated with script buil_winpe_iso.bat) 
NOTE : pe image may be stored on the tftp server, but  tftp client and server must be able to exchange more thna 32MB..
and tftp is slow...slow...

** a running cifs share (samba or microsoft)
to store windows ISO 
to store 2 scripts to let user select which ISO & windows version install

** a running dhcp server, doing also a tftp server
to give location of windows PE iso to pxe boot
to provide the script that will be used the windows PE to see the cifs share

NOTE : I could have put the cifs share in the script that is run at startup in the windows PE, 
but I consider solution more evolutive by being able to changs cifs wihtour rebuild the PE iso...

** windows 32bit iso and if you use, 64bit version, bot 32bit and 64bit version  for each OS version
as winPE will run the setup of the 32bit version of windows 7 iso  to install the 64bit version of window 7
winPE will run the setup of the 32bit version of windows 8 iso  to install the 64bit version of window 8
etc...

# Install :

** download tftp.exe http://www.winagents.com/en/products/tftp-client/
and store it inside  the same folder as buil_winpe_iso.bat/ init.ps1
NOTE : feel free to test use another tftp client, but in this case, edit init.ps1 to match  your tftp client argument...

** download & install Windows 8.1 ADK from https://www.microsoft.com/en-us/download/details.aspx?id=30652 

** check batch file : build_winpe_iso.bat
to ensure variable WPE (default : c:\winpe) is on a drive which exist ( you don't need to create the folder, that will be done)
to edit your LOCAL ( test with fr-FR,us-US)
if you put windows ADK to the non default location, edit variable ADKPATH 

** run as administrator the batch :  build_winpe_iso.bat

NOTE: elevated privileges is required as it use dsim command
if you are not confident, review yourself what is done inside the batch ...

if batch ended without error, 
-> copy the winPE_x86.iso (generated  in %WPE% folder) to  your web server DocumentRoot
and keep in mind the url required to access it ( example http://myserver/foo/winPE_x86.iso)

NOTE : if you want to start again, the batch ,you have to remove folder %WPE% yourself

-> edit your tftp server file to add something like :

-------------------------------------------
LABEL win 

	MENU LABEL  ^. Windows 7/8/8.1/10 (Installation)
	
	KERNEL memdisk
	
	INITRD http://myserver/foo/winPE_x86.iso
	
	APPEND iso raw
-------------------------------------------

	
-> edit .\on_tftp_server\windows_install_batch.bat to change %SHARE% by the share hosting your windows ISO

-> COPY it to the root of the tftp server

NOTE:
please ensure your share is something like:

-------------------------------------------
[windows_iso$]

        path = /home/brice/windows_iso
        
        public = 
        
        guest ok = yes
-------------------------------------------

-> copy .\on_file_server\run.bat to your cifs share

--> edit .\on_file_server\run.ps1

edit $OS and $ossetup depending of you windows ISO :

-------------------------------------------
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

"win8" = "Windows 8 pro 32bit - VLK license key

"win81" = "Windows 8.1 pro 32bit - VLK license key" 

"win10" = "Windows 10 Treshold2 32bit - OEM/RETAIL/VLK key"

}

-------------------------------------------

NOTE
you can have several iso of 'winXXX' under $OS but you must at least have an x86 ( 32bit version) of that OS

for each os version you have ( win7,win8, win10) it must exist in $ossetup a same name as in $os  for the x86 architecture

as $ossetup will be used to run the setup of the 32bit version of windows  you want ( win7/win8/win8.1/win10) and install the package of the ISO you want 

so for example:
to  install win7all_editions_64bit.iso, script in PE will mount the iso : win7x86sp1.iso

as win7all_editions_64bit.iso is "win7" and $ossetup for win7 is "Windows 7 Pro SP1 32bit - OEM/RETAIL/VLK license key" which is ISO win7x86sp1.iso

yes...that sound complicated, but that way , I don't create any custom ISO, I only store original ISO...


-> copy .\on_file_server\run.ps1 to  you cifs share  !!
	
	
	





