#!/bin/sh
set -e

BACKUPDIR='/opt/backup/etcd'

ORIG=$(cd $(dirname $0); pwd)

eval $(${ORIG}/get_env.py)
ETCD="etcdctl --cert-file ${etcd_certFile} --key-file ${etcd_keyFile} --ca-file ${etcd_ca} --no-sync --peers ${etcd_url}"

$ETCD ls --recursive

hotdir="${BACKUPDIR}/hot/$(date +%Y%m%d%H%M).etcd"
mkdir -p $hotdir

echo "backuping the data directory to $hotdir"
$ETCD backup --data-dir $etcd_storage --backup-dir $hotdir
echo
du -ksh $hotdir
find $hotdir
