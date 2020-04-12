@echo off
setlocal EnableDelayedExpansion

for /f %%G in ('dir /b /o:n /ad') do (
	Set CURRENT_FOLDER=%%G
	rem ignore the . folders
	IF NOT "!CURRENT_FOLDER:~0,1!"=="." (
		echo Found Language %%G
		rem delete all the old language package
		IF EXIST %%G.zipg del %%G.zip
		pushd .
			rem create a temporary build folder, copy the site content
			rem to the admin/site folder and add then the admin content
			rem to the admin folder. Then create the zip file
			cd %%G
		 	call :qrmRecursive temp_build
			md temp_build\admin
			md temp_build\site
			Xcopy /E /I site temp_build\site > nul 2>&1
			Xcopy /E /I site temp_build\admin > nul 2>&1
			Xcopy /E /I /Y admin temp_build\admin > nul 2>&1
			copy lang_%%G.xml temp_build\ > nul 2>&1
			call :addFiles temp_build\admin  temp_build\lang_%%G.xml FILES_ADMIN
            call :addFiles temp_build\site  temp_build\lang_%%G.xml FILES_SITE
			cd temp_build
			zip -r -q ../../%%G.zip site admin lang_%%G.xml
		popd
		rem clean up the temporary build folder
		call :qrmRecursive %%G\temp_build
		echo Translation package for %%G finished.
	)
)

EXIT /B 0

:qrmRecursive
IF EXIST %~1 rd /S /Q %~1
EXIT /B 0

rem Creates a file list in the install xml file
rem param1 Path to the folder with the language files
rem param2 Path to XML file
rem param3 Placeholder which gets replaced in the language file
:addFiles
set FILES_PATH=%~1
set XML_FILE_PATH=%~2
set PLACEHOLDER=%~3

set "TAGOPEN=<filename>"
set "TAGCLOSE=</filename>"

set FILENAMECONTENT=
for /f %%G in ('dir /b /o:n %FILES_PATH%') do (
    SET FILENAMECONTENT=!FILENAMECONTENT! !TAGOPEN!%%G!TAGCLOSE!
)
powershell -Command "(gc %XML_FILE_PATH%) -replace '%PLACEHOLDER%', '%FILENAMECONTENT%' | Out-File -encoding ASCII %XML_FILE_PATH%"


EXIT /B 0
