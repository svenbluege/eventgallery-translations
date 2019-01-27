echo off
for /f %%G in ('dir /b /o:n /ad') do (
	echo Found Language %%G
	del %%G.zip
	pushd .
	cd %%G
	del admin.zip
	del site.zip	
	zip -r admin_%%G.zip admin
	zip -r site_%%G.zip site
	zip ../%%G.zip site_%%G.zip admin_%%G.zip pkg_%%G.xml
	popd
	
)