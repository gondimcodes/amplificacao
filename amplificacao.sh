#!/usr/bin/env bash
# Script de checagem de portas de amplificacao abertas.
# Eh uma contribuicao e nao me responsabilizo por quaisquer danos causados
# pelo uso desse script.
# Autor: Marcelo Gondim - gondim at gmail.com
# Data: 18/02/2023
# Versao: 2.6
#
vermelho='\033[0;31m'
verde='\033[0;32m'
semcor='\033[0m'
azul='\033[0;34m'

if [ -z $1 ]; then
   echo "Faltou o IP de busca!"
   exit
fi

programas=(
host
nmap
nmblookup
nc
rpcinfo
curl
dig
snmpget
ntpq
ldapsearch
hexdump
fping
)

for programa in "${programas[@]}"
do
   if [ -z "`type $programa 2> /dev/null`" ]; then
      echo "Nao tem instalado o programa $programa!"
      exit
   fi
done

netbios() {
echo -e "Testando NETBIOS (137/udp): \c"
if [ "`nmblookup -A $1 | grep -i \"No reply from\"`" == "" ]; then
   echo -e "${vermelho}Aberta${semcor}"
else
   if [ "`fping $1 2> /dev/null | grep -i 'alive'`" != "" ]; then
      echo -e "${verde}Fechada${semcor}"
   else
      echo -e "${azul}Inconclusivo${semcor}"
   fi
fi
}

dhcpdiscover() {
echo -e "Testando DVR-DHCPDiscover (37810/udp): \c"
if [ "`echo -n \"\\xff\" | nc -w 3 -u $1 37810 | hexdump -C`" != "" ]; then
   echo -e "${vermelho}Aberta${semcor}"
else
   if [ "`fping $1 2> /dev/null | grep -i 'alive'`" != "" ]; then
      echo -e "${verde}Fechada${semcor}"
   else
      echo -e "${azul}Inconclusivo${semcor}"
   fi
fi
}

rpc() {
echo -e "Testando RPC (111/udp): \c"
if [ "`rpcinfo -T udp -p $1 2> /dev/null`" != "" ]; then
   echo -e "${vermelho}Aberta${semcor}"
else
   if [ "`fping $1 2> /dev/null | grep -i 'alive'`" != "" ]; then
      echo -e "${verde}Fechada${semcor}"
   else
      echo -e "${azul}Inconclusivo${semcor}"
   fi
fi
}

arms() {
echo -e "Testando ARMS (3283/udp): \c"
if [ "`printf \"\\x00\\x14\\x00\\x01\\x03\" | nc -w 3 -u $1 3283 | hexdump -C`" != "" ]; then
   echo -e "${vermelho}Aberta${semcor}"
else
   if [ "`fping $1 2> /dev/null | grep -i 'alive'`" != "" ]; then
      echo -e "${verde}Fechada${semcor}"
   else
      echo -e "${azul}Inconclusivo${semcor}"
   fi
fi
}

tftp() {
echo -e "Testando TFTP (69/udp): \c"
if [ "`curl -m 3 tftp://$1/a.pdf 2>&1 | grep -i \"File Not Found\"`" != "" ]; then
   echo -e "${vermelho}Aberta${semcor}"
else
   if [ "`fping $1 2> /dev/null | grep -i 'alive'`" != "" ]; then
      echo -e "${verde}Fechada${semcor}"
   else
      echo -e "${azul}Inconclusivo${semcor}"
   fi
fi
}

dns() {
echo -e "Testando DNS (53/udp): \c"
if [ -z "`host -W 5 google.com $1|grep -i \"connection timed out\"`" ]; then
   if [ -z "`host -W 5 google.com $1|grep SERVFAIL`" -a -z "`host -W 5 google.com $1|grep REFUSED`" ]; then
      echo -e "${vermelho}Aberta${semcor}"
   else
      echo -e "${verde}Fechada${semcor}"
   fi
else
   if [ "`fping $1 2> /dev/null | grep -i 'alive'`" != "" ]; then
      echo -e "${verde}Fechada${semcor}"
   else
      echo -e "${azul}Inconclusivo${semcor}"
   fi
fi
}

