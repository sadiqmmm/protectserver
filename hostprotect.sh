#!/bin/bash
 
HOST=`hostname`
INTERFACE=eth0
DUMPDIR=~/dump/
SUBJECT="WARNING:Packet alert on $HOST"
EMAIL="youraddress@yoursite.com"
EMAILMESSAGE="~/dump/emailmessage.txt"
 
# print $2 for inbound packets, $10 for outbound
 
while /bin/true; do
  pkt_old=`grep $INTERFACE: /proc/net/dev | cut -d :  -f2 | awk '{ print $10 }'`
  sleep 1
  pkt_new=`grep $INTERFACE: /proc/net/dev | cut -d :  -f2 | awk '{ print $10 }'`
 
  pkt=$(( $pkt_new - $pkt_old ))
  echo -ne "\r$pkt outbound packets/s\033[0K"
 
  if [ $pkt -gt 250 ]; then
    echo -e "\n`date` Peak rate exceeded, dumping packets."
    tcpdump -n -s0 -c 2000 -w $DUMPDIR/dump.`date +"%Y%m%d-%H%M%S"`.cap
    echo "`date` Packets dumped, sleeping now."
    echo "Packet rate was $pkt packets/s at `date`"  &gt; $EMAILMESSAGE
    /usr/bin/mail -s "$SUBJECT" "$EMAIL" &lt; $EMAILMESSAGE
     sleep 150
  fi
done
