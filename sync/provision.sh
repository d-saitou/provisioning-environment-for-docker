#!/bin/bash
readonly BASE_DIR="$(dirname "${0}")"

# provision host machine
${BASE_DIR}/host/provision_host.sh
rc=${?}
if [[ ${rc} -ne 0 ]]; then
  exit ${rc}
fi

# provision containers
su - vagrant -c '~/sync/container/provision_container.sh'
rc=${?}

exit ${rc}
