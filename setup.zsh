#!/bin/zsh

export MOONBOT_PATH="$(readlink -f $(dirname $0))"
export MOONBOT_REAL_ROOT="$MOONBOT_PATH/.root"
export MOONBOT_SRC="$MOONBOT_PATH/.src"
export MOONBOT_ROOT="/tmp/.moonbot.$(uuidgen -t)-$(uuidgen -r)"

continue_stage=n
if [ -f "$MOONBOT_PATH/.continue_stage" ]
  then continue_stage=$(cat "$MOONBOT_PATH/.continue_stage")
fi

if [ -f "$MOONBOT_PATH/.continue_root" ]
  then MOONBOT_ROOT=$(cat "$MOONBOT_PATH/.continue_root")
fi

case $continue_stage in
  n)
    rm -f "$MOONBOT_PATH/.continue_stage"
    rm -rf "$MOONBOT_ROOT" "$MOONBOT_SRC" "$MOONBOT_REAL_ROOT"
    mkdir -p "$MOONBOT_REAL_ROOT" "$MOONBOT_SRC"
    ln -s "$MOONBOT_REAL_ROOT" "$MOONBOT_ROOT"
    echo "$MOONBOT_ROOT" > "$MOONBOT_PATH/.continue_root"
    ;&
  luajit)
    echo "luajit" > "$MOONBOT_PATH/.continue_stage"
    cd $MOONBOT_SRC
    git clone http://luajit.org/git/luajit-2.0.git luajit || exit
    cd luajit
    git checkout v2.1
    git pull
    make amalg PREFIX=$MOONBOT_ROOT CPATH=$MOONBOT_ROOT/include LIBRARY_PATH=$MOONBOT_ROOT/lib && \
    make install PREFIX=$MOONBOT_ROOT || exit
    ln -sf luajit-2.1.0-alpha $MOONBOT_ROOT/bin/luajit
    ;&
  luarocks)
    echo "luarocks" > "$MOONBOT_PATH/.continue_stage"
    cd $MOONBOT_SRC
    git clone git://github.com/keplerproject/luarocks.git || exit
    cd luarocks
    ./configure --prefix=$MOONBOT_ROOT \
                --lua-version=5.1 \
                --lua-suffix=jit \
                --with-lua=$MOONBOT_ROOT \
                --with-lua-include=$MOONBOT_ROOT/include/luajit-2.1 \
                --with-lua-lib=$MOONBOT_ROOT/lib/lua/5.1 \
                --force-config && \
    make build && make install || exit
    ;&
  msgpack)
    echo "msgpack" > "$MOONBOT_PATH/.continue_stage"
    # messagepack
    $MOONBOT_ROOT/bin/luarocks install lua-messagepack || exit
    ;&
  moonscript)
    echo "moonscript" > "$MOONBOT_PATH/.continue_stage"
    $MOONBOT_ROOT/bin/luarocks install moonscript
    ;&
  wrappers)
    echo "wrappers" > "$MOONBOT_PATH/.continue_stage"
    # wrappers
    cat > $MOONBOT_PATH/.run <<END
#!/bin/zsh
export MOONBOT_PATH="\$(readlink -f \$(dirname \$0))"
export MOONBOT_REAL_ROOT="\$MOONBOT_PATH/.root"
export MOONBOT_ROOT="$MOONBOT_ROOT"

[ -e "\$MOONBOT_ROOT" ] || ln -s "\$MOONBOT_PATH/.root" \$MOONBOT_ROOT

export PATH="\$MOONBOT_ROOT/bin:\$PATH"
export LUA_PATH="\$MOONBOT_PATH/custom_?.lua;\$MOONBOT_PATH/src/?/init.lua;\$MOONBOT_PATH/src/?.lua;\$MOONBOT_PATH/?.lua;\$LUA_PATH;\$MOONBOT_ROOT/lualib/?.lua;\$MOONBOT_ROOT/share/luajit-2.1.0-alpha/?.lua;\$MOONBOT_ROOT/share/lua/5.1/?.lua;\$MOONBOT_ROOT/share/lua/5.1/?/init.lua"
export LUA_CPATH="\$MOONBOT_PATH/custom_?.so;\$MOONBOT_PATH/src/?/init.so;\$MOONBOT_PATH/src/?.so;\$MOONBOT_PATH/?.so;\$LUA_CPATH;\$MOONBOT_ROOT/lualib/?.so;\$MOONBOT_ROOT/share/luajit-2.1.0-alpha/?.so;\$MOONBOT_ROOT/share/lua/5.1/?.so;\$MOONBOT_ROOT/share/lua/5.1/?/init.so"
export MOON_PATH="\$MOONBOT_PATH/custom_?.moon;\$MOONBOT_PATH/src/?/init.moon;\$MOONBOT_PATH/src/?.moon;\$MOONBOT_PATH/?.moon;\$MOON_PATH;\$MOONBOT_ROOT/lualib/?.moon;\$MOONBOT_ROOT/share/luajit-2.1.0-alpha/?.moon;\$MOONBOT_ROOT/share/lua/5.1/?.moon;\$MOONBOT_ROOT/share/lua/5.1/?/init.moon"
export LD_LIBRARY_PATH="\$MOONBOT_ROOT/lib:\$LD_LIBRARY_PATH"

fn=\$(basename \$0)
if [ "\$fn" = ".run" ]
  then exec "\$@"
else
  exec \$fn "\$@"
fi
END
    chmod a+rx $MOONBOT_PATH/.run
    ln -sf .run $MOONBOT_PATH/moon
    ln -sf .run $MOONBOT_PATH/moonc
    ln -sf .run $MOONBOT_PATH/luarocks
    ;&
esac

# cleanup
rm -rf "$MOONBOT_SRC"
rm -f "$MOONBOT_ROOT" "$MOONBOT_PATH/.continue_stage" "$MOONBOT_PATH/.continue_root"
