#.SILENT: make_deb_packet create_deb_files copy_armhf_rocks remove_artefacts_packet_folder create_artefacts_packet_folder create_glial_dist build_panel submodules_update copy_core remove_unused_core_files copy_panel remove_artefacts_dist_folder create_artefacts_dist_folder

.DEFAULT: make_deb_packet

DIST_DIR = ./build_artefacts_dist
PACKET_DIR = ./build_artefacts_packet
ROCKS_DIR = ./rocks_bin
CORE_DIR = ./core
PANEL_DIR = ./panel

DEBIAN_DIR = $(PACKET_DIR)/glial/DEBIAN
PANEL_DIST_DIR = $(DIST_DIR)/panel

VERSION = `cd $(CORE_DIR)/ && git describe --dirty --always --tags | cut -c 2-`
SIZE = `du -sk $(PACKET_DIR)/glial | awk '{print $$1}'`

ifndef ARCH
  ARCH = armhf
  ${info Not ARCH define, use: "ARCH=armhf" or "ARCH=x86_linux". Set default: $(ARCH)}
endif

ifndef BRANCH
  BRANCH = master
  ${info Not BRANCH define, use: "BRANCH=master" or "BRANCH=develop". Set default: $(BRANCH)}
endif

make_deb_packet: create_glial_dist copy_armhf_rocks create_artefacts_packet_folder
	mkdir -p $(PACKET_DIR)/glial/usr/share/tarantool/glial/
	mkdir -p $(PACKET_DIR)/glial/etc/tarantool/instances.enabled/
	cp ./packet_make/instance_glial_start.lua $(PACKET_DIR)/glial/etc/tarantool/instances.enabled/glial.lua
	mv $(DIST_DIR)/* $(PACKET_DIR)/glial/usr/share/tarantool/glial/
	echo $(VERSION) > $(PACKET_DIR)/glial/usr/share/tarantool/glial/VERSION

	make create_deb_files

	#chown -R root:root $(PACKET_DIR)/glial/
	#chown -R tarantool:tarantool $(PACKET_DIR)/glial/etc/tarantool/
	#chown -R tarantool:tarantool $(PACKET_DIR)/glial/usr/share/tarantool/

	dpkg-deb --build $(PACKET_DIR)/glial glial_$(VERSION)_$(ARCH).deb
	dpkg-deb -I glial_$(VERSION)_$(ARCH).deb

create_deb_files:
	mkdir -p $(DEBIAN_DIR)
	cp ./packet_make/dirs $(DEBIAN_DIR)/dirs
	cp ./packet_make/prerm $(DEBIAN_DIR)/prerm
	cp ./packet_make/postinst $(DEBIAN_DIR)/postinst
	cp ./packet_make/control $(DEBIAN_DIR)/control

	echo "Architecture: $(ARCH)" >> $(DEBIAN_DIR)/control
	echo "Version: "$(VERSION) >> $(DEBIAN_DIR)/control
	echo "Installed-Size: "$(SIZE) >> $(DEBIAN_DIR)/control

copy_armhf_rocks: create_artefacts_packet_folder
	mkdir $(PACKET_DIR)/.rocks
	cp -r $(ROCKS_DIR)/$(ARCH)/* $(PACKET_DIR)/.rocks
	mkdir $(PACKET_DIR)/glial/

remove_artefacts_packet_folder:
	rm -rf $(PACKET_DIR)

create_artefacts_packet_folder: remove_artefacts_packet_folder
	mkdir $(PACKET_DIR)

#------------------------------------------------------------#

create_glial_dist: copy_core copy_panel remove_unused_core_files

build_panel: submodules_update
	npm install --prefix $(PANEL_DIR)
	npm run build --prefix $(PANEL_DIR)

submodules_update:
	git submodule update --init
	git submodule foreach git fetch
	git submodule foreach git checkout origin/$(BRANCH)

copy_core: create_artefacts_dist_folder submodules_update
	cp -r $(CORE_DIR)/* $(DIST_DIR)/

remove_unused_core_files: create_artefacts_dist_folder copy_core
	rm -rf $(DIST_DIR)/README.md
	rm -rf $(DIST_DIR)/changelog.md
	rm -rf $(DIST_DIR)/LICENSE
	rm -rf $(DIST_DIR)/glial.code-workspace
	rm -rf $(DIST_DIR)/Dockerfile
	rm -rf $(DIST_DIR)/tests
	rm -rf $(DIST_DIR)/.git
	rm -rf $(DIST_DIR)/.gitignore
	rm -rf $(DIST_DIR)/.gitmodules
	rm -rf $(DIST_DIR)/.travis.yml

copy_panel: create_artefacts_dist_folder build_panel
	rm -rf $(PANEL_DIST_DIR)
	mkdir $(PANEL_DIST_DIR)
	mkdir -p $(PANEL_DIST_DIR)/public/admin
	mkdir $(PANEL_DIST_DIR)/templates
	cp $(PANEL_DIR)/dist/index.html $(PANEL_DIST_DIR)/templates/
	cp -r $(PANEL_DIR)/dist/* $(PANEL_DIST_DIR)/public/admin/
	rm -rf $(PANEL_DIR)/dist

remove_artefacts_dist_folder:
	rm -rf $(DIST_DIR)

create_artefacts_dist_folder: remove_artefacts_dist_folder
	mkdir $(DIST_DIR)
