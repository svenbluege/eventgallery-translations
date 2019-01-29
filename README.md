# How to create a language package for Event Gallery

There is a good description on how to create a language package for Joomla.
(https://docs.joomla.org/J2.5:Making_non-core_language_packs)

Please add the backend translation to the ```admin``` folder and all other translations for plugins, modules and the component to the ```site``` folder.

# How to build language packs

## Windows
On the command line go to the root folder of this repository and run ```build.bat```. This will create installable zip files for each language. 

## Linux

Make sure ZIP is installed (```apt-get install zip```). Then run ```build.sh``` to create the language install script.

# How to install a language pack

Just grab a zip file, for example fr_FR.zip, and install it using the Joomla Extension Manager. 
