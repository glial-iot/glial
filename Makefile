create_glial_dist: copy_core copy_panel remove_unused_core_files



build_panel: submodule_update
	cd ./panel && npm install && npm run build

submodules_update:
	git submodule update --init
	cd ./core/ && git merge origin master
	cd ./panel/ && git merge origin master

copy_core: create_artefacts_folder
	cp -r ./core/* ./build_artefacts/

remove_unused_core_files: create_artefacts_folder copy_core
	rm -rf ./build_artefacts/README.md
	rm -rf ./build_artefacts/changelog.md
	rm -rf ./build_artefacts/LICENSE
	rm -rf ./build_artefacts/glial.code-workspace
	rm -rf ./build_artefacts/Dockerfile
	rm -rf ./build_artefacts/tests

copy_panel: create_artefacts_folder build_panel
	rm -rf ./build_artefacts/panel
	mkdir ./build_artefacts/panel
	mkdir ./build_artefacts/panel/public
	mkdir ./build_artefacts/panel/public/admin
	mkdir ./build_artefacts/panel/templates
	mv ./panel/dist/index.html ./build_artefacts/panel/templates/
	mv ./panel/dist/* ./build_artefacts/panel/public/admin/

remove_artefacts_folder:
	rm -rf ./build_artefacts

create_artefacts_folder: remove_artefacts_folder
	mkdir ./build_artefacts
