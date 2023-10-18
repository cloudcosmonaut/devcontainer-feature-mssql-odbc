#!/bin/bash

set -e

# Optional: Import test library
source dev-container-features-test-lib

# Check gh-cli in path
check "gh-in-path" test 1 -eq "$(which gh | wc -l)"

# Report result
reportResults
