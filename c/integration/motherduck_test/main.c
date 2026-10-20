// Licensed to the Apache Software Foundation (ASF) under one
// or more contributor license agreements.  See the NOTICE file
// distributed with this work for additional information
// regarding copyright ownership.  The ASF licenses this file
// to you under the Apache License, Version 2.0 (the
// "License"); you may not use this file except in compliance
// with the License.  You may obtain a copy of the License at
//
//   http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing,
// software distributed under the License is distributed on an
// "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY
// KIND, either express or implied.  See the License for the
// specific language governing permissions and limitations
// under the License.

#include <stdio.h>
#include <stdlib.h>
#include <string.h>

#include <arrow-adbc/adbc.h>
#include <arrow-adbc/driver/postgresql.h>

int main(void) {
  struct AdbcDriver driver;
  struct AdbcError error;
  memset(&driver, 0, sizeof(driver));
  memset(&error, 0, sizeof(error));

  AdbcStatusCode status =
      AdbcDriverPostgresqlInit(ADBC_VERSION_1_1_0, &driver, &error);
  if (status != ADBC_STATUS_OK) {
    fprintf(stderr, "AdbcDriverPostgresqlInit failed: %s\n",
            error.message ? error.message : "(no error message)");
    if (error.release) error.release(&error);
    return EXIT_FAILURE;
  }

  if (driver.release) {
    status = driver.release(&driver, &error);
    if (status != ADBC_STATUS_OK) {
      fprintf(stderr, "AdbcDriver.release failed: %s\n",
              error.message ? error.message : "(no error message)");
      if (error.release) error.release(&error);
      return EXIT_FAILURE;
    }
  }

  return EXIT_SUCCESS;
}