mdns() {
echo -e "Testando Multicast DNS (5353/udp): \c"
if [ "`dig +timeout=1 @$1 -p 5353 ptr _services._dns-sd._udp.local | grep -i \"connection timed out\"`" == "" ]; then
   echo -e "${vermelho}Aberta${semcor}"
else
   if [ "`fping $1 2> /dev/null | grep -i 'alive'`" != "" ]; then
      echo -e "${verde}Fechada${semcor}"
   else
      echo -e "${azul}Inconclusivo${semcor}"
   fi
fi
}

ssdp() {
echo -e "Testando SSDP (1900/udp): \c"
if [ "`printf \"M-SEARCH * HTTP/1.1\\r\\nHost:239.255.255.250:1900\\r\\nST:upnp:rootdevice\\r\\nMan:\\"ssdp:discover\\"\\r\\nMX:3\\r\\n\\r\\n\" | nc -w 3 -u $1 1900 | hexdump -C`" != "" ]; then
   echo -e "${vermelho}Aberta${semcor}"
else
   if [ "`fping $1 2> /dev/null | grep -i 'alive'`" != "" ]; then
      echo -e "${verde}Fechada${semcor}"
   else
      echo -e "${azul}Inconclusivo${semcor}"
   fi
fi
}

snmp() {
echo -e "Testando SNMP (161/udp): \c"
if [ "`snmpget -v 2c -c public $1 iso.3.6.1.2.1.1.1.0 2> /dev/null`" != "" ]; then
   echo -e "${vermelho}Aberta${semcor}"
else
   if [ "`fping $1 2> /dev/null | grep -i 'alive'`" != "" ]; then
      echo -e "${verde}Fechada${semcor}"
   else
      echo -e "${azul}Inconclusivo${semcor}"
   fi
fi
}

ntp() {
echo -e "Testando NTP (123/udp): \c"
if [ "`ntpq -c rv $1 2>&1 | grep -i \"timed out\"`" == "" ]; then
   echo -e "${vermelho}Aberta${semcor}"
else
   if [ "`fping $1 2> /dev/null | grep -i 'alive'`" != "" ]; then
      echo -e "${verde}Fechada${semcor}"
   else
      echo -e "${azul}Inconclusivo${semcor}"
   fi
fi
}

ldap() {
echo -e "Testando LDAP (389/udp): \c"
if [ "`ldapsearch -x -h $1 -s base 2> /dev/null | hexdump -C`" != "" ]; then
   echo -e "${vermelho}Aberta${semcor}"
else
   if [ "`fping $1 2> /dev/null | grep -i 'alive'`" != "" ]; then
      echo -e "${verde}Fechada${semcor}"
   else
      echo -e "${azul}Inconclusivo${semcor}"
   fi
fi
}

ubnt() {
echo -e "Testando UBNT (10001/udp): \c"
if [ "`printf  \"\\x01\\x00\\x00\\x00\" | nc -w 3 -u $1 10001 | hexdump -C`" != "" ]; then
   echo -e "${vermelho}Aberta${semcor}"
else
   if [ "`fping $1 2> /dev/null | grep -i 'alive'`" != "" ]; then
      echo -e "${verde}Fechada${semcor}"
   else
      echo -e "${azul}Inconclusivo${semcor}"
   fi
fi
}

chargen() {
echo -e "Testando CHARGEN (19/udp): \c"
if [ "`echo | nc -w 1 -u $1 19 | hexdump -C`" != "" ]; then
   echo -e "${vermelho}Aberta${semcor}"
else
   if [ "`fping $1 2> /dev/null | grep -i 'alive'`" != "" ]; then
      echo -e "${verde}Fechada${semcor}"
   else
      echo -e "${azul}Inconclusivo${semcor}"
   fi
fi
}

