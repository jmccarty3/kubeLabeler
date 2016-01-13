#!/bin/bash
set -e

[[ -v NODENAME ]] || (echo "Nodename not set" && exit 1)
RAW_LABELS=$1

LABELS=( ${RAW_LABELS//,/ } )
data=$(curl -s http://$KUBEMASTER_URL/api/v1/nodes/$NODENAME | jq -r 'select(.metadata.labels)|.metadata.labels| {"metadata": { "labels" : .metadata.labels}}' )

if [ -z "$data" ]; then
  echo 'No labels returned for Node. Likely not found'
  exit 1
fi

for label in ${LABELS[@]}
do
  key=${label%=*}
  value=${label#*=}
  data=$(echo $data | jq -r --arg key "$key" --arg value "$value" '.metadata.labels +={ ($key):$value }')
  echo $?
done

curl -v -X PATCH -d "$data" -H "Content-Type: application/strategic-merge-patch+json" http://$KUBEMASTER_URL/api/v1/nodes/$NODENAME

