"Ready for Takeoff" Server
==========================

Run local version
-----------------

Open project in separate Godot and run.
Make sure to have a fitting endpoint in Client/gamestate.gd.

Create a new version running on a VM
------------------------------------

- Export pck file of the server in godot to folder "build/"
- Run push_new_version.sh
- Make sure to have a fitting endpoint in Client/gamestate.gd.

Create new droplet deployment
-----------------------------

Create droplet on digitalocean. E.g. Docker 19.03.12 on Ubuntu 20.04

Setup inspired by
https://www.digitalocean.com/community/tutorials/initial-server-setup-with-ubuntu-20-04


```bash
ssh root@SERVER_IP
adduser pilot
usermod -aG sudo pilot
usermod -aG docker pilot

ufw app list
ufw allow OpenSSH
ufw allow 44444
ufw enable
ufw status

rsync --archive --chown=pilot:pilot ~/.ssh /home/pilot

# Now exit ssh and login as pilot
exit
ssh pilot@SERVER_IP

mkdir build

exit
```
