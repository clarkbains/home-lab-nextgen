#!/bin/bash
set -e

input=$(cat)
private_key=$(echo "$input" | jq -r '.private_key')
user=$(echo "$input" | jq -r '.user')
host=$(echo "$input" | jq -r '.host')
client_name=$(echo "$input" | jq -r '.client_name')
pool=$(echo "$input" | jq -r '.pool')

ssh_private_key_file=`mktemp`

chmod 600 $ssh_private_key_file
echo $private_key | base64 --decode > $ssh_private_key_file
cat << EOF | ssh -o "StrictHostKeyChecking=no" -i $ssh_private_key_file $user@$host bash -s
echo "{\"token\":\"\`ceph auth get-key client.admin\`\",\"id\":\"\`ceph fsid\`\",\"client\":\"admin\",\"pool\":\"$pool\"}"
EOF

rm $ssh_private_key_file

