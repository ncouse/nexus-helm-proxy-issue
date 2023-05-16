#!/bin/sh

BASE_URL=${NEXUS_BASE_URL:-http://localhost:8182}
NEXUS_DATA_DIR=${NEXUS_DATA_DIR:-/nexus-data}
NEW_PASSWORD=${NEXUS_PASSWORD:-MyAdminPassword}
CONFIG_ROOT_DIR=${CONFIG_ROOT_DIR:-/config}

echo "Starting setup"

# The first time you run, the admin password is in a file, and we will use this to set up
if [ ! -e ${NEXUS_DATA_DIR}/admin.password ]
then
    echo "Password file does not exist. No initialisation to perform. Exiting."
    exit 0
fi
PASS=$(cat ${NEXUS_DATA_DIR}/admin.password)
echo "Password: ${PASS}"

# Change password
curl -vfsSL -X 'PUT' \
  "${BASE_URL}/service/rest/v1/security/users/admin/change-password" \
  -u "admin:${PASS}" \
  -H 'accept: application/json' \
  -H 'Content-Type: text/plain' \
  -d "${NEW_PASSWORD}"

# Enable anonymous access
curl -vfsSL -X 'PUT' \
  "${BASE_URL}/service/rest/v1/security/anonymous" \
  -u "admin:${NEW_PASSWORD}" \
  -H 'accept: application/json' \
  -H 'Content-Type: application/json' \
  -d "$(cat ${CONFIG_ROOT_DIR}/other/anon-access.json)"

# Create the repositoroes
for REPO_JSON_FILE in $(find ${CONFIG_ROOT_DIR}/repos/helm-proxy -type f)
do
    echo "Repo Config: ${REPO_JSON_FILE}"
    REPO_JSON="$(cat ${REPO_JSON_FILE})"

    curl -vfsSL -X 'POST' \
        "${BASE_URL}/service/rest/v1/repositories/helm/proxy" \
        -u "admin:${NEW_PASSWORD}" \
        -H 'accept: application/json' \
        -H 'Content-Type: application/json' \
        -d "${REPO_JSON}"
done

echo "Complete"

echo "Password: ${NEW_PASSWORD}"


