#!/bin/bash
#
# Script to provision host OS.
#
# Style:
#   refer to google style. (https://google.github.io/styleguide/shellguide.html)
set -o pipefail

# Constants
readonly OK=0
readonly NG=1
readonly BASE_DIR="$(dirname "${0}")"
readonly LOG_DIR="${HOME}/provision"
readonly LOG_FILE="${LOG_DIR}/provision.$(date +"%Y%m%d%H%M%S").log"
readonly PLAYBOOK_DIR="${BASE_DIR}/ansible"

function print_log() {
  printf "$(date +"%Y-%m-%d %T") ${@}\n"
}

function print_label() {
  printf " \n### ${@}\n"
}

#######################################
# Provision host OS.
# Globals:
#   PLAYBOOK_DIR, OK, NG
# Arguments:
#   None
# Returns:
#   success:${OK}, failure:${NG}
#######################################
function provision() {
  local rc

  if [[ ! -e /usr/bin/ansible && ! -e /usr/local/bin/ansible ]]; then
    print_label 'update package list'
    apt-get -q update
    [[ ${?} -ne ${OK} ]] && return ${NG}

    print_label 'upgrate package'
    apt-get -y -q dist-upgrade
    [[ ${?} -ne ${OK} ]] && return ${NG}

    print_label 'install pip3'
    apt-get -y -q install python3-pip
    [[ ${?} -ne ${OK} ]] && return ${NG}

    print_label 'install ansible'
    pip3 install ansible
    [[ ${?} -ne ${OK} ]] && return ${NG}
  fi

  print_label 'provision host'
  cd ${PLAYBOOK_DIR}
  ansible-playbook -i hosts -l app-group site.yml
  rc=${?}
  cd - >/dev/null
  [[ ${rc} -ne ${OK} ]] && return ${NG}

  return ${OK}
}

#######################################
# Main function.
# Globals:
#   LOG_DIR, LOG_FILE, OK, NG
# Arguments:
#   None
# Returns:
#   success:${OK}, failure:${NG}
#######################################
function main() {
  local rc
  local message

  if [[ `whoami` != "root" ]]; then
    echo "Please change to root user." >&2
    return ${NG}
  fi

  if [[ ! -d ${LOG_DIR} ]]; then
    mkdir -p ${LOG_DIR}
    if [[ ${?} -ne ${OK} ]]; then
      echo "Failed to create log directory." >&2
      return ${NG}
    fi
  fi

  print_log "*************************" | tee -a ${LOG_FILE}
  print_log " Provisioning start..."    | tee -a ${LOG_FILE}
  print_log "*************************" | tee -a ${LOG_FILE}

  provision 2>&1 \
    | while read line; do \
        print_log "${line}"; \
      done \
    | tee -a ${LOG_FILE}
  rc=${?}

  if [[ ${rc} -eq ${OK} ]]; then
    message='Provisioning completed!'
  else
    message='Provisioning failed!'
  fi
  print_log ' '                         | tee -a ${LOG_FILE}
  print_log '*************************' | tee -a ${LOG_FILE}
  print_log " ${message}"               | tee -a ${LOG_FILE}
  print_log '*************************' | tee -a ${LOG_FILE}
  chown -R vagrant:vagrant ${LOG_DIR}

  return ${rc}
}

main "${@}"
exit ${?}
