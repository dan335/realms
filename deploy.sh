#!/bin/bash
docker login registry.gitlab.com -u danphi
if ! rspec . ; then
    exit
fi
docker build -t registry.gitlab.com/danphi/realms .
docker push registry.gitlab.com/danphi/realms