sudo apt update -y
sudo apt upgrade -y
sudo apt install docker-compose -y

 cat > docker-compose.yaml << EOF

version: "2.2"

services:
  
  packetbeat:

    image: docker.elastic.co/beats/packetbeat:$1
    container_name: packetbeat
    volumes:
      - ./beat/packetbeat.docker.yml:/usr/share/packetbeat/packetbeat.yml
      - ./certs:/usr/share/elasticsearch/config/certs
    environment:
      - ELASTICSEARCH_HOSTS=["https://$2:$3"]
      - BEAT_PASSWORD=$1


    cap_add:
      - NET_RAW
      - NET_ADMIN
   # network_mode: "host"  

  auditbeat:
   image: docker.elastic.co/beats/auditbeat:${STACK_VERSION}
   container_name: auditbeat

   cap_add:
     - AUDIT_CONTROL
     - AUDIT_READ
   user: root
   pid: host
   privileged: true 
   volumes:
      - ./beat/auditbeat.docker.yml:/usr/share/auditbeat/auditbeat.yml:ro
      - /var/log:/var/log:ro
      - ./certs:/usr/share/elasticsearch/config/certs
   environment:
      - ELASTICSEARCH_HOSTS=["https://$2:$3"]
      - BEAT_PASSWORD=$1


EOF

 cat  docker-compose.yaml 