# Netfilter 
#
# Change host IP address
# Setup forward, routing and iptables
# 
# Syntax: sh firewall.sh <interface> <router_ip> <cidr> <host>
#
# Example: 
# firewall.sh eth0 192.168.0.1 192.168.0.0/25 192.168.0.129

if [ "$1" != "" ]; then
    DEV=$1
else
    DEV=eth0  # raspberry pi
    #DEV=enp14s0
fi
echo "Interface:" $DEV

if [ "$2" != "" ]; then
    ROUTER=$2
else
    ROUTER=192.168.1.1
fi
echo "Router:" $ROUTER

if [ "$3" != "" ]; then
    CIDR=$3
else
    CIDR=192.168.1.0/25
fi
echo "CIDR:" $CIDR

if [ "$4" != "" ]; then
    HOST=$4
else
    HOST=192.168.1.129
fi
echo "Host:" $HOST

# enable IP forwarding
#sudo echo 1 | sudo tee /proc/sys/net/ipv4/ip_forward

# disable ICMP redirects
# to prevent client sending directly to the gateway
#echo 0 | sudo tee /proc/sys/net/ipv4/conf/*/send_redirects 

#sudo modprobe ip_tables
#sudo modprobe ip_conntrack


# disable DHCP client
# see: https://help.ubuntu.com/community/NetworkConfigurationCommandLine/Automatic
#sudo /etc/init.d/network-manager stop
#sudo /etc/init.d/wicd stop

# remove from init.d
# sudo update-rc.d -f NetworkManager remove
# Reverse: sudo update-rc.d -f NetworkManager defaults 50


#sudo iptables -t nat -F
#sudo iptables -t filter -F 


# Setup eth interface
sudo ifconfig $DEV $HOST down
sudo ifconfig $DEV $HOST netmask 255.255.255.0 up 
sudo route add $ROUTER $DEV
sudo route add default gw $ROUTER $DEV

#sudo iptables -N NETFILTER
#sudo iptables -A FORWARD -j NETFILTER

# NAT all DNS requests : this should be the first rule
#sudo iptables -t nat -I POSTROUTING -o $DEV -p udp --dport 53 -j SNAT --to $HOST
#sudo iptables -t nat -I POSTROUTING -o $DEV -p tcp --dport 53 -j SNAT --to $HOST
#sudo iptables -I FORWARD -o $DEV -p udp --dport 53 -m state --state RELATED,ESTABLISHED -j ACCEPT
#sudo iptables -I FORWARD -o $DEV -p tcp --dport 53 -m state --state RELATED,ESTABLISHED -j ACCEPT

# to delete a rule
#sudo iptables -D NETFILTER -s 192.168.0.133 -d 192.168.0.1 -j DROP

# don't need nat, just forwarding will do
#sudo iptables -t nat -A POSTROUTING -o $DEV -s $CIDR -j SNAT --to-source $HOST

#sudo route add default gw $ROUTER $DEV:0


#SSH
#sudo iptables -A INPUT -p tcp --dport ssh -j ACCEPT
#sudo iptables -A OUTPUT -p tcp --sport 22 -j ACCEPT

# Restart syslogd afte interface change
#sudo service rsyslog restart

#
# need to stop dhclient to release bootpc port (68 - client)
#sudo  netstat -tulpn
#netfilter -i enp14s0 -gw ec2-54-252-189-238.ap-southeast-2.compute.amazonaws.com -net 192.168.0.0/24


# Delete lines
# second IP
#sudo ifconfig $DEV:0 $DUALIP netmask 255.255.255.0 up

#sudo iptables -t nat -A POSTROUTING -o enp14s0 -s 192.168.1.0/24 -j SNAT --to 192.168.1.1
#sudo iptables -t filter -A FORWARD -p tcp -d 192.168.1.1 --dport 80 -j ACCEPT 
