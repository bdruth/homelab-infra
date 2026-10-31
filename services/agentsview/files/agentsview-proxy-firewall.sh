#!/bin/sh
# Synology rc.d boot hook and Ansible convergence. This Docker version runs
# docker-proxy for published sockets, so remote clients can arrive on INPUT.
# Keep a DOCKER-USER rule as well for any DNAT-forwarded path.
set -eu

case "${1:-start}" in
  start|restart)
    /usr/sbin/iptables -C INPUT -d 192.168.7.211 -p tcp --dport 18080 \
      ! -s 192.168.7.198 -j DROP 2>/dev/null ||
    /usr/sbin/iptables -I INPUT 1 -d 192.168.7.211 -p tcp --dport 18080 \
      ! -s 192.168.7.198 -j DROP
    # Docker may create this chain after Synology runs rc.d at boot. INPUT is
    # the effective guard for docker-proxy and is installed first above.
    if /usr/sbin/iptables -S DOCKER-USER >/dev/null 2>&1; then
      /usr/sbin/iptables -C DOCKER-USER -p tcp -m conntrack \
        --ctorigdst 192.168.7.211 --ctorigdstport 18080 \
        ! -s 192.168.7.198 -j DROP 2>/dev/null ||
      /usr/sbin/iptables -I DOCKER-USER 1 -p tcp -m conntrack \
        --ctorigdst 192.168.7.211 --ctorigdstport 18080 \
        ! -s 192.168.7.198 -j DROP
    fi
    ;;
  stop) ;;
  *) exit 2 ;;
esac
