ELASTIC_PASSWORD="changeme"
BEATS_PASSWORD="changeme"

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



