############# VARIABLES @@@@@@@@@@@@@@@@

PASSWORD="changeme"
REMOTE_HOST_IP="192.168.1.10"
REMOTE_HOST_NAME="git"
REMOTE_PASSWORD="none"
STACK_VERSION="8.5.3"
LOCAL=1
usage="Usage: bash launch.sh -e Elastic Stack password -r Remote machine ip -u Remote machine name -p Remote machine root password -s STACK_VERSION -l run docker launch or not -t local or remote deployment -o port that is port forwarded"
OPEN_PORT=9200
LAUNCH=1
while getopts ':he:r:u:p:s:l' flag
do
    case "${flag}" in
        h) echo $usage
          exit
          ;;
        e) PASSWORD=${OPTARG};;
        r) REMOTE_HOST_IP=${OPTARG};;
        u) REMOTE_HOST_NAME=${OPTARG};;
        p) REMOTE_PASSWORD=${OPTARG};;
        s) STACK_VERSION=${OPTARG};;
        l) LAUNCH=0;;
        t) LOCAL=0;;
        o) OPEN_PORT=${OPTARG};;
        :) printf "missing argument for -%s\n" "$OPTARG" >&2
          echo "$usage" >&2
          exit 1
          ;;

    esac
done

ELASTIC_PASSWORD=$PASSWORD
BEATS_PASSWORD=$PASSWORD
KIBANA_PASSWORD=$PASSWORD

echo $REMOTE_HOST_IP  $REMOTE_HOST_NAME $REMOTE_PASSWORD




############# CODE STARTS @@@@@@@@@@@@@@@@
if [[ "$LAUNCH" -eq 1 ]]; then 
  cat > .env << EOF
  STACK_VERSION=$STACK_VERSION
  ELASTIC_PASSWORD=$ELASTIC_PASSWORD
  KIBANA_PASSWORD=$ELASTIC_PASSWORD
  MEM_LIMIT=1073741827
  CLUSTER_NAME=docker-cluster
  LICENSE=basic
  ES_PORT=9200
  KIBANA_PORT=5601
  BEAT_PASSWORD=$BEATS_PASSWORD
