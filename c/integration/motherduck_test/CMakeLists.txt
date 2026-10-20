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

cmake_minimum_required(VERSION 3.18)

project(adbc-motherduck-test LANGUAGES C CXX)
set(CMAKE_C_STANDARD 11)
set(CMAKE_C_STANDARD_REQUIRED ON)

set(ADBC_LINKAGE "shared" CACHE STRING "MotherDuck driver linkage")
set_property(CACHE ADBC_LINKAGE PROPERTY STRINGS shared static)

find_package(AdbcDriverMotherDuck REQUIRED)

add_executable(motherduck_test main.c)
if(ADBC_LINKAGE STREQUAL "shared")
  target_link_libraries(
    motherduck_test PRIVATE AdbcDriverMotherDuck::adbc_driver_motherduck_shared)
elseif(ADBC_LINKAGE STREQUAL "static")
  set_target_properties(motherduck_test PROPERTIES LINKER_LANGUAGE CXX)
  target_link_libraries(
    motherduck_test PRIVATE AdbcDriverMotherDuck::adbc_driver_motherduck_static)
else()
  message(FATAL_ERROR "ADBC_LINKAGE must be shared or static")
endif()
