#!/bin/bash

# Return the mode from config file
getModeFunction() {
  local mode=prod
  if [ -f "$NETFILTER/private/config.yaml" ]; then
    mode=`cat $NETFILTER/private/config.yaml | sed -En 's/ *mode: *\"*([a-fA-F]*)\"*/\1/p'`
    if [ "$mode" != "test" ] && [ "$mode" != "beta" ] && [ "$mode" != "prod" ]; then
        mode=prod
    fi
  fi
  echo $mode
}

# setup systemd services
#
setup() {

  if [ ! -d "$NETFILTER/bin" ]; then
    mkdir $NETFILTER/bin
    chmod 0770 $NETFILTER/bin
  fi

  local mode=`getModeFunction`
  local dir=$NETFILTER/netfilter_${mode}

  tag=`git -C $dir describe --tags`
  echo "netfilter running setup release=$tag"

  local publicip=`cat $NETFILTER/private/config.yaml | sed -En 's/ *publicip: *\"*([a-fA-F]*)\"*/\1/p'`
  curl https://api.blockthekids.com/admin/log?function=prodsetup\&publicip=${publicip}\&release=${tag}

  local restart=0
  local systemd_dir=/etc/systemd/system

  diff -q ${systemd_dir}/netfilter.service ${dir}/etc/netfilter.service
  if [ $? != 0 ]; then
    rm -f ${systemd_dir}/netfilter.service
    cp -v ${dir}/etc/netfilter.service ${systemd_dir}/netfilter.service
    restart=1
  fi

  diff -q $NETFILTER/bin/setup.sh ${dir}/etc/setup.sh
  if [ $? != 0 ]; then
    rm -f ${NETFILTER}/bin/setup.sh
    cp -v ${dir}/etc/setup.sh ${NETFILTER}/bin/setup.sh
    chmod +x ${NETFILTER}/bin/setup.sh
    restart=1
  fi

  rm -f ${systemd_dir}/netfilter.script # no longer needed
  rm -f ${dir}/bin/netfilter.script # no longer needed
  #diff -q ${systemd_dir}/netfilter.script ${dir}/etc/netfilter.script
  #if [ $? != 0 ]; then
    #rm -f ${systemd_dir}/netfilter.script
    #cp ${dir}/etc/netfilter.service ${systemd_dir}/netfilter.script
    #restart=1
  #fi


  diff -q ${systemd_dir}/netfilter.download.service ${dir}/etc/netfilter.download.service
  if [ $? != 0 ]; then
    rm -f ${systemd_dir}/download.service # cleanup old service
    rm -f ${systemd_dir}/netfilter.download.service
    cp -v ${dir}/etc/netfilter.download.service ${systemd_dir}/netfilter.download.service
    restart=1
  fi

  diff -q $NETFILTER/bin/netfilter.download.script ${dir}/etc/netfilter.download.script
  if [ $? != 0 ]; then
    rm -f ${NETFILTER}/bin/netfilter.download.script
    cp -v ${dir}/etc/netfilter.download.script ${NETFILTER}/bin/netfilter.download.script
    chmod +x ${NETFILTER}/bin/netfilter.download.script
    restart=1
  fi

  diff -q ${systemd_dir}/netfilter.download.timer ${dir}/etc/netfilter.download.timer
  if [ $? != 0 ]; then
    rm -f ${systemd_dir}/download.timer # remove old service
    rm -f ${systemd_dir}/netfilter.download.timer
    cp -v ${dir}/etc/netfilter.download.timer ${systemd_dir}/netfilter.download.timer
    restart=1
  fi

  diff -q $NETFILTER/bin/firewall.sh ${dir}/etc/firewall.sh
  if [ $? != 0 ]; then
    rm -f ${NETFILTER}/bin/firewall.sh
    cp -v ${dir}/etc/firewall.sh ${NETFILTER}/bin/firewall.sh
    restart=1
  fi

  # DONT update syslogd with unique mac
  loggly=/etc/rsyslog.d/22-loggly.conf
  rm -f $loggly # remove old file

  local curversion=`$NETFILTER/bin/netfilter -v`
  if [ $? -ne 0 ]; then
    curversion="noversion"
  fi

  local newversion=`${NETFILTER}/netfilter_${mode}/bin/netfilter -v`
  if [ $? -ne 0 ]; then
    newversion="noversion"
  fi

  if [ "$curversion" != "$newversion" ]; then
    cp -v ${NETFILTER}/netfilter_${mode}/bin/netfilter ${NETFILTER}/bin/netfilter
    restart=1
  fi

  if [ $restart -eq 1 ]; then
    echo "netfilter updated to $newversion in $mode. Restarting...."
    /bin/systemctl daemon-reload
    systemctl enable rsyslog.service
    systemctl enable netfilter.download.timer
    systemctl enable netfilter.download.service
    systemctl enable netfilter.service
    systemctl restart netfilter.service
    systemctl restart netfilter.download.timer
    #systemctl restart rsyslog.service
  else 
    echo "netfilter no changes using version $curversion in $mode"
  fi 
}

#
# Setup netfilter
#
NETFILTER=/home/netfilter

if [ ! -d "$NETFILTER/private" ]; then
  mkdir $NETFILTER/private
  chmod 0700 $NETFILTER/private
fi

case $1 in
  setup)  "$1" ;;
  *) 
    echo "nothing to do - use setup.sh setup"
  ;;
esac
