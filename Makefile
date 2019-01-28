DIST_DIR = build_artefacts_dist
PACKET_DIR = build_artefacts_packet
ROCKS_DIR = rocks_bin

VERSION = `cd ./core/ && git describe --dirty --always --tags | cut -c 2-`
SIZE = `du -sk ./$(PACKET_DIR)/glial | awk '{print $$1}'`

ifndef ARCH
  ARCH = armhf
  ${info Not ARCH define, use: "ARCH=armhf" or "ARCH=x86". Set default: $(ARCH)}
endif

create_glial_dist: copy_core copy_panel remove_unused_core_files

make_deb_packet: create_glial_dist copy_armhf_rocks create_artefacts_packet_folder
	mkdir -p ./$(PACKET_DIR)/glial/usr/share/tarantool/glial/
	mkdir -p ./$(PACKET_DIR)/glial/etc/tarantool/instances.enabled/
	cp ./packet_make/instance_glial_start.lua ./$(PACKET_DIR)/glial/etc/tarantool/instances.enabled/glial.lua
	mv ./$(DIST_DIR)/* ./$(PACKET_DIR)/glial/usr/share/tarantool/glial/
	echo $(VERSION) > ./$(PACKET_DIR)/glial/usr/share/tarantool/glial/VERSION

	make create_deb_files

	#chown -R root:root ./$(PACKET_DIR)/glial/
	#chown -R tarantool:tarantool ./$(PACKET_DIR)/glial/etc/tarantool/
	#chown -R tarantool:tarantool ./$(PACKET_DIR)/glial/usr/share/tarantool/

	dpkg-deb --build ./$(PACKET_DIR)/glial glial_$(VERSION)_$(ARCH).deb
	dpkg-deb -I glial_$(VERSION)_$(ARCH).deb

create_deb_files:
	mkdir -p ./$(PACKET_DIR)/glial/DEBIAN
	cp ./packet_make/dirs ./$(PACKET_DIR)/glial/DEBIAN/dirs
	cp ./packet_make/prerm ./$(PACKET_DIR)/glial/DEBIAN/prerm
	cp ./packet_make/postinst ./$(PACKET_DIR)/glial/DEBIAN/postinst

	echo "Package: glial" > ./$(PACKET_DIR)/glial/DEBIAN/control
	echo "Maintainer: vvzvlad <vvzvlad@gmail.com>" >> ./$(PACKET_DIR)/glial/DEBIAN/control
	echo "Architecture: $(ARCH)" >> ./$(PACKET_DIR)/glial/DEBIAN/control
	echo "Section: misc" >> ./$(PACKET_DIR)/glial/DEBIAN/control
	echo "Description: IoT management system by Nokia IoT Lab" >> ./$(PACKET_DIR)/glial/DEBIAN/control
	echo "Priority: optional" >> ./$(PACKET_DIR)/glial/DEBIAN/control
	echo "Origin: vvzvlad <vvzvlad@gmail.com>" >> ./$(PACKET_DIR)/glial/DEBIAN/control
	echo "Depends: tarantool, libmosquitto-dev, tarantool-dev" >> ./$(PACKET_DIR)/glial/DEBIAN/control
	echo "Version: "$(VERSION) >> ./$(PACKET_DIR)/glial/DEBIAN/control
	echo "Installed-Size: "$(SIZE) >> ./$(PACKET_DIR)/glial/DEBIAN/control

copy_armhf_rocks: create_artefacts_packet_folder
	mkdir ./$(PACKET_DIR)/.rocks
	cp -r ./$(ROCKS_DIR)/$(ARCH)/* ./$(PACKET_DIR)/.rocks
	mkdir ./$(PACKET_DIR)/glial/

remove_artefacts_packet_folder:
	rm -rf ./$(PACKET_DIR)

create_artefacts_packet_folder: remove_artefacts_packet_folder
	mkdir ./$(PACKET_DIR)

#------------------------------------------------------------#

build_panel: submodules_update
	cd ./panel && npm install && npm run build

submodules_update:
	git submodule update --init
	git submodule foreach git fetch
	git submodule foreach git merge origin master

copy_core: create_artefacts_dist_folder submodules_update
	cp -r ./core/* ./$(DIST_DIR)/

remove_unused_core_files: create_artefacts_dist_folder copy_core
	rm -rf ./$(DIST_DIR)/README.md
	rm -rf ./$(DIST_DIR)/changelog.md
	rm -rf ./$(DIST_DIR)/LICENSE
	rm -rf ./$(DIST_DIR)/glial.code-workspace
	rm -rf ./$(DIST_DIR)/Dockerfile
	rm -rf ./$(DIST_DIR)/tests

copy_panel: create_artefacts_dist_folder build_panel
	rm -rf ./$(DIST_DIR)/panel
	mkdir ./$(DIST_DIR)/panel
	mkdir ./$(DIST_DIR)/panel/public
	mkdir ./$(DIST_DIR)/panel/public/admin
	mkdir ./$(DIST_DIR)/panel/templates
	cp ./panel/dist/index.html ./$(DIST_DIR)/panel/templates/
	cp -r ./panel/dist/* ./$(DIST_DIR)/panel/public/admin/
	rm -rf ./panel/dist

remove_artefacts_dist_folder:
	rm -rf ./$(DIST_DIR)

create_artefacts_dist_folder: remove_artefacts_dist_folder
	mkdir ./$(DIST_DIR)
