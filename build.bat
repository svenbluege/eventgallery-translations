@echo off
setlocal EnableDelayedExpansion

for /f %%G in ('dir /b /o:n /ad') do (
	Set CURRENT_FOLDER=%%G
	IF NOT "!CURRENT_FOLDER:~0,4!"==".git" (
		echo Found Language %%G
		del %%G.zip
		pushd .
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
		rd /S /Q %%G\temp_build
	)
)

