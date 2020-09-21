#!/bin/bash


KEY="~/.ssh/id_rsa"
REMOTEDIR="/mnt/backup"
LOCALDIR="/root/ocp/backup_masters"
OCPUSER=`oc whoami 2>/dev/null`
MASTERS=`oc get nodes -o wide | grep master | awk '{print $6}'`

OCP_LOGIN(){

        oc login -u system:admin
}

OCP_BACKUP(){

        for NODE in $MASTERS;
        do
             mkdir $LOCALDIR/$NODE >/dev/null 2>&1
             ssh -i $KEY core@$NODE mkdir $REMOTEDIR >/dev/null 2>&1
             ssh -i $KEY core@$NODE sudo /usr/local/bin/cluster-backup.sh $REMOTEDIR
             ssh -i $KEY core@$NODE sudo chown -R core:core $REMOTEDIR
             rsync -avz -e "ssh -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -i $KEY" core@$NODE:$REMOTEDIR/* $LOCALDIR/$NODE
        done
}

RETENTATION_POLICY(){

        # MASTERS
        for NODE in $MASTERS;
        do
             ssh -i $KEY core@$NODE sudo find $REMOTEDIR/* -type f -mtime +3 -delete
        done

        # LOCAL
        find $LOCALDIR/* -type f -mtime +3 -delete

}


if [ "$OCPUSER" == "system:admin" ];
then
        OCP_BACKUP
        RETENTATION_POLICY
else
        OCP_LOGIN
        OCP_BACKUP
        RETENTATION_POLICY
fi