qotd() {
echo -e "Testando QOTD (17/udp): \c"
if [ "`echo | nc -w 1 -u $1 17 | hexdump -C`" != "" ]; then
   echo -e "${vermelho}Aberta${semcor}"
else
   if [ "`fping $1 2> /dev/null | grep -i 'alive'`" != "" ]; then
      echo -e "${verde}Fechada${semcor}"
   else
      echo -e "${azul}Inconclusivo${semcor}"
   fi
fi
}

memcached() {
echo -e "Testando MEMCACHED (11211/udp): \c"
if [ "`printf '\\x0\\x0\\x0\\x0\\x0\\x1\\x0\\x0\\x73\\x74\\x61\\x74\\x73\\x0a' | nc -w 3 -u $1 11211 | hexdump -C`" != "" ]; then
   echo -e "${vermelho}Aberta${semcor}"
else
   if [ "`fping $1 2> /dev/null | grep -i 'alive'`" != "" ]; then
      echo -e "${verde}Fechada${semcor}"
   else
      echo -e "${azul}Inconclusivo${semcor}"
   fi
fi
}

ws-discovery() {
echo -e "Testando WS-DISCOVERY (3702/udp): \c"
if [ "`printf '<\\252>\\n' | nc -w 3 -u $1 3702 | hexdump -C`" != "" ]; then
   echo -e "${vermelho}Aberta${semcor}"
else
   if [ "`fping $1 2> /dev/null | grep -i 'alive'`" != "" ]; then
      echo -e "${verde}Fechada${semcor}"
   else
      echo -e "${azul}Inconclusivo${semcor}"
   fi
fi
}

coap() {
echo -e "Testando CoAP (5683/udp): \c"
if [ "`printf '\\x40\\x01\\x7d\\x70\\xbb\\x2e\\x77\\x65\\x6c\\x6c\\x2d\\x6b\\x6e\\x6f\\x77\\x6e\\x04\\x63\\x6f\\x72\\x65' | nc -w3 -u $1 5683| hexdump -C`" != "" ]; then
   echo -e "${vermelho}Aberta${semcor}"
else
   if [ "`fping $1 2> /dev/null | grep -i 'alive'`" != "" ]; then
      echo -e "${verde}Fechada${semcor}"
   else
      echo -e "${azul}Inconclusivo${semcor}"
   fi
fi
}

mt4145() {
echo -e "Testando MT4145 (4145/tcp): \c"
if [ "`nmap -sT -pT:4145 -Pn -n $1|grep open|awk '{print $2}'`" == "open" ]; then
   echo -e "${vermelho}Aberta${semcor}"
else
   if [ "`fping $1 2> /dev/null | grep -i 'alive'`" != "" ]; then
      echo -e "${verde}Fechada${semcor}"
   else
      echo -e "${azul}Inconclusivo${semcor}"
   fi
fi
}

mt5678() {
echo -e "Testando MT5678 - botnet Meris (5678/tcp): \c"
if [ "`nmap -sT -pT:5678 -Pn -n $1|grep open|awk '{print $2}'`" == "open" ]; then
   echo -e "${vermelho}Aberta${semcor}"
else
   if [ "`fping $1 2> /dev/null | grep -i 'alive'`" != "" ]; then
      echo -e "${verde}Fechada${semcor}"
   else
      echo -e "${azul}Inconclusivo${semcor}"
   fi
fi
}

if [ -z $2 ]; then
   netbios $1
   rpc $1
   arms $1
   tftp $1
   dns $1
   mdns $1
   ssdp $1
   snmp $1
   ntp $1
   ldap $1
   ubnt $1
   chargen $1
   qotd $1
   memcached $1
   ws-discovery $1
   coap $1
   mt4145 $1
   mt5678 $1
   dhcpdiscover $1
   exit
fi

echo -e "$1 \c"
$2 $1
