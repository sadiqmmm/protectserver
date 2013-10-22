# Testing the UDP flood attack  = grep -ir 'fsockopen.*udp' /home/

#!/bin/sh
echo "Flushing iptables and allowing everything..."
iptables -F
iptables -X
iptables -t nat -F
iptables -t nat -X
iptables -t mangle -F
iptables -t mangle -X
iptables -P INPUT ACCEPT
iptables -P FORWARD ACCEPT
iptables -P OUTPUT ACCEPT
 
echo "Applying iptables baseline rules..."
# Deny everything on the default INPUT chain
iptables -P INPUT DROP
 
# Allow connections that are already connected to the server.
iptables -A INPUT -i eth0 -m state --state ESTABLISHED,RELATED -j ACCEPT
iptables -A INPUT -i eth1 -m state --state ESTABLISHED,RELATED -j ACCEPT
iptables -A INPUT -i lo -j ACCEPT
 
# #########################
# Outbound UDP Flood protection in a user defined chain.
iptables -N udp-flood
iptables -A OUTPUT -p udp -j udp-flood
iptables -A udp-flood -p udp -m limit --limit 200/s -j RETURN
iptables -A udp-flood -j LOG --log-level 4 --log-prefix 'UDP-flood attempt: '
iptables -A udp-flood -j DROP
 
# #########################
# SYN-Flood protection in a user defined chain
iptables -N syn-flood
iptables -A INPUT -p tcp --syn -j syn-flood
iptables -A syn-flood -m limit --limit 30/s --limit-burst 60 -j RETURN
iptables -A syn-flood -j LOG --log-level 4 --log-prefix 'SYN-flood attempt: '
iptables -A syn-flood -j DROP
 
# #########################
# SSH
# Rate limit SSH on 57328
iptables -A INPUT -p tcp --dport 57328 -m state --state NEW -m recent --set --name SSH-LIMIT
iptables -A INPUT -p tcp --dport 57328 -m state --state NEW -m recent --update --rttl --seconds 60 --hitcount 20 -j REJECT --reject-with tcp-reset --name SSH-LIMIT

# Allow SSH on 57328 port
iptables -A INPUT -p tcp --dport 57328 -j ACCEPT 


# #########################
# HTTP
# Allow HTTP and HTTPS
iptables -A INPUT -p tcp --dport 80 -j ACCEPT
iptables -A INPUT -p tcp --dport 11001 -j ACCEPT
iptables -A INPUT -p tcp --dport 443 -j ACCEPT
 
# If we made it this far the packet will be dropped - so log it as denied.
iptables -A INPUT -j LOG --log-level 4 --log-prefix 'Denied: '
