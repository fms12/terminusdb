#!/bin/bash
CURRENT_DIR=$(pwd)
GIT_ROOT_DIR=$(git rev-parse --show-toplevel)
SWIPL_DIR="/usr/lib/swi-prolog"
SOURCE="${BASH_SOURCE[0]}"
TERMINUSDB_DIR="${CURRENT_DIR}/app_dir/usr/share/terminusdb"

function cleanup () {
    rm -rf "$TERMINUSDB_DIR"/src/rust/target
}

# Download linuxdeploy first
curl -Ls 'https://github.com/linuxdeploy/linuxdeploy/releases/download/continuous/linuxdeploy-x86_64.AppImage' > linuxdeploy-x86_64.AppImage
chmod +x linuxdeploy-x86_64.AppImage
mkdir -p app_dir/usr/share/terminusdb
mkdir -p app_dir/usr/bin
mkdir -p app_dir/usr/lib/swi-prolog/pack
mkdir -p app_dir/usr/lib/x86_64-linux-gnu
rsync -r "$GIT_ROOT_DIR"/* app_dir/usr/share/terminusdb
cp -r terminusdb/* app_dir/usr/share/terminusdb/
cp -r /usr/lib/swi-prolog app_dir/usr/lib/
cp -L /usr/lib/x86_64-linux-gnu/libedit.so.2 app_dir/usr/lib/swi-prolog/lib/x86_64-linux/
cp -L /lib/x86_64-linux-gnu/libpcre.so.3 app_dir/usr/lib/swi-prolog/lib/x86_64-linux/
cp -L /usr/lib/x86_64-linux-gnu/libbsd.so.0 app_dir/usr/lib/swi-prolog/lib/x86_64-linux/
rm -rf app_dir/usr/lib/swi-prolog/bin/x86_64-linux/swipl-ld
cd $TERMINUSDB_DIR && make
cleanup
#linuxdeploy-x86_64.AppImage --appdir ./app_dir --executable /lib/swi-prolog/bin/x86_64-linux/swipl --library /lib/swi-prolog --library ~/.local/share/swi-prolog/pack/terminus_store_prolog/rust/target/release/libterminus_store_prolog.so -d terminusdb.desktop -i swipl.png --custom-apprun AppRun --output appimage --verbosity=0
cd "$CURRENT_DIR"
./linuxdeploy-x86_64.AppImage --appdir ./app_dir --executable "$SWIPL_DIR"/bin/x86_64-linux/swipl --library "$SWIPL_DIR"/lib/x86_64-linux/libswipl.so.8 --library /lib/x86_64-linux-gnu/libpcre.so.3 -d terminusdb.desktop -i terminusdb.svg --custom-apprun AppRun --output appimage --verbosity=0
