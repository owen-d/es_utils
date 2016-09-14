#!/bin/bash
# utility, adjust as needed
set -e

#params
SUFFIX=${SUFFIX-_dev}
echo "using SUFFIX $SUFFIX"
OLD_SUFFIX=${OLD_SUFFIX-_old}
# Define $ES_URL, $MYSQL_HOST, $MYSQL_USER, $MYSQL_PASS, $MYSQL_DB, $MAPPING, $SQL, $MAPPER, $ALIAS, $TYPE, and $ROTATE if you want aliases to be rotated
# Optionally define $BATCH_SIZE, $ID_FIELD, $SUFFIX, $OLD_SUFFIX


create_new_mapping() {
  UUID="`./sync-worker/mkUuid`"
  echo "Using new index $UUID"
  ../lib/cloneIndex -o $ALIAS -n $UUID -u $ES_URL -s
  ../lib/putMapping -i $UUID -t $TYPE -u $ES_URL --mapping=$MAPPING
  ../lib/export -q "`cat $SQL`" -t $TYPE -b $BATCH_SIZE --id=$ID_FIELD -i $UUID -u $ES_URL -m $MAPPER --mysqlHost=$MYSQL_HOST --mysqlUser=$MYSQL_USER --mysqlPass=$MYSQL_PASS --mysqlDb=$MYSQL_DB

  if [[ ! -z $ROTATE ]];
    then
      # set default vars
      BATCH_SIZE=${BATCH_SIZE:-100}
      ID_FIELD=${ID_FIELD:-uuid}

      echo "deleting prior old index"
      curl -s -XDELETE ${ES_URL}/${ALIAS}${OLD_SUFFIX}
      echo
      echo "rotating to old suffix"
      ./rotateAlias -a ${ALIAS}${OLD_SUFFIX} -n $ALIAS -u $ES_URL
      echo "promoting $UUID to $ALIAS"
      ./rotateAlias -a $ALIAS -n $UUID -u $ES_URL
      echo "closing ${ALIAS}${OLD_SUFFIX}"
      curl -s -XPOST ${ES_URL}/${ALIAS}${OLD_SUFFIX}/_close
  fi
}
