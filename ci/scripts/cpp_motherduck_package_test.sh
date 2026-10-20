#!/usr/bin/env bash
# Licensed to the Apache Software Foundation (ASF) under one
# or more contributor license agreements.  See the NOTICE file
# distributed with this work for additional information
# regarding copyright ownership.  The ASF licenses this file
# to you under the Apache License, Version 2.0 (the
# "License"); you may not use this file except in compliance
# with the License.  You may obtain a copy of the License at
#
#   http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing,
# software distributed under the License is distributed on an
# "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY
# KIND, either express or implied.  See the License for the
# specific language governing permissions and limitations
# under the License.

# Test installed shared and static MotherDuck CMake packages. The static build
# deliberately uses external fmt and nanoarrow packages.

set -euo pipefail

main() {
    local -r source_dir="${1}"
    local -r build_dir="${2}"
    local -r install_dir="${3}"
    local -r deps_prefix="${install_dir}/deps"

    if [ ! -d "${build_dir}/fmt" ]; then
        git clone https://github.com/fmtlib/fmt.git \
            --branch 11.1.4 --depth 1 "${build_dir}/fmt"
    fi
    cmake -S "${build_dir}/fmt" -B "${build_dir}/fmt-build" \
          -DCMAKE_BUILD_TYPE=Release \
          -DCMAKE_INSTALL_PREFIX="${deps_prefix}" \
          -DCMAKE_POSITION_INDEPENDENT_CODE=ON \
          -DFMT_DOC=OFF \
          -DFMT_TEST=OFF
    cmake --build "${build_dir}/fmt-build" --target install -j

    if [ ! -d "${build_dir}/nanoarrow" ]; then
        git clone https://github.com/apache/arrow-nanoarrow.git \
            --depth 1 "${build_dir}/nanoarrow"
    fi
    cmake -S "${build_dir}/nanoarrow" -B "${build_dir}/nanoarrow-build" \
          -DCMAKE_BUILD_TYPE=Release \
          -DCMAKE_INSTALL_PREFIX="${deps_prefix}" \
          -DCMAKE_POSITION_INDEPENDENT_CODE=ON
    cmake --build "${build_dir}/nanoarrow-build" --target install -j

    export PKG_CONFIG_PATH="${deps_prefix}/lib/pkgconfig${PKG_CONFIG_PATH:+:${PKG_CONFIG_PATH}}"

    for linkage in shared static; do
        local build_shared=OFF
        local build_static=OFF
        if [ "${linkage}" = "shared" ]; then
            build_shared=ON
        else
            build_static=ON
        fi

        local package_prefix="${install_dir}/${linkage}"
        cmake -S "${source_dir}/c" -B "${build_dir}/${linkage}" \
              -DCMAKE_BUILD_TYPE=Release \
              -DCMAKE_INSTALL_PREFIX="${package_prefix}" \
              -DCMAKE_PREFIX_PATH="${deps_prefix}" \
              -DADBC_BUILD_SHARED="${build_shared}" \
              -DADBC_BUILD_STATIC="${build_static}" \
              -DADBC_BUILD_TESTS=OFF \
              -DADBC_DRIVER_MANAGER=ON \
              -DADBC_DRIVER_POSTGRESQL=ON \
              -DADBC_MOTHERDUCK_FLAVOR=ON \
              -DADBC_WITH_VENDORED_FMT=OFF \
              -DADBC_WITH_VENDORED_NANOARROW=OFF
        cmake --build "${build_dir}/${linkage}" --target install -j

        cmake -S "${source_dir}/c/integration/motherduck_test" \
              -B "${build_dir}/consumer-${linkage}" \
              -DCMAKE_BUILD_TYPE=Release \
              -DCMAKE_PREFIX_PATH="${package_prefix};${deps_prefix}" \
              -DADBC_LINKAGE="${linkage}"
        cmake --build "${build_dir}/consumer-${linkage}" --target motherduck_test -j

        env \
            "DYLD_LIBRARY_PATH=${package_prefix}/lib${DYLD_LIBRARY_PATH:+:${DYLD_LIBRARY_PATH}}" \
            "LD_LIBRARY_PATH=${package_prefix}/lib${LD_LIBRARY_PATH:+:${LD_LIBRARY_PATH}}" \
            "${build_dir}/consumer-${linkage}/motherduck_test"
    done
}

main "$@"
