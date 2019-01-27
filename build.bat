echo off
for /f %%G in ('dir /b /o:n /ad') do (
	echo Found Language %%G
	del %%G.zip
	pushd .
	cd %%G
	zip -r ../%%G.zip site admin lang_%%G.xml
	popd
	
)