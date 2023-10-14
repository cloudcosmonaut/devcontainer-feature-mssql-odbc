#!/bin/bash

set -e

# Optional: Import test library
source dev-container-features-test-lib

# Check installation of libmsodbcsql-17
check "libmsodbcsql-17" test 1 -eq "$(find /opt/microsoft/msodbcsql17 -name 'libmsodbcsql-17.*.so.*' | wc -l)"

# Check installation of `bcp`
check "bcp" test 1 -eq "$(find /opt/mssql-tools/ -name 'bcp' | wc -l)"

# Check installation of `sqlcmd`
check "sqlcmd" test 1 -eq "$(find /opt/mssql-tools/ -name 'sqlcmd' | wc -l)"

# Report result
reportResults
