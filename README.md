# How to create a language package for Event Gallery

There is a good description on how to create a language package for Joomla.
(https://docs.joomla.org/J2.5:Making_non-core_language_packs)

Please add the backend translation to the ```admin``` folder and **all** other translations for plugins, modules and the component to the ```site``` folder. 
While building the install package, the content of the site folder is copied to the admin folder so you don't need to have separate translation files for plugins and modules.

In the manifest file you don't need to add all translation files manually. Just use the placeholder ```FILES_ADMIN``` and ```FILES_SITE```. The build process will replace them with the correct file listing. Check the ```lang_fr-FR.xml``` to see an example.

    <files folder="admin" target="administrator/language/fr-FR">
        <!-- placeholder for the files. The build files will replace that -->
        FILES_ADMIN
    </files>
    <files folder="site" target="language/fr-FR">
        <!-- placeholder for the files. The build files will replace that -->
        FILES_SITE
    </files>

# How to build language packs

The build creates one installable zip file per language in the folder ```dist```. The name of a file contains the language and the version, for example ```lang_eventgallery_fr-FR_7.0.0.23.zip```.

Set the version of Event Gallery a language pack is made for with the ```version``` tag in its manifest file (```lang_fr-FR.xml```), for example ```7.0.0```. The build adds the number of commits which changed the language folder as fourth part, so every change of a language results in a higher version like ```7.0.0.23```. Therefore the build needs the full git history.

For the Joomla updater the build adds an update server to every language pack and writes the matching update file ```update_fr-FR.xml``` to the folder ```dist```.

## GitHub

Every push to the master branch builds all language packs and publishes them together with the update files as separate files of the release [latest](https://github.com/svenbluege/eventgallery-translations/releases/latest). For a pull request the language packs are attached to the workflow run as the artifact ```language-packs```.

## Windows
On the command line go to the root folder of this repository and run ```build.bat```.

## Linux

Make sure ZIP is installed (```apt-get install zip```). Then run ```build.sh```.

# How to install a language pack

Download the zip file of your language from the [latest release](https://github.com/svenbluege/eventgallery-translations/releases/latest), for example ```lang_eventgallery_fr-FR_7.0.0.23.zip```, and install it using the Joomla Extension Manager. After that the Joomla updater offers every new language pack of your language.
