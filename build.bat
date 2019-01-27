@echo off
setlocal EnableDelayedExpansion

for /f %%G in ('dir /b /o:n /ad') do (
	Set CURRENT_FOLDER=%%G
	:: ignore the .git folder
	IF NOT "!CURRENT_FOLDER:~0,4!"==".git" (
		echo Found Language %%G
		:: delete all the old language package
		del %%G.zip
		pushd .
			:: create a temporary build folder, copy the site content 
			:: to the admin/site folder and add then the admin content 
			:: to the admin folder. Then create the zip file
			cd %%G
		 	rd /S /Q temp_build
			md temp_build\admin
			md temp_build\site
			Xcopy /E /I site temp_build\site
			Xcopy /E /I site temp_build\admin
			Xcopy /E /I /Y admin temp_build\admin
			cd temp_build
			zip -r ../../%%G.zip site admin lang_%%G.xml
		popd
		:: clean up the temporary build folder
		rd /S /Q %%G\temp_build
	)
)

