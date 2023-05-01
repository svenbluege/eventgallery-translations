#!/usr/bin/env bash

# Creates a file list in the install xml file
# param1 Path to the folder with the language files
# param2 Path to XML file
# param3 Placeholder which gets replaced in the language file
addFiles () {
  FILES_PATH=$1
  XML_FILE_PATH=$2
  PLACEHOLDER=$3

  FILENAMECONTENT="\n"
  for FILENAME in $FILES_PATH/*; do
    FILENAMECONTENT="${FILENAMECONTENT} <filename>$(basename -- "$FILENAME")</filename>\n"
  done
  sed -i 's,'"$PLACEHOLDER"','"$FILENAMECONTENT"',g' $XML_FILE_PATH
}

# removes files/folders only if they exist.
qrmRecursive() {
  for f
  do
    [ -e "$f" ] && rm -r "$f"
  done
}

for G in *; do
    if [[ -d $G ]]; then
        echo Found Language $G
		# delete all the old language package
		rm -r $G.zip
		pushd . >> /dev/null
			# create a temporary build folder, copy the site FILENAMECONTENT 
			# to the admin/site folder and add then the admin FILENAMECONTENT 
			# to the admin folder. Then create the zip file
			cd $G
		 	qrmRecursive temp_build
			mkdir -p temp_build/admin
			mkdir -p temp_build/site
			cp -r site/. temp_build/site
			cp -r site/. temp_build/admin
			cp -r -f admin/. temp_build/admin
			cp lang_$G.xml temp_build/
			addFiles 'temp_build/admin'  temp_build/lang_$G.xml 'FILES_ADMIN'
      addFiles 'temp_build/site'  temp_build/lang_$G.xml 'FILES_SITE'
			cd temp_build
			zip -r -q ../../$G.zip site admin lang_$G.xml
		popd >> /dev/null
		# clean up the temporary build folder
		rm -r $G/temp_build
		echo "Translation package for $G finished."
    fi
done
