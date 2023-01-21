
dir=$HOME



 cat > $dir/packetbeat.yml << EOF

packetbeat.interfaces.auto_promisc_mode: true
packetbeat.flows:
  timeout: 30s
  period: 10s
packetbeat.protocols:
- type: icmp
  enabled: true
- type: ssh
  ports: [22,23]
packetbeat.protocols.dns:
  ports: [53]
  include_authorities: true
  include_additionals: true
packetbeat.protocols.http:
  ports: [80, 5601, 9200, 8080, 8081, 5000, 8002]
processors:
- add_cloud_metadata: ~
output.elasticsearch:
  hosts: ["https://es04:$2"]
  username: 'packetbeat_writer'
  password: '$3'
  pipeline: geoip-info
  ssl:
    certificate_authorities: "$dir/ca.crt"
   # certificate: "/usr/share/elasticsearch/config/certs/packetbeat/packetbeat.crt"
   # key: "/usr/share/elasticsearch/config/certs/packetbeat/packetbeat.key"
setup.kibana:

    host: "es04:5601"
    username: 'kibana_system'
    
    

setup.dashboards.enabled: true


EOF

su -l  root <<! >/dev/null 2>&1
$5
service packetbeat stop
if grep -q "es04" /etc/hosts; then
    echo "Exists"
else
    echo "$1  es04" >> /etc/hosts
fi



apt-get update -y /dev/tty

# Install the public signing key
wget -qO - https://artifacts.elastic.co/GPG-KEY-elasticsearch |  apt-key add -

# Save the repository definition to /etc/apt/sources.list.d/elastic-7.x.list
echo "deb https://artifacts.elastic.co/packages/7.x/apt stable main" | tee -a /etc/apt/sources.list.d/elastic-7.x.list

# Update package list
apt-get update -y

# Install the Beats package
apt-get install filebeat packetbeat auditbeat  -y
service packetbeat stop
mv $dir/packetbeat.yml /etc/packetbeat/packetbeat.yml
chown root /etc/packetbeat/packetbeat.yml

service packetbeat start
service packetbeat stop
service packetbeat start
!

