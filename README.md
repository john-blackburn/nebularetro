# Nebula Retro

An open source platform game which allows the user to edit/create new
levels. The game was written in Lua using the Gideros game engine
(http://giderosmobile.com). As such it can be exported for any OS
Gideros supports including iOS, Android, Windows Phone, desktop and
HTML5. On desktop systems you control the game using keyboard (default
controls are left, right and ctrl, you can redefine them from the
Options menu). On mobile devices, touch controls appear which can be
adjusted from the options menu.

In either case, the game can be played in landscape or portrait
mode. In portrait mode the user can edit levels he has completed and
create new ones.

The game now allows you to create new levels and upload them to the server. Other people can then 
play your levels using the "TEH INTERNETS" option. This is achieved using the Gideros UrlLoader class 
which allows HTTP GET and POST requests to be sent. The server code consists of old fashioned CGI 
scripts which save the uploaded levels as simple text files.
