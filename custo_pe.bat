@echo off

set WPE=d:\winpe
set ARCH=x86
set "PECAB=C:\Program Files (x86)\Windows Kits\8.1\Assessment and Deployment Kit\Windows Preinstallation Environment\%ARCH%\WinPE_OCs"

:MOUNT
echo MOUNTING WINPE IMAGE boot.wim in %WPE%...
Dism /mount-wim /wimfile:%WPE%\media\sources\boot.wim /index:1 /mountdir:%WPE%\mount
if %ERRORLEVEL%  GTR 0 goto :END

:TFTP CLIENT
echo COPY TFTP CLIENT
rem tftp client downloaded from http://www.winagents.com/en/products/tftp-client/
copy tftp.exe  %WPE%\mount\windows\System32\
if %ERRORLEVEL% GTR 0 goto :UNMOUNT


:POWERSHELL
echo APPLYING POWERSHELLPACKAGE...
Dism /Add-Package /image:%WPE%\mount /PackagePath:"%PECAB%\WinPE-WMI.cab"
if %ERRORLEVEL% GTR 0 goto :UNMOUNT
Dism /Add-Package /image:%WPE%\mount /PackagePath:"%PECAB%\WinPE-NetFX.cab"
if %ERRORLEVEL% GTR 0 goto :UNMOUNT
Dism /Add-Package /image:%WPE%\mount /PackagePath:"%PECAB%\WinPE-Scripting.cab"
if %ERRORLEVEL% GTR 0 goto :UNMOUNT
Dism /Add-Package /image:%WPE%\mount /PackagePath:"%PECAB%\WinPE-PowerShell.cab"
if %ERRORLEVEL% GTR 0 goto :UNMOUNT
Dism /Add-Package /image:%WPE%\mount /PackagePath:"%PECAB%\WinPE-StorageWMI.cab"
if %ERRORLEVEL% GTR 0 goto :UNMOUNT




:CUSTOM_LANG
echo APPLYING LANGUAGE CUSTOMIZATIONS...
Dism /image:%WPE%\mount /Set-SysLocale:fr-FR
if %ERRORLEVEL% GTR 0 goto :UNMOUNT
Dism /image:%WPE%\mount /Set-UserLocale:fr-FR
if %ERRORLEVEL% GTR 0 goto :UNMOUNT
Dism /image:%WPE%\mount /Set-InputLocale:fr-FR
if %ERRORLEVEL% GTR 0 goto :UNMOUNT

:CUSTOM_STARTUPBATCH
copy %~dp0\init.ps1 %WPE%\mount\windows
echo CREATING STARTUP BATCH IN WINPE...
set INSTALLBATCH=%WPE%\mount\windows\System32\Startnet.cmd
echo @echo off > %INSTALLBATCH%
echo echo **************************** >> %INSTALLBATCH%
echo echo wpeinit... >> %INSTALLBATCH%
echo wpeinit >> %INSTALLBATCH% 
echo echo wpeutil WaitForNetwork... >> %INSTALLBATCH%
echo wpeutil WaitForNetwork >>   %INSTALLBATCH%
echo echo **************************** >> %INSTALLBATCH%
echo echo powershell -executionPolicy Bypass %%%SYSTEMROOT%%%\init.ps1 >>   %INSTALLBATCH%
echo powershell -executionPolicy Bypass %%%SYSTEMROOT%%%\init.ps1  >> %INSTALLBATCH%
timeout /T 3


:BOOTFIX
echo EXCLUDE bootfix.bin
rem http://social.technet.microsoft.com/Forums/windows/en-US/92246cf6-38ed-4568-835a-012447c649b4/vista-winpehow-to-remove-message-of-press-any-key-to-boot-from-the-cddirectly-boot-to-cdrom?forum=itprovistadeployment
rename %WPE%\media\Boot\bootfix.bin  bootfix.bin.old

:UNMOUNT
echo UNMOUNTING WIPE IMAGE in %WPE%
Dism /Unmount-Wim /MountDir:%WPE%\mount /Commit
if %ERRORLEVEL% GTR 0 goto :END

:END