sudo docker kill $(sudo docker ps -q)
sudo docker system prune -f
#sudo docker volume prune -f
sudo docker-compose up --remove-orphans
