#!/usr/bin/env bash

for G in *; do
    if [[ -d $G ]]; then
        echo Found Language $G
		# delete all the old language package
		rm -r $G.zip
		pushd .
			# create a temporary build folder, copy the site content 
			# to the admin/site folder and add then the admin content 
			# to the admin folder. Then create the zip file
			cd $G
		 	rm -r temp_build
			mkdir -p temp_build/admin
			mkdir -p temp_build/site
			cp -r site/. temp_build/site
			cp -r site/. temp_build/admin
			cp -r -f admin/. temp_build/admin
			cp lang_$G.xml temp_build/
			cd temp_build
			zip -r ../../$G.zip site admin lang_$G.xml
		popd
		# clean up the temporary build folder
		# rm -r $G/temp_build
    fi
done
