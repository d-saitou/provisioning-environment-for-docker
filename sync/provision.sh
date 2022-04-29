#!/bin/bash
readonly BASE_DIR="$(dirname "${0}")"

# provision host machine
${BASE_DIR}/host/provision_host.sh

exit ${?}
