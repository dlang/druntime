#!/bin/bash

set -euxo pipefail

N=${N:-2}
MODEL=${MODEL:-64}

# build dmd and druntime (in debug and release)
make -j$N -C ../dmd/src -f posix.mak MODEL=$MODEL HOST_DMD=$DMD BUILD="debug" all
make -j$N -C ../dmd/src -f posix.mak MODEL=$MODEL HOST_DMD=$DMD BUILD="release" all
TEST_COVERAGE="1" make -j$N -C . -f posix.mak MODEL=$MODEL unittest-debug
rm -rf test/runnable/extra-files
bash codecov.sh -t "${CODECOV_TOKEN}"
