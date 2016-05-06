# pe_env
TODO/TO CHECK... ! !  :


to create a windows 8 PE used to boot in PXE

First download & install Windows 8 PE  from https://www.microsoft.com/en-us/download/details.aspx?id=30652 ( it's included in Windows Assessment and Deployment Kit (ADK) for Windows® 8 

create a folder let say D:\winpe_env, and unzip https://github.com/bcrespin/pe_env/archive/master.zip inside

create a folder let say D:\winpe that will be used to prepare the windows 8 PE iso
-> update script "custo_pe.bat" variable set WPE=d:\winpe to match your folder

download tftp.exe from http://www.winagents.com/en/products/tftp-client/ and put it insider you D:\winpe_env


run C:\Program Files (x86)\Windows Kits\8.1\Assessment and Deployment Kit\Deployment Tools\DandISetEnv.batand 
and type  "copype x86 D:\winpe"

now run batch : custo_pe.bat with runas

