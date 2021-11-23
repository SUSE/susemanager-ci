#! /bin/bash

echo 'minima-mirror-bv2.mgr.prv.suse.net:/srv/mirror/repo/$RCE/RES7  /mirror/repo/$RCE/RES7  nfs  defaults  0 0' >> /etc/fstab
mount '/mirror/repo/$RCE/RES7'

echo 'minima-mirror-bv2.mgr.prv.suse.net:/srv/mirror/repo/$RCE/RES7-SUSE-Manager-Tools  /mirror/repo/$RCE/RES7-SUSE-Manager-Tools  nfs  defaults  0 0' >> /etc/fstab
mount '/mirror/repo/$RCE/RES7-SUSE-Manager-Tools'

echo 'minima-mirror-bv2.mgr.prv.suse.net:/srv/mirror/repo/$RCE/RES7-SUSE-Manager-Tools-Beta  /mirror/repo/$RCE/RES7-SUSE-Manager-Tools-Beta  nfs  defaults  0 0' >> /etc/fstab
mount '/mirror/repo/$RCE/RES7-SUSE-Manager-Tools-Beta'

echo 'minima-mirror-bv2.mgr.prv.suse.net:/srv/mirror/SUSE/Updates/RES  /mirror/SUSE/Updates/RES  nfs  defaults  0 0' >> /etc/fstab
mount '/mirror/SUSE/Updates/RES'

echo 'minima-mirror-bv2.mgr.prv.suse.net:/srv/mirror/SUSE/Updates/RES-CB  /mirror/SUSE/Updates/RES-CB  nfs  defaults  0 0' >> /etc/fstab
mount '/mirror/SUSE/Updates/RES-CB'

echo 'minima-mirror-bv2.mgr.prv.suse.net:/srv/mirror/SUSE/Updates/RES-AS  /mirror/SUSE/Updates/RES-AS  nfs  defaults  0 0' >> /etc/fstab
mount '/mirror/SUSE/Updates/RES-AS'

echo 'minima-mirror-bv2.mgr.prv.suse.net:/srv/mirror/SUSE/Products/RES  /mirror/SUSE/Products/RES  nfs  defaults  0 0' >> /etc/fstab
mount '/mirror/SUSE/Products/RES'

echo 'minima-mirror-bv2.mgr.prv.suse.net:/srv/mirror/repositories/systemsmanagement:/Uyuni:/Stable:/CentOS7-Uyuni-Client-Tools/CentOS_7  /mirror/repositories/systemsmanagement:/Uyuni:/Stable:/CentOS7-Uyuni-Client-Tools/CentOS_7  nfs  defaults  0 0' >> /etc/fstab
mount /mirror/repositories/systemsmanagement:/Uyuni:/Stable:/CentOS7-Uyuni-Client-Tools/CentOS_7

echo 'minima-mirror-bv2.mgr.prv.suse.net:/srv/mirror/repositories/systemsmanagement:/Uyuni:/Stable:/CentOS8-Uyuni-Client-Tools/CentOS_8  /mirror/repositories/systemsmanagement:/Uyuni:/Stable:/CentOS8-Uyuni-Client-Tools/CentOS_8  nfs  defaults  0 0' >> /etc/fstab
mount /mirror/repositories/systemsmanagement:/Uyuni:/Stable:/CentOS8-Uyuni-Client-Tools/CentOS_8

echo 'minima-mirror-bv3.mgr.prv.suse.net:/srv/mirror/distribution/leap/15.3  /mirror/distribution/leap/15.3  nfs  defaults  0 0' >> /etc/fstab
mount /mirror/distribution/leap/15.3

echo 'minima-mirror-bv3.mgr.prv.suse.net:/srv/mirror/repositories/systemsmanagement:/sumaform:/tools/openSUSE_Leap_15.3  /mirror/repositories/systemsmanagement:/sumaform:/tools/openSUSE_Leap_15.3  nfs  defaults  0 0' >> /etc/fstab
mount /mirror/repositories/systemsmanagement:/sumaform:/tools/openSUSE_Leap_15.3
