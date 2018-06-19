#!/bin/bash

# https://social.imirhil.fr/@aeris
  # stream 60 IN A 163.172.46.173
  # stream 60 IN AAAA 2001:bc8:3f23:200::1
  # stream 60 IN A 163.172.218.10
  # stream 60 IN AAAA 2001:bc8:3f23:1100::1
  # stream 60 IN A 51.15.35.75
  # stream 60 IN AAAA 2001:bc8:4700:2500::fa5
# https://framapiaf.org/@framasky
  # stream 60 IN A 195.201.54.108
  # stream 60 IN AAAA 2a01:4f8:13b:20d6::108
# https://mastodon.social/@blequerrec
  # stream 60 IN A 51.15.57.54
  # stream 60 IN AAAA 2001:bc8:4700:2300::24:917
# https://twitter.com/huguesdelamure
  # 130.117.11.12
  # 2a0b:cbc0:1103:1::a

HOST=stream.passageenseine.fr

echo "Upstream"
printf "  IPv4:\t"
curl -sS4I -m 10 https://upstream.passageenseine.fr/index.m3u8 | head -1
printf "  IPv6:\t"
curl -sS6I -m 10 https://upstream.passageenseine.fr/index.m3u8 | head -1

echo "IPv4 mirrors"
dig A +short "${HOST}" | while read IP; do
  printf "  ${IP}:\t"
  curl -sS4I -m 10 --resolve "${HOST}:443:${IP}" "https://${HOST}/index.m3u8" | head -1
done

echo "IPv6 mirrors"
dig AAAA +short "${HOST}" | while read IP; do
  printf "  ${IP}:\t"
  curl -sS6I -m 10 --resolve "${HOST}:443:${IP}" "https://${HOST}/index.m3u8" | head -1
done
