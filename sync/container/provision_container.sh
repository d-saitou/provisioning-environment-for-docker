#!/bin/bash
#
# Provision docker containers.
# Requires the following packages and tools.
# - python3
# - ansible (+jinja2)
# - docker (+compose plugin)
# - docker-py
# - yq
# - ./tool/jinja2_template_converter.py
# This script outputs error messages related to provisioning to stdout and log file.
#
# Style:
#   refer to google style. (https://google.github.io/styleguide/shellguide.html)
set -o pipefail

# Constants
readonly OK=0
readonly NG=1
readonly BASE_DIR="$(dirname "${0}")"
readonly CTR_DIR="${HOME}/container"
readonly LOG_DIR="${CTR_DIR}/log"
readonly LOG_FILE="${LOG_DIR}/provision.$(date +"%Y%m%d%H%M%S").log"
readonly TIMEZONE="$(timedatectl | grep 'Time zone:' | awk '{print $3}')"

function print_log() {
  printf "$(date +"%Y-%m-%d %T") ${@}\n"
}

function print_label() {
  printf " \n### ${@}\n"
}

#######################################
# Provision docker container.
# Globals:
#   BASE_DIR, CTR_DIR, LOG_DIR, OK, NG
# Arguments:
#   None
# Returns:
#   success:${OK}, failure:${NG}
#######################################
function provision() {
  local image_name

  if [[ -f ${CTR_DIR}/compose.yml ]]; then
    print_label 'cleanup containers and images'
    docker compose -f ${CTR_DIR}/compose.yml stop 2>&1 >/dev/null
    docker compose -f ${CTR_DIR}/compose.yml rm -f 2>&1 >/dev/null
  fi

  print_label 'copy dependent files'
  rm -rf $(find ${CTR_DIR} -mindepth 1 | grep -v ${LOG_DIR} | xargs) 2>&1 >/dev/null
  cp -r ${BASE_DIR}/* ${CTR_DIR}/
  [[ ${?} -ne ${OK} ]] && return ${NG}

  print_label 'configure dbserver container'
  configure_dbserver_container
  [[ ${?} -ne ${OK} ]] && return ${NG}

  print_label 'configure apserver container'
  configure_apserver_container
  [[ ${?} -ne ${OK} ]] && return ${NG}

  print_label 'create containers'
  docker compose -f ${CTR_DIR}/compose.yml up -d
  [[ ${?} -ne ${OK} ]] && return ${NG}

  # Run only on first provisioning
  if [[ $(cat ~/.bashrc | grep 'CONTAINER PROVISIONING BLOCK' | wc -l) -eq 0 ]]; then
    print_label 'add aliases to .bashrc'
    echo "# CONTAINER PROVISIONING BLOCK START" >>~/.bashrc
    echo "alias dbserver-bash='docker exec -it dbserver /bin/bash'" >>~/.bashrc
    echo "alias apserver-bash='docker exec -it apserver /bin/bash'" >>~/.bashrc
    echo "# CONTAINER PROVISIONING BLOCK END" >>~/.bashrc
  fi
  return ${OK}
}

#######################################
# Configure dbserver container.
# Globals:
#   CTR_DIR, TIMEZONE, OK, NG
# Arguments:
#   None
# Returns:
#   failure:${NG}, command return code
#######################################
function configure_dbserver_container() {
  echo 'create environment variable file from config.yml...'
  yq -y .mysql ${CTR_DIR}/config.yml | sed 's/: /=/g' >${CTR_DIR}/dbserver/mysql.env
  [[ ${?} -ne ${OK} ]] && return ${NG}

  echo 'create my.cnf...'
  ${CTR_DIR}/tool/jinja2_template_converter.py \
    ${CTR_DIR}/dbserver/my.cnf.j2 timezone "$(date +%:z)" \
    >${CTR_DIR}/dbserver/conf.d/my.cnf
  [[ ${?} -ne ${OK} ]] && return ${NG}

  echo 'get sql files such as ddl and dmls...'
  local app_init_db_dir=$(yq -r .application.app_init_db_dir ${CTR_DIR}/config.yml)
  if [[ -n "${app_init_db_dir}}" ]]; then
    local app_name=$(yq -r .application.app_name ${CTR_DIR}/config.yml)
    local app_git_url=$(yq -r .application.app_git_url ${CTR_DIR}/config.yml)

    git clone ${app_git_url} /tmp/${app_name}
    [[ ${?} -ne ${OK} ]] && return ${NG}

    cp -r /tmp/${app_name}/${app_init_db_dir} ${CTR_DIR}/dbserver/initdb.d/
    [[ ${?} -ne ${OK} ]] && return ${NG}

    rm -rf /tmp/${app_name}
  fi
  return ${OK}
}

#######################################
# Configure the apserver container.
# Globals:
#   CTR_DIR, OK, NG
# Arguments:
#   None
# Returns:
#   Command return code
#######################################
function configure_apserver_container() {
  echo 'create ansible group_vars file...'
  yq -y .application ${CTR_DIR}/config.yml >${CTR_DIR}/apserver/ansible/group_vars/all
  [[ ${?} -ne ${OK} ]] && return ${NG}
  yq -y .tomcat ${CTR_DIR}/config.yml >>${CTR_DIR}/apserver/ansible/group_vars/all
  [[ ${?} -ne ${OK} ]] && return ${NG}

  # Note:
  #  To configure the apserver manager as desired,
  #  use Ansible instead of the official Tomcat Dockerfile to create a container image.
  echo 'create a container image for AP server using ansible...'
  cd ${CTR_DIR}/apserver/ansible
  ansible-playbook -i hosts site.yml
  local rc=${?}
  cd - >/dev/null
  return ${rc}
}

#######################################
# Main function.
# Globals:
#   CTR_DIR, LOG_DIR, LOG_FILE, OK, NG
# Arguments:
#   None
# Returns:
#   success:${OK}, failure:${NG}
#######################################
function main() {
  local rc
  local message

  if [[ ! -d ${LOG_DIR} ]]; then
    mkdir -p ${CTR_DIR}
    if [[ ${?} -ne ${OK} ]]; then
      echo "Failed to create container directory." >&2
      return ${NG}
    fi
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

  return ${rc}
}

main "${@}"
exit ${?}
