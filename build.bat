@echo off
setlocal EnableDelayedExpansion

rem Builds one installable language pack per language folder:
rem dist\lang_eventgallery_<language>_<version>.zip
rem The version is taken from the manifest of the language (lang_<language>.xml)
rem and gets the number of commits which changed the language folder appended.
rem
rem For the Joomla updater every language pack gets an update server and the
rem build writes the matching update file dist\update_<language>.xml. Both are
rem published in the release "latest", so a site always gets the newest
rem language pack offered, whatever version of Event Gallery or Joomla it runs.

cd /d "%~dp0"

set DIST=dist
set REPOSITORY=svenbluege/eventgallery-translations
IF DEFINED GITHUB_REPOSITORY set REPOSITORY=%GITHUB_REPOSITORY%
set RELEASE_URL=https://github.com/%REPOSITORY%/releases/download/latest
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
		rem Joomla offers an update only for a higher version, so the number of
		rem commits which changed the language is added: 7.0.0 becomes 7.0.0.42
		for /f %%C in ('git rev-list --count HEAD -- %%G') do set VERSION=!VERSION!.%%C
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
			call :setVersion temp_build\lang_%%G.xml !VERSION!
			call :addUpdateServer temp_build\lang_%%G.xml %%G
			cd temp_build
			rem the tar of Windows creates zip files, no additional tool is needed
			%SystemRoot%\System32\tar.exe -a -c -f ..\..\%DIST%\!PACKAGE! site admin lang_%%G.xml
		popd
		rem clean up the temporary build folder
		call :qrmRecursive %%G\temp_build
		echo Translation package %DIST%\!PACKAGE! finished.
		call :writeUpdateFile %%G !VERSION! !PACKAGE!
		echo Update file %DIST%\update_%%G.xml finished.
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

rem Sets the version in the install xml file
rem param1 Path to XML file
rem param2 Version
:setVersion
powershell -Command "(gc %~1) -replace '<version>.*</version>', '<version>%~2</version>' | Out-File -encoding ASCII %~1"
EXIT /B 0

rem Adds the update server to the install xml file
rem param1 Path to XML file
rem param2 Language
:addUpdateServer
powershell -Command "(gc %~1) -replace '</extension>', '' | Out-File -encoding ASCII %~1"
>> %~1 (
	echo 	^<updateservers^>
	echo 		^<server type="extension" priority="1" name="Event Gallery %~2 language pack"^>%RELEASE_URL%/update_%~2.xml^</server^>
	echo 	^</updateservers^>
	echo ^</extension^>
)
EXIT /B 0

rem Writes the update file for the Joomla updater. The element of a file
rem extension is the name of its manifest file. Joomla ignores an update
rem without a targetplatform, the version .* matches every Joomla version.
rem param1 Language
rem param2 Version
rem param3 File name of the language pack
:writeUpdateFile
set NAME=
for /f "usebackq delims=" %%N in (`powershell -NoProfile -Command "([xml](Get-Content '%~1\lang_%~1.xml')).extension.name.Trim()"`) do set NAME=%%N
set HASH=
for /f "usebackq delims=" %%H in (`powershell -NoProfile -Command "(Get-FileHash '%DIST%\%~3' -Algorithm SHA256).Hash.ToLower()"`) do set HASH=%%H
> %DIST%\update_%~1.xml (
	echo ^<?xml version="1.0" encoding="utf-8"?^>
	echo ^<updates^>
	echo 	^<update^>
	echo 		^<name^>%NAME%^</name^>
	echo 		^<description^>The %~1 language pack for Event Gallery^</description^>
	echo 		^<element^>lang_%~1^</element^>
	echo 		^<type^>file^</type^>
	echo 		^<client^>site^</client^>
	echo 		^<version^>%~2^</version^>
	echo 		^<infourl title="Event Gallery language packs"^>https://github.com/%REPOSITORY%/releases/tag/latest^</infourl^>
	echo 		^<downloads^>
	echo 			^<downloadurl type="full" format="zip"^>%RELEASE_URL%/%~3^</downloadurl^>
	echo 		^</downloads^>
	echo 		^<sha256^>%HASH%^</sha256^>
	echo 		^<targetplatform name="joomla" version=".*"/^>
	echo 	^</update^>
	echo ^</updates^>
)
EXIT /B 0
