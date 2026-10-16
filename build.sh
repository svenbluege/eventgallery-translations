#!/usr/bin/env bash

# Builds one installable language pack per language folder:
# dist/lang_eventgallery_<language>_<version>.zip
# The version is taken from the manifest of the language (lang_<language>.xml)
# and gets the number of commits which changed the language folder appended.
#
# For the Joomla updater every language pack gets an update server and the
# build writes the matching update file dist/update_<language>.xml. Both are
# published in the release "latest", so a site always gets the newest
# language pack offered, whatever version of Event Gallery or Joomla it runs.

set -euo pipefail

cd "$(dirname "$0")"

DIST=dist
REPOSITORY=${GITHUB_REPOSITORY:-svenbluege/eventgallery-translations}
RELEASE_URL=https://github.com/$REPOSITORY/releases/download/latest

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
        # Joomla offers an update only for a higher version, so the number of
        # commits which changed the language is added: 7.0.0 becomes 7.0.0.42
        VERSION=$VERSION.$(git rev-list --count HEAD -- "$G")
        PACKAGE=lang_eventgallery_${G}_${VERSION}.zip
        NAME=$(sed -n 's:.*<name>\(.*\)</name>.*:\1:p' "$MANIFEST" | tr -d '[:space:]')

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
        sed -i 's:<version>.*</version>:<version>'"$VERSION"'</version>:' "$TEMP/lang_$G.xml"
        sed -i 's,</extension>,\t<updateservers>\n\t\t<server type="extension" priority="1" name="Event Gallery '"$G"' language pack">'"$RELEASE_URL/update_$G.xml"'</server>\n\t</updateservers>\n</extension>,' "$TEMP/lang_$G.xml"
        (cd "$TEMP" && zip -r -q -X "../../$DIST/$PACKAGE" site admin "lang_$G.xml")
        # clean up the temporary build folder
        rm -rf "$TEMP"
        echo "Translation package $DIST/$PACKAGE finished."

        # the update file for the Joomla updater. The element of a file
        # extension is the name of its manifest file. Joomla ignores an update
        # without a targetplatform, the version .* matches every Joomla version.
        cat > "$DIST/update_$G.xml" <<EOF
<?xml version="1.0" encoding="utf-8"?>
<updates>
	<update>
		<name>$NAME</name>
		<description>The $G language pack for Event Gallery</description>
		<element>lang_$G</element>
		<type>file</type>
		<client>site</client>
		<version>$VERSION</version>
		<infourl title="Event Gallery language packs">https://github.com/$REPOSITORY/releases/tag/latest</infourl>
		<downloads>
			<downloadurl type="full" format="zip">$RELEASE_URL/$PACKAGE</downloadurl>
		</downloads>
		<sha256>$(sha256sum "$DIST/$PACKAGE" | cut -d' ' -f1)</sha256>
		<targetplatform name="joomla" version=".*"/>
	</update>
</updates>
EOF
        echo "Update file $DIST/update_$G.xml finished."
    fi
done
