#!/usr/bin/env bash

# Ensure we have virtualenvwrapper sourced so we can `workon`
source `which virtualenvwrapper.sh`

# Startup our eRegs 
cd /vagrant

# Startup regulations-core
cd regulations-core
workon regcore
nohup python manage.py runserver 0.0.0.0:8000 &

# Startup regulations-site
cd ../regulations-site
workon regsite
nohup python manage.py runserver 0.0.0.0:8001 &

