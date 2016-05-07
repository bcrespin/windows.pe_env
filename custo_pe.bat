@echo off

set WPE=d:\winpe
set LOCAL="fr-FR"
rem set LOCAL="us-US"

rem ####################################################################################################################

rem don't quote it please
rem change it if ADK installed not in default folder
set ADKPATH=C:\Program Files (x86)\Windows Kits\8.1

rem don't change arch unless you know what you do
set ARCH=x86
set "PECAB=%ADKPATH%\Assessment and Deployment Kit\Windows Preinstallation Environment\%ARCH%\WinPE_OCs"
set MSBATCHINITCMD="%ADKPATH%\Assessment and Deployment Kit\Deployment Tools\DandISetEnv.bat"
set COPYPECMD="%ADKPATH%\Assessment and Deployment Kit\Windows Preinstallation Environment\copype"
set MAKEMEDIACMD="%ADKPATH%\Assessment and Deployment Kit\Windows Preinstallation Environment\MakeWinPEMedia"

set SCRIPTPATH="%~dp0%"


IF EXIST "%ADKPATH%" goto CHECKTFTP
echo WINDOWS 8.1 ADK is missing or not in the expected directory
echo download & install it from https://www.microsoft.com/download/details.aspx?id=39982
goto :PB

:CHECKTFTP
IF EXIST "%SCRIPTPATH%\tftp.exe" goto CHECKSCRIPT
echo ERROR : tftp.exe missing in script dir
echo please download it from : http://www.winagents.com/en/products/tftp-client/
goto :PB

:CHECKSCRIPT
IF EXIST "%SCRIPTPATH%\init.ps1" goto PROCEED
echo ERROR : required file init.ps1 missing in script dir
goto :PB

:PROCEED
rem #####################################################################################################################
rem content from "C:\Program Files (x86)\Windows Kits\8.1\Assessment and Deployment Kit\Deployment Tools\DandISetEnv.bat"
rem only remove cmd at end as we do all automatic
rem to setup some required variables

REM Sets the PROCESSOR_ARCHITECTURE according to native platform for x86 and x64. 
REM
IF /I %PROCESSOR_ARCHITECTURE%==x86 (
    IF NOT "%PROCESSOR_ARCHITEW6432%"=="" (
        SET PROCESSOR_ARCHITECTURE=%PROCESSOR_ARCHITEW6432%
    )
) ELSE IF /I NOT %PROCESSOR_ARCHITECTURE%==amd64 (
    @echo Not implemented for PROCESSOR_ARCHITECTURE of %PROCESSOR_ARCHITECTURE%.
    @echo Using "%ProgramFiles%"
    
    SET NewPath="%ProgramFiles%"

    goto SetPath
)

REM
REM Query the 32-bit and 64-bit Registry hive for KitsRoot
REM

SET regKeyPathFound=1
SET wowRegKeyPathFound=1
SET KitsRootRegValueName=KitsRoot81

REG QUERY "HKLM\Software\Wow6432Node\Microsoft\Windows Kits\Installed Roots" /v %KitsRootRegValueName% 1>NUL 2>NUL || SET wowRegKeyPathFound=0
REG QUERY "HKLM\Software\Microsoft\Windows Kits\Installed Roots" /v %KitsRootRegValueName% 1>NUL 2>NUL || SET regKeyPathFound=0

if %wowRegKeyPathFound% EQU 0 (
  if %regKeyPathFound% EQU 0 (
    @echo KitsRoot not found, can't set common path for Deployment Tools
    goto :EOF 
  ) else (
    SET regKeyPath=HKLM\Software\Microsoft\Windows Kits\Installed Roots
  )
) else (
    SET regKeyPath=HKLM\Software\Wow6432Node\Microsoft\Windows Kits\Installed Roots
)


  
FOR /F "skip=2 tokens=2*" %%i IN ('REG QUERY "%regKeyPath%" /v %KitsRootRegValueName%') DO (SET KitsRoot=%%j)

REM
REM Build the D&I Root from the queried KitsRoot
REM
SET DandIRoot=%KitsRoot%Assessment and Deployment Kit\Deployment Tools

REM
REM Construct the path to WinPE directory, architecture-independent
REM Construct two paths, one of which is without quotes, for internal usage in WinPE scripts
REM
SET WinPERoot=%KitsRoot%Assessment and Deployment Kit\Windows Preinstallation Environment

REM 
REM Constructing tools paths relevant to the current Processor Architecture 
REM
SET DISMRoot=%DandIRoot%\%PROCESSOR_ARCHITECTURE%\DISM
SET BCDBootRoot=%DandIRoot%\%PROCESSOR_ARCHITECTURE%\BCDBoot
SET ImagingRoot=%DandIRoot%\%PROCESSOR_ARCHITECTURE%\Imaging
SET OSCDImgRoot=%DandIRoot%\%PROCESSOR_ARCHITECTURE%\Oscdimg
SET WdsmcastRoot=%DandIRoot%\%PROCESSOR_ARCHITECTURE%\Wdsmcast

