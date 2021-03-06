#### Running RadTrack in a Docker container

*TODO(robnagler) This doesn't seem to work right.*

Get DISPLAY variable:

```bash
echo $DISPLAY
```

Get xauth for that display

```bash
xauth list
```

Set up a tunnel on the host (6000 + display):

```
socat TCP-LISTEN:6010,fork,bind=172.17.42.1 TCP:127.0.0.1:6010
```

Note: the 172.17.42.1 will change, but this is the docker default for the docker host.

Add in the xauth cookie from above:

```
xauth add 172.17.42.1:10 MIT-MAGIC-COOKIE-1  <cookie>
```

In docker container, set the display:

```
export DISPLAY=172.17.42.1:10.0
```

Start the display.

#### Uploading Vagrant box

Go to the radtrack box page on Atlas:

https://atlas.hashicorp.com/biviosoftware/boxes/radtrack

Click on `New version`. Set provider to `virtualbox`. Upload the box.

Click 'edit' next to the version (e.g. v0.2). Then click `release version`.

#### Misc

##### Running docker manually

```bash
docker run -i -t -v $PWD:/cfg fedora:21 /bin/bash -l
```

#### Installing Qt on the Mac

Download http://download.qt.io/official_releases/qt/4.8/4.8.6/qt-opensource-mac-4.8.6-1.dmg and
install.

#### Manually building and installing Qt

You probably don't need to do this, and it doesn't seem to work on Mavericks right now.

Build QT in a virtualenv:

```bash
if [[ ! $VIRTUAL_ENV ]]; then
    echo 'You must have a pyenv activated.' 1>&2
    exit 1
fi
set -e
tmp=/var/tmp/$USER$$
mkdir "$tmp"
cd "$tmp"
curl -s -L -O http://download.qt.io/official_releases/qt/4.8/4.8.6/qt-everywhere-opensource-src-4.8.6.tar.gz
tar xzf qt-everywhere-opensource-src-4.8.6.tar.gz
rm qt-everywhere-opensource-src-4.8.6.tar.gz
cd qt-everywhere-opensource-src-4.8.6
./configure -opensource -confirm-license -prefix "$VIRTUAL_ENV" -prefix-install -nomake 'tests examples demos docs translations' -no-multimedia -no-webkit -no-javascript-jit -no-phonon -no-xmlpatterns -system-sqlite -no-script -no-svg -no-scripttools -no-qt3support
gmake
gmake install
```
