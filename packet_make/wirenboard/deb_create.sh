#!/bin/sh
set -e

ARCH="armhf"

rm -rf ./build_artefacts
mkdir ./build_artefacts

# Copy rocks
mkdir ./build_artefacts/.rocks
cp -r ./$ARCH""_rocks/* ./build_artefacts/.rocks/


mkdir -p ./build_artefacts/glial/usr/share/tarantool/glial
cp -r ../../build_artefacts/* ./build_artefacts/glial/usr/share/tarantool/glial/
rm ./build_artefacts/glial/usr/share/tarantool/glial/glial_start.lua

mkdir -p ./build_artefacts/glial/etc/tarantool/instances.enabled/
cp ./wb_instance_glial_start.lua ./build_artefacts/glial/etc/tarantool/instances.enabled/glial.lua

# Change owner
#chown -R root:root ./build_artefacts/glial/
#chown -R tarantool:tarantool ./build_artefacts/glial/etc/tarantool/
#chown -R tarantool:tarantool ./build_artefacts/glial/usr/share/tarantool/

# Make deb metainfo
mkdir -p ./build_artefacts/glial/DEBIAN

cp ./control ./build_artefacts/glial/DEBIAN/control

VERSION=`cd ../../core/ && git describe --dirty --always --tags | cut -c 2-`
VERSION_FOR_CONTROL="Version: "$VERSION
echo $VERSION_FOR_CONTROL >> ./build_artefacts/glial/DEBIAN/control

SIZE=`du -sk  ./build_artefacts/glial |awk '{print $1}'`
SIZE_FOR_CONTROL="Installed-Size: "$SIZE
echo $SIZE_FOR_CONTROL >> ./build_artefacts/glial/DEBIAN/control

cp ./dirs ./build_artefacts/glial/DEBIAN/dirs
cp ./prerm ./build_artefacts/glial/DEBIAN/prerm
cp ./postinst ./build_artefacts/glial/DEBIAN/postinst

# Add version file
echo $VERSION > ./build_artefacts/glial/usr/share/tarantool/glial/VERSION

# Buld
dpkg-deb --build ./build_artefacts/glial glial_$VERSION""_$ARCH"".deb
dpkg-deb -I glial_$VERSION""_$ARCH"".deb

# Clear
rm -rf ./build_artefacts