REM
REM Now do the paths that apply to all architectures...
REM
REM Note that the last one in this list should not have a
REM trailing semi-colon to avoid duplicate semi-colons
REM on the last entry when the final path is assembled.
REM
SET HelpIndexerRoot=%DandIRoot%\HelpIndexer
SET WSIMRoot=%DandIRoot%\WSIM

REM
REM Now buld the master path from the various tool root folders...
REM
REM Note that each fragment above should have any required trailing 
REM semi-colon as a delimiter so we do not put any here.
REM
REM Note the last one appended to NewPath should be the last one
REM set above in the arch. neutral section which also should not
REM have a trailing semi-colon.
REM
SET NewPath=%DISMRoot%;%ImagingRoot%;%BCDBootRoot%;%OSCDImgRoot%;%WdsmcastRoot%;%HelpIndexerRoot%;%WSIMRoot%;%WinPERoot%;

:SetPath
SET PATH=%NewPath:"=%;%PATH%
rem #####################################################################################################################

:PECOPY
echo CREATE COPY PE FILES
call %COPYPECMD% %ARCH% "%WPE%"
if %ERRORLEVEL%  GTR 0 goto :ERROR

:MOUNT
echo MOUNTING WINPE IMAGE boot.wim in %WPE%...
Dism /mount-wim /wimfile:%WPE%\media\sources\boot.wim /index:1 /mountdir:%WPE%\mount
if %ERRORLEVEL%  GTR 0 goto :ERROR

:TFTP_CLIENT
echo COPY TFTP CLIENT
rem tftp client downloaded from http://www.winagents.com/en/products/tftp-client/
copy %~dp0\tftp.exe  %WPE%\mount\windows\System32\
if %ERRORLEVEL% GTR 0 goto :UNMOUNTISSUE

:POWERSHELL
echo APPLYING POWERSHELLPACKAGE...
Dism /Add-Package /image:%WPE%\mount /PackagePath:"%PECAB%\WinPE-WMI.cab"
if %ERRORLEVEL% GTR 0 goto :UNMOUNTISSUE
Dism /Add-Package /image:%WPE%\mount /PackagePath:"%PECAB%\WinPE-NetFX.cab"
if %ERRORLEVEL% GTR 0 goto :UNMOUNTISSUE
Dism /Add-Package /image:%WPE%\mount /PackagePath:"%PECAB%\WinPE-Scripting.cab"
if %ERRORLEVEL% GTR 0 goto :UNMOUNTISSUE
Dism /Add-Package /image:%WPE%\mount /PackagePath:"%PECAB%\WinPE-PowerShell.cab"
if %ERRORLEVEL% GTR 0 goto :UNMOUNTISSUE
Dism /Add-Package /image:%WPE%\mount /PackagePath:"%PECAB%\WinPE-StorageWMI.cab"
if %ERRORLEVEL% GTR 0 goto :UNMOUNTISSUE

:CUSTOM_LANG
echo APPLYING LANGUAGE CUSTOMIZATIONS...
Dism /image:%WPE%\mount /Set-SysLocale:%LOCAL%
if %ERRORLEVEL% GTR 0 goto :UNMOUNTISSUE
Dism /image:%WPE%\mount /Set-UserLocale:%LOCAL%
if %ERRORLEVEL% GTR 0 goto :UNMOUNTISSUE
Dism /image:%WPE%\mount /Set-InputLocale:%LOCAL%
if %ERRORLEVEL% GTR 0 goto :UNMOUNTISSUE

:CUSTOM_STARTUPBATCH
copy %~dp0\init.ps1 %WPE%\mount\windows
if %ERRORLEVEL% GTR 0 goto :UNMOUNTISSUE
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
if %ERRORLEVEL% GTR 0 goto :UNMOUNTISSUE

:UNMOUNT
echo UNMOUNTING WIPE IMAGE in %WPE%
Dism /Unmount-Wim /MountDir:%WPE%\mount /Commit
if %ERRORLEVEL% GTR 0 goto :ERROR
goto :MAKEMEDIA

:UNMOUNTISSUE
echo UNMOUNTING WIPE IMAGE in %WPE%
Dism /Unmount-Wim /MountDir:%WPE%\mount /Commit
if %ERRORLEVEL% GTR 0 goto :ERROR
goto END

:MAKEMEDIA
echo CREATE MEDIA %WPE%\winPE_%ARCH%.iso in %WPE%
%MAKEMEDIACMD% /ISO %WPE% %WPE%\winPE_%ARCH%.iso
if %ERRORLEVEL% GTR 0 goto :ERROR
GOTO END

:ERROR
echo ERROR OCCURED, PLEASE LOOK AT MESSAGE ABOVE

:END
cd /d "%SCRIPTPATH%"
