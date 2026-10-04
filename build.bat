@echo off
setlocal EnableDelayedExpansion

rem Builds one installable language pack per language folder:
rem dist\lang_eventgallery_<language>_<version>.zip
rem The version is taken from the manifest of the language (lang_<language>.xml).

cd /d "%~dp0"

set DIST=dist
call :qrmRecursive %DIST%
md %DIST%

for /f %%G in ('dir /b /o:n /ad') do (
	rem a language folder contains its manifest
	IF EXIST %%G\lang_%%G.xml (
		echo Found Language %%G
		set VERSION=
		for /f "usebackq delims=" %%V in (`powershell -NoProfile -Command "([xml](Get-Content '%%G\lang_%%G.xml')).extension.version.Trim()"`) do set VERSION=%%V
		IF "!VERSION!"=="" (
			echo No version found in %%G\lang_%%G.xml
			EXIT /B 1
		)
		set PACKAGE=lang_eventgallery_%%G_!VERSION!.zip
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
			rem the tar of Windows creates zip files, no additional tool is needed
			%SystemRoot%\System32\tar.exe -a -c -f ..\..\%DIST%\!PACKAGE! site admin lang_%%G.xml
		popd
		rem clean up the temporary build folder
		call :qrmRecursive %%G\temp_build
		echo Translation package %DIST%\!PACKAGE! finished.
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
