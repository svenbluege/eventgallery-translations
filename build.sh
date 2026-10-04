#!/usr/bin/env bash

# Builds one installable language pack per language folder:
# dist/lang_eventgallery_<language>_<version>.zip
# The version is taken from the manifest of the language (lang_<language>.xml).

set -euo pipefail

cd "$(dirname "$0")"

DIST=dist

# Creates a file list in the install xml file
# param1 Path to the folder with the language files
# param2 Path to XML file
# param3 Placeholder which gets replaced in the language file
addFiles () {
  FILES_PATH=$1
  XML_FILE_PATH=$2
  PLACEHOLDER=$3

  FILENAMECONTENT="\n"
  for FILENAME in "$FILES_PATH"/*; do
    FILENAMECONTENT="${FILENAMECONTENT}\t\t\t<filename>$(basename -- "$FILENAME")</filename>\n"
  done
  sed -i 's,'"$PLACEHOLDER"','"$FILENAMECONTENT"',g' "$XML_FILE_PATH"
}

rm -rf "$DIST"
mkdir "$DIST"

for G in *; do
    # a language folder is named like fr-FR
    if [[ -d $G && $G =~ ^[a-z]{2,3}-[A-Z]{2}$ ]]; then
        echo "Found Language $G"
        MANIFEST=$G/lang_$G.xml
        if [[ ! -f $MANIFEST ]]; then
            echo "Missing manifest $MANIFEST" >&2
            exit 1
        fi
        VERSION=$(sed -n 's:.*<version>\(.*\)</version>.*:\1:p' "$MANIFEST" | tr -d '[:space:]')
        if [[ -z $VERSION ]]; then
            echo "No version found in $MANIFEST" >&2
            exit 1
        fi
        PACKAGE=lang_eventgallery_${G}_${VERSION}.zip

        # create a temporary build folder, copy the site content
        # to the admin/site folder and add then the admin content
        # to the admin folder. Then create the zip file
        TEMP=$G/temp_build
        rm -rf "$TEMP"
        mkdir -p "$TEMP/admin" "$TEMP/site"
        cp -r "$G/site/." "$TEMP/site"
        cp -r "$G/site/." "$TEMP/admin"
        cp -r -f "$G/admin/." "$TEMP/admin"
        cp "$MANIFEST" "$TEMP/"
        addFiles "$TEMP/admin" "$TEMP/lang_$G.xml" 'FILES_ADMIN'
        addFiles "$TEMP/site" "$TEMP/lang_$G.xml" 'FILES_SITE'
        (cd "$TEMP" && zip -r -q -X "../../$DIST/$PACKAGE" site admin "lang_$G.xml")
        # clean up the temporary build folder
        rm -rf "$TEMP"
        echo "Translation package $DIST/$PACKAGE finished."
    fi
done
