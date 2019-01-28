#!/bin/sh
set -e

git submodule update

rm -rf ./build_artefacts

mkdir ./build_artefacts
cp -r ./core/* ./build_artefacts/
rm -rf ./build_artefacts/panel

mkdir ./build_artefacts/panel
mkdir ./build_artefacts/panel/public
mkdir ./build_artefacts/panel/public/admin
mkdir ./build_artefacts/panel/templates

cd ./panel/
npm install
npm run build
cd ..

mv ./panel/dist/index.html ./build_artefacts/panel/templates/
mv  ./panel/dist/* ./build_artefacts/panel/public/admin/


rm -rf ./build_artefacts/README.md
rm -rf ./build_artefacts/changelog.md
rm -rf ./build_artefacts/LICENSE
rm -rf ./build_artefacts/glial.code-workspace
rm -rf ./build_artefacts/Dockerfile
rm -rf ./build_artefacts/tests