EOF




  sudo sysctl -w vm.max_map_count=262144
  chmod 600 beat/auditbeat.docker.yml
  sudo docker kill $(sudo docker ps -q)
  sudo docker system prune -f
  sudo docker volume prune -f
  sudo docker-compose up --remove-orphans -d
  echo "Creando Roles"
  curl -k -X   PUT -u elastic:$ELASTIC_PASSWORD -H "Content-Type: application/json; charset=utf-8'"  "https://localhost:9200/_security/role/beats_writer" \
  -H "Expect:" \
  --data-raw '
  {
        "cluster": [
      "monitor",
      "manage",
      "all",
      "manage_ilm",
      "manage_ml",
      "manage_index_templates",
      "manage_ingest_pipelines",
      "manage_pipeline"
    ],
    "indices": [
      {
        "names": [
          "*beat-*"
        ],
        "privileges": [
          "write",
          "all",
          "create_index"
        ]
      }
    ]
    }'
    
   
      curl -k -X   PUT -u elastic:$ELASTIC_PASSWORD -H "Content-Type: application/json; charset=utf-8'"  "https://localhost:9200/_security/user/filebeat_writer" \
  -H "Expect:" \
  --data-raw '
  {
  "password": "'$BEATS_PASSWORD'",
    "roles": [
      "beats_writer"
    ]
  }
  '
   
     curl -k -X   PUT -u elastic:$ELASTIC_PASSWORD -H "Content-Type: application/json; charset=utf-8'" "https://localhost:9200/_ingest/pipeline/geoip-info?pretty" \
    -H "Expect:" \
    --data-raw '
{
  "description": "Add geoip info",
  "processors": [
    {
      "geoip": {
        "field": "client.ip",
        "target_field": "client.geo",
        "ignore_missing": true
      }
    },
    {
      "geoip": {
        "database_file": "GeoLite2-ASN.mmdb",
        "field": "client.ip",
        "target_field": "client.as",
        "properties": [
          "asn",
          "organization_name"
        ],
        "ignore_missing": true
      }
    },
    {
      "geoip": {
        "field": "source.ip",
        "target_field": "source.geo",
        "ignore_missing": true
      }
    },
    {
      "geoip": {
        "database_file": "GeoLite2-ASN.mmdb",
        "field": "source.ip",
        "target_field": "source.as",
        "properties": [
          "asn",
          "organization_name"
        ],
        "ignore_missing": true
      }
    },
    {
      "geoip": {
        "field": "destination.ip",
        "target_field": "destination.geo",
        "ignore_missing": true
      }
    },
    {
      "geoip": {
        "database_file": "GeoLite2-ASN.mmdb",
        "field": "destination.ip",
        "target_field": "destination.as",
        "properties": [
          "asn",
          "organization_name"
        ],
        "ignore_missing": true
      }
    },
    {
      "geoip": {
        "field": "server.ip",
        "target_field": "server.geo",
        "ignore_missing": true
      }
    },
    {
      "geoip": {
        "database_file": "GeoLite2-ASN.mmdb",
        "field": "server.ip",
        "target_field": "server.as",
        "properties": [
          "asn",
          "organization_name"
        ],
        "ignore_missing": true
      }
    },
    {
      "geoip": {
        "field": "host.ip",
        "target_field": "host.geo",
        "ignore_missing": true
      }
    },
    {
      "rename": {
        "field": "server.as.asn",
        "target_field": "server.as.number",
        "ignore_missing": true
      }
    },
    {
      "rename": {
        "field": "server.as.organization_name",
        "target_field": "server.as.organization.name",
        "ignore_missing": true
      }
    },
    {
      "rename": {
        "field": "client.as.asn",
        "target_field": "client.as.number",
        "ignore_missing": true
      }
    },
    {
      "rename": {
        "field": "client.as.organization_name",
        "target_field": "client.as.organization.name",
        "ignore_missing": true
      }
    },
    {
      "rename": {
        "field": "source.as.asn",
        "target_field": "source.as.number",
        "ignore_missing": true
      }
    },
    {
      "rename": {
        "field": "source.as.organization_name",
        "target_field": "source.as.organization.name",
        "ignore_missing": true
      }
    },
    {
      "rename": {
        "field": "destination.as.asn",
        "target_field": "destination.as.number",
        "ignore_missing": true
      }
    },
    {
      "rename": {
        "field": "destination.as.organization_name",
        "target_field": "destination.as.organization.name",
        "ignore_missing": true
      }
    }
  ]
}
'


    echo -e "\n Creando usuarios"

    curl -k -X   PUT -u elastic:$ELASTIC_PASSWORD -H "Content-Type: application/json; charset=utf-8'"  "https://localhost:9200/_security/user/filebeat_writer" \
  -H "Expect:" \
  --data-raw '
  {
  "password": "'$BEATS_PASSWORD'",
    "roles": [
      "beats_writer"
    ]
  }
  '
    echo -e " Usuario filebeat_writer creado \n"
    curl -k -X   PUT -u elastic:$ELASTIC_PASSWORD -H "Content-Type: application/json; charset=utf-8'"  "https://localhost:9200/_security/user/packetbeat_writer" \
  -H "Expect:" \
  --data-raw '
  {
    "password": "'$BEATS_PASSWORD'",
    "roles": [
      "beats_writer"
    ]
  }
  '
  echo -e " Usuario packetbeat_writer creado \n"

    curl -k -X   PUT -u elastic:$ELASTIC_PASSWORD -H "Content-Type: application/json; charset=utf-8'"  "https://localhost:9200/_security/user/auditbeat_writer" \
  -H "Expect:" \
  --data-raw '
  {
    "password": "'$BEATS_PASSWORD'",
    "roles": [
      "beats_writer"
    ]
  }
  '
  echo -e " Usuario auditbeat_writer creado \n"

  sudo docker cp $(sudo docker ps | grep es01 | awk '{print $1;}'):/usr/share/elasticsearch/config/certs/ca/ca.crt .
fi

sudo chown $(whoami) ca.crt

if [[ "$LOCAL" -eq 1 ]]; then 
	IP=`ip a | grep $(ip route | grep default | awk '{print $5}') | grep inet | awk '{print $2;}' |  awk -F '/' '{print $1}'`
	PORT=`sudo docker port es04 | head -n 1 |  awk -F ':' '{print $2}'`
else
	PORT=`sudo docker port es04 | head -n 1 |  awk -F ':' '{print $2}'`
	echo Need to open port $PORT in router
	content="$(wget http://checkip.dyndns.org/ -q -O -)"
   	IP="$(<<< "$content" sed -e 's/.*Current IP Address: //' -e 's/<.*//')"
  
fi
scp -r ./ca.crt $REMOTE_HOST_NAME@$REMOTE_HOST_IP:/home/$REMOTE_HOST_NAME/

ssh $REMOTE_HOST_NAME@$REMOTE_HOST_IP 'bash -s' <  test.sh "$IP $PORT $BEATS_PASSWORD $STACK_VERSION $REMOTE_PASSWORD"






