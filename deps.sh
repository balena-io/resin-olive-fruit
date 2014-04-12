curl http://archive.raspberrypi.org/debian/raspberrypi.gpg.key | apt-key add -
echo "deb http://archive.raspberrypi.org/debian wheezy main" >> /etc/apt/sources.list
apt-get -q update
apt-get install -qy libraspberrypi-bin
