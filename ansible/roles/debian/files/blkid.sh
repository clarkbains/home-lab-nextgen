#!/bin/bash
if [[ $# -ne 2 ]]; then
    echo "Usage: $0 <type> <slot>"
    exit 128
fi

TYPE=$1
SLOT=$2

if [[ "$TYPE" -eq "scsi" ]]; then
    SERIAL="drive-$TYPE$SLOT"
else
    echo "$TYPE not supported"
    exit 1
fi

DRIVE_ID="`lsblk --$TYPE | awk -v "d=$SERIAL" ' { if($8 == d) { print $1 } } '`"
if [[ -z $DRIVE_ID ]]; then
    echo "Cannot find drive id $TYPE $SLOT `lsblk --$TYPE`"
    exit 1
fi

echo -n "/dev/$DRIVE_ID"