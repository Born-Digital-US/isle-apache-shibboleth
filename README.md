to initialize the current version of Islandora...  
`docker exec -it <container-name or ID> bash /utility-scripts/isle_drupal_build_tools/isle_islandora_installer.sh`

Drupal Login information

isle:isle (as username:password)

Environmental Variables Available:

Match the Islandora UID to the user id of the user on the host system resposible for Islandora's webroot.  
Most distros use UID 1000 for the primary user.  If you are experiencing permissions issues on the host `id -u` to get the UID.

 - ISLANDORA_UID = 1000 (default)
 - ENABLE_XDEBUG = false (default) | true