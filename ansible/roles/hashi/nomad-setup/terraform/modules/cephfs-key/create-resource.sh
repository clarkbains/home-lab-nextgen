#!/bin/bash
set -e


ssh_private_key_file=`mktemp`
chmod 600 $ssh_private_key_file
echo $private_key | base64 --decode > $ssh_private_key_file

cat << EOF | ssh -o "StrictHostKeyChecking=no" -i $ssh_private_key_file $user@$host bash -s
ceph fs authorize $pool client.nomad-$client_name $client_path rw -f json | jq -r '.[0].key'
EOF

rm $ssh_private_key_file
