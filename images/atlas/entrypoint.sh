#!/bin/bash

# Licensed to the Apache Software Foundation (ASF) under one
# or more contributor license agreements.  See the NOTICE file
# distributed with this work for additional information
# regarding copyright ownership.  The ASF licenses this file
# to you under the Apache License, Version 2.0 (the
# "License"); you may not use this file except in compliance
# with the License.  You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

# Note: no set -e — Atlas init commands may fail gracefully (patches, log4j warnings)

export MANAGE_LOCAL_HBASE=false
export MANAGE_LOCAL_SOLR=false

export MANAGE_EMBEDDED_CASSANDRA=false
export MANAGE_LOCAL_ELASTICSEARCH=false

# Use JAVA_HOME from image ENV, or detect dynamically as fallback
if [ -z "${JAVA_HOME:-}" ] || [ ! -d "${JAVA_HOME}" ]; then
  JAVA_HOME_DETECTED=$(dirname $(dirname $(readlink -f $(which java))))
  export JAVA_HOME=${JAVA_HOME_DETECTED%/jre}
fi
export ATLAS_HOME=/opt/atlas

# Clean stale PID file from previous container runs
rm -f ${ATLAS_HOME}/logs/atlas.pid

echo "JAVA_HOME=$JAVA_HOME (arch: $(uname -m))"

echo ""
echo "╔═══════════════════════════════════════════════════════════════════════╗"
echo "║                         🧭  Setting up Atlas...                       ║"
echo "╚═══════════════════════════════════════════════════════════════════════╝"
echo ""
# TODO: USE keycloak auth once baseimage updated
# set admin passwords
encryptedPwd=$(${ATLAS_HOME}/bin/cputil.py -g -u admin -p ${ATLAS_ADMIN_PASSWORD} -s)
echo "admin=ADMIN::${encryptedPwd}" > ${ATLAS_HOME}/conf/users-credentials.properties
# setup atlas properties
${ATLAS_HOME}/scripts/atlas-properties.sh
cd ${ATLAS_HOME}/bin

# TODO: Patch as part of image build
# patch files
patch --verbose --ignore-whitespace -N --fuzz 2 < ${ATLAS_HOME}/patches/atlas_start.py.patch; true
patch --verbose --ignore-whitespace -N --fuzz 2 < ${ATLAS_HOME}/patches/atlas_config.py.patch; true

if [ ! -e ${ATLAS_HOME}/state/.initDone ]
then
  INIT_ATLAS=true
else
  INIT_ATLAS=false
fi
echo "#############################################################################"
if [ "${INIT_ATLAS}" = "true" ]
then
  # TODO: improve initial setup time
  # initial setup run
  echo ""
  echo "╔═══════════════════════════════════════════════════════════════════════╗"
  echo "║                         ⚙️  Initialising Atlas...                     ║"
  echo "╚═══════════════════════════════════════════════════════════════════════╝"
  echo ""
  ${ATLAS_HOME}/bin/atlas_start.py & \
  tail -fF ${ATLAS_HOME}/logs/application.log | sed '/Defaulting to local host name/ q' \
  && sleep 10 \
  && ${ATLAS_HOME}/bin/atlas_stop.py \
  && truncate -s0 ${ATLAS_HOME}/logs/application.log

  touch ${ATLAS_HOME}/state/.initDone
  echo "Done initialising Atlas!"
  echo "#############################################################################"
fi

# check if seeding is needed
if [ "${SEED_ATLAS:-false}" = "true" ]; then
  echo ""
  echo "╔═══════════════════════════════════════════════════════════════════════════════════╗"
  echo "║                         🌱  Seeding and starting up Atlas...                      ║"
  echo "╚═══════════════════════════════════════════════════════════════════════════════════╝"
  echo ""
  # run, seed and log
  ${ATLAS_HOME}/scripts/atlas-import.sh & ${ATLAS_HOME}/bin/atlas_start.py; tail -fF ${ATLAS_HOME}/logs/application.log
else
  echo ""
  echo "╔═══════════════════════════════════════════════════════════════════════╗"
  echo "║                         🚀  Starting up Atlas...                      ║"
  echo "╚═══════════════════════════════════════════════════════════════════════╝"
  echo ""
  # run and log
  ${ATLAS_HOME}/bin/atlas_start.py; tail -fF ${ATLAS_HOME}/logs/application.log
fi
