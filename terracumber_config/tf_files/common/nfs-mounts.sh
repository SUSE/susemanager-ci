#! /bin/bash

for dir in 'repo/$RCE/RES7' \
           'repo/$RCE/RES7-SUSE-Manager-Tools' \
           'repo/$RCE/RES7-SUSE-Manager-Tools-Beta' \
           'SUSE/Updates/RES' \
           'SUSE/Updates/RES-CB' \
           'SUSE/Updates/RES-AS' \
           'SUSE/Products/RES' \
           'repositories/systemsmanagement:/Uyuni:/Stable:/CentOS7-Uyuni-Client-Tools/CentOS_7' \
           'repositories/systemsmanagement:/Uyuni:/Stable:/CentOS8-Uyuni-Client-Tools/CentOS_8'; do
  echo "minima-mirror-bv2.mgr.prv.suse.net:/srv/mirror/$dir  /mirror/$dir  nfs  defaults  0 0" >> /etc/fstab
  mount "/mirror/$dir"
done

#for dir in 'distribution/leap/15.3' \
#           'update/leap/15.3' \
#           'SUSE/Products/SLE-Manager-Tools/15/aarch64' \
#           'SUSE/Products/SLE-Manager-Tools/15-BETA/aarch64' \
#           'SUSE/Updates/SLE-Manager-Tools/15/aarch64' \
#           'SUSE/Updates/SLE-Manager-Tools/15-BETA/aarch64' \
#           'repositories/systemsmanagement:/sumaform:/tools/openSUSE_Leap_15.3' \
#           'repositories/systemsmanagement:/Uyuni:/Stable:/openSUSE_Leap_15-Uyuni-Client-Tools'; do
#  echo "minima-mirror-bv3.mgr.prv.suse.net:/srv/mirror/$dir  /mirror/$dir  nfs  defaults  0 0" >> /etc/fstab
#  mount "/mirror/$dir"
#done
