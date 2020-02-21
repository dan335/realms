docker login registry.gitlab.com -u danphi
docker build -t registry.gitlab.com/danphi/realms .
docker push registry.gitlab.com/danphi/realms
ssh root@astroe.io "cd /shipyard/compose; docker-compose pull; docker-compose up -d"