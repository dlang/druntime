set -u

## download dmd and run `dbuild/main.d`
get_dmd(){
  set -e
  (
    set -x
    bin_D=bin
    mkdir -p $bin_D
    source mak/VARS

    zip_F=$bin_D/tmp.zip
    os2=$OS
    bin_D2=bin
    if [ "$OS" == "osx" ]; then
      echo ok
    else
      bin_D2+=$MODEL
    fi

    if [ "$OS" == "freebsd" ]; then
      os2+=-$MODEL
    fi

    TOOL_DIR=$bin_D/dmd2/$OS/$bin_D2/
    TOOL_RDMD=$TOOL_DIR/rdmd

    if [ ! -f $zip_F ]; then
      # xz requires brew on OSX; can't use `| tar -Jxf - -C $bin_D`
      curl -fSL --retry 3 "http://downloads.dlang.org/releases/2.x/$DMD_VERSION/dmd.$DMD_VERSION.$os2.zip" -o $zip_F
      unzip $zip_F -d $bin_D
    fi

    export GENERATED_VARS_F
    export TOOL_RDMD
    $TOOL_RDMD dbuild/main.d
  )
}

echo_run () {
  echo "$@"
  "$@"
}
