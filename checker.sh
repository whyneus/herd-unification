#!/bin/bash

if [[ ! -f /etc/redhat-release ]]
then
  echo MANCHKREQ
  exit 1
fi

workdir=`getent passwd rack | cut -d: -f6`/2016-consolidation/
uptime=`cat /proc/uptime | cut -d. -f1`

if [[ ! -f ${workdir}/runpost ]]
then
  state="pre"
  service iptables save >/dev/null
  mkdir ${workdir}
  touch ${workdir}/runpost
else
  if [[ ${uptime} -lt 300 ]]
  then
    # sleep $((300-${uptime}))
    sleep 25
  fi
  state="post"

  backupagent=`which simpana 2>/dev/null`
  if [[ ! -z ${backupagent} ]]
  then
    echo restart simpana
    ${backupagent} restart >/dev/null
  fi
  sleep 10
fi

netstat -nutlp | awk -F'[ /]+' '/tcp/ {print $8}' | sort | column -t | uniq > ${workdir}/netstat-${state}
mount > ${workdir}/mount-${state}
ip a > ${workdir}/ip-${state}
iptables -nL > ${workdir}/iptables-${state}
iptables -t nat -nL > ${workdir}/iptablesnat-${state}
for i in `ls /etc/init.d/`; do /etc/init.d/${i} status 2&>1 >> ${workdir}/services-${state}; done;

if [[ ${state} == "post" ]]
then
  diff --suppress-common-lines -y ${workdir}/ip-pre ${workdir}/ip-post
  diff --suppress-common-lines -y ${workdir}/mount-pre ${workdir}/mount-post
  diff --suppress-common-lines -y ${workdir}/iptables-pre ${workdir}/iptables-post
  diff --suppress-common-lines -y ${workdir}/iptablesnat-pre ${workdir}/iptablesnat-post
  diff --suppress-common-lines -y ${workdir}/netstat-pre ${workdir}/netstat-post
  diff --suppress-common-lines -y ${workdir}/services-pre ${workdir}/services-post | egrep -v 'pid.*pid|Chain|^Table\:'
  echo POST check done.
else
  echo PRE check done.
fi
