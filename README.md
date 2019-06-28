# ISLE Apache HTTPD Image

## Part of the ISLE Islandora 7.x Docker Images
Designed as the webserver (httpd) for ISLE. Hosts Drupal and Islandora modules and includes an [install script to provide a quick start!](#loading-the-islelocaldomain-islandora-instance-quickstart)

Based on:  
  - [Adopt OpenJDK 8 Docker Image](https://hub.docker.com/r/adoptopenjdk/openjdk8)
  - [Apache HTTPD 2.4](https://httpd.apache.org/)
  - [PHP 5.6](https://www.php.net/)

Contains and Includes:
  - [Composer](https://getcomposer.org)
  - [Drush 8.x](https://www.drush.org/)
  - [Tesseract OCR](https://github.com/tesseract-ocr) w/ Language Packs:
    - DEU (GER)
    - ENG
    - FRA
    - HIN
    - ITA
    - JPN
    - POR
    - RUS
    - SPA
  - Demo Kakadu JP2 library and binaries as made available by the AdoreDjatoka project.
    - *NOTE*: you will need to purchase a Kakadu license if you intend to use these binaries in production.  
  - [ImageMagick 7](https://www.imagemagick.org/)
    - Features: Cipher DPC HDRI OpenMP
    - Delegates (built-in): bzlib djvu mpeg fontconfig freetype jbig jng jpeg lcms lqr lzma openexr openjp2 png ps raw rsvg tiff webp wmf x zlib
  - [File Information Tool Set (FITS)](https://projects.iq.harvard.edu/fits/home)
  - [S6 Overlay](https://github.com/just-containers/s6-overlay) to manage services  
  - `cron` and `tmpreaper` to clean /tmp

## Loading the ISLE.localdomain Islandora instance ('quickstart')

to initialize the current version of Islandora...  
`docker exec -it isle-apache-ld bash /utility-scripts/isle_drupal_build_tools/isle_islandora_installer.sh`

### Default Login information

Drupal login information
  - Username: isle
  - Password: isle

## Environmental Variables Available:

  - ISLANDORA_UID = 1000 (default)  
Match the Islandora UID to the user id of the user on the host system responsible for Islandora's webroot.  
Most distros use UID 1000 for the primary user, so it is the default.  
**If you are experiencing permission issues on the host when editing your webroot `id -u` to get the appropriate UID to set.**

  - ENABLE_XDEBUG = false (default) | true  
Enables the XDEBUG Apache mod for remote debugging.

  - PULL_ISLE_BUILD_TOOLS = true (default) | false  
Fetches the latest ISLE build tools from the (Islandora Collaboration Group)[https://github.com/Islandora-Collaboration-Group/isle_drupal_build_tools]
