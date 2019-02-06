.DEFAULT: make_deb_packets

DIST_DIR = ./build_artefacts_dist
PACKET_DIR = ./build_artefacts_packet
ROCKS_DIR = ./rocks_bin
CORE_DIR = ./core
PANEL_DIR = ./panel

DEBIAN_DIR = $(PACKET_DIR)/glial/DEBIAN
PANEL_DIST_DIR = $(DIST_DIR)/panel

VERSION = `cd $(CORE_DIR)/ && git describe --dirty --always --tags | cut -c 2-`
SIZE = `du -sk $(PACKET_DIR)/glial | awk '{print $$1}'`

ifdef BRANCH
 ${info BRANCH set to $(BRANCH)}
endif
ifndef BRANCH
 BRANCH = master
 ${info Not BRANCH define, use "BRANCH=master" or "BRANCH=develop". Set default: $(BRANCH)}
endif

NB =
ifeq ($(BRANCH), develop)
 NB = -night
 ${info Build type: night}
endif

#------------------------------MAIN TARGET------------------------------#


MAKE_PARAM = -f $(lastword $(MAKEFILE_LIST)) BRANCH=$(BRANCH)

make_deb_packets:
	$(MAKE) $(MAKE_PARAM) make_core make_panel clean_debs

	$(MAKE) $(MAKE_PARAM) make_deb_packet_armhf
	$(MAKE) $(MAKE_PARAM) clear_artefacts_packet_folder_armhf

	$(MAKE) $(MAKE_PARAM) make_deb_packet_amd64
	$(MAKE) $(MAKE_PARAM) clear_artefacts_packet_folder_amd64

	$(MAKE) $(MAKE_PARAM) clean_panel clean_core

#---------------------------GENERATE TARGET---------------------------------#

# 1: arch, 2: arch_patch
define generate-targets
make_deb_packet_$(1): create_dirs_$(1) copy_rocks_$(1)
	cp ./packet_make/instance_glial_start.lua $$(PACKET_DIR)/glial/etc/tarantool/instances.enabled/glial.lua
	cp -r $$(DIST_DIR)/* $$(PACKET_DIR)/glial/usr/share/tarantool/glial/
	echo $$(VERSION)$$(NB) > $$(PACKET_DIR)/glial/usr/share/tarantool/glial/VERSION

	mkdir -p $$(DEBIAN_DIR)
	cp ./packet_make/dirs $$(DEBIAN_DIR)/dirs
	cp ./packet_make/prerm $$(DEBIAN_DIR)/prerm
	cp ./packet_make/postinst $$(DEBIAN_DIR)/postinst
	cp ./packet_make/control $$(DEBIAN_DIR)/control

	echo "Architecture: $(1)" >> $$(DEBIAN_DIR)/control
	echo "Version: "$$(VERSION)$$(NB) >> $$(DEBIAN_DIR)/control
	echo "Installed-Size: "$$(SIZE) >> $$(DEBIAN_DIR)/control

	dpkg-deb --build $$(PACKET_DIR)/glial glial_$$(VERSION)$$(NB)_$(1).deb
	dpkg-deb -I glial_$$(VERSION)$$(NB)_$(1).deb

copy_rocks_$(1): create_dirs_$(1)
	mkdir $$(PACKET_DIR)/glial/usr/share/tarantool/glial/.rocks
	cp -r $$(ROCKS_DIR)/$(2)/* $$(PACKET_DIR)/glial/usr/share/tarantool/glial/.rocks/

create_dirs_$(1): clear_artefacts_packet_folder_$(1)
	mkdir -p $$(PACKET_DIR)/glial/usr/share/tarantool/glial/
	mkdir -p $$(PACKET_DIR)/glial/etc/tarantool/instances.enabled/

clear_artefacts_packet_folder_$(1):
	rm -rf $$(PACKET_DIR)

endef

#------------------------------------------------------------#

$(eval $(call generate-targets,armhf,armhf))
$(eval $(call generate-targets,amd64,amd64))

#-----------------------------PANEL-------------------------------#

make_panel: build_panel
	rm -rf $(PANEL_DIST_DIR)
	mkdir $(PANEL_DIST_DIR)
	mkdir -p $(PANEL_DIST_DIR)/public/admin
	mkdir $(PANEL_DIST_DIR)/templates
	cp $(PANEL_DIR)/dist/index.html $(PANEL_DIST_DIR)/templates/
	cp -r $(PANEL_DIR)/dist/* $(PANEL_DIST_DIR)/public/admin/

build_panel: submodules_update clean_panel
	npm install --prefix $(PANEL_DIR)
	npm run build --prefix $(PANEL_DIR)

clean_panel:
	rm -rf $(PANEL_DIR)/dist

#-----------------------------GIT-------------------------------#

submodules_update:
	git submodule update --init
	git submodule foreach git fetch
	git submodule foreach git checkout origin/$(BRANCH)

#-----------------------------CORE-------------------------------#

make_core: submodules_update copy_core remove_unused_core_files

copy_core: clean_core
	mkdir $(DIST_DIR)
	cp -r $(CORE_DIR)/* $(DIST_DIR)/

remove_unused_core_files:
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

clean_core:
	rm -rf $(DIST_DIR)


#-----------------------------deb-------------------------------#

clean_debs: submodules_update clean_core
	rm -rf ./*.deb
