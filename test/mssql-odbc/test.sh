#!/bin/bash

set -e

# Optional: Import test library
source dev-container-features-test-lib

# Check installation of libmsodbcsql-18
check "libmsodbcsql-18" test 1 -eq "$(find /opt/microsoft/msodbcsql18 -name 'libmsodbcsql-18.*.so.*' | wc -l)"

# Check installation of `bcp`
check "bcp" test 0 -eq "$(find /opt/mssql-tools18/ -name 'bcp' | wc -l)"

# Check installation of `sqlcmd`
check "sqlcmd" test 0 -eq "$(find /opt/mssql-tools18/ -name 'sqlcmd' | wc -l)"

# Report result
reportResults
