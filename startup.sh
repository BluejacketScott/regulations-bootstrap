#!/usr/bin/env bash

# Ensure we have virtualenvwrapper sourced so we can `workon`
source `which virtualenvwrapper.sh`

# Startup our eRegs 
cd /vagrant

# Startup regulations-core
cd regulations-core
workon reg-core
nohup ./bin/django runserver 0.0.0.0:8000 &

# Startup regulations-site
cd ../regulations-site
workon reg-site
nohup ./bin/django runserver 0.0.0.0:8001 &

