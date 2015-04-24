#!/usr/bin/env bash
git clone https://github.com/cfpb/regulations-parser
git clone https://github.com/cfpb/regulations-core
git clone https://github.com/cfpb/regulations-site
git clone https://github.com/cfpb/fr-notices.git
mkvirtualenv reg-parser
mkvirtualenv reg-core
mkvirtualenv reg-site
cd regulations-parser
workon reg-parser
pip install -r requirements.txt
pip install -r requirements_test.txt
echo 'API_BASE = "http://localhost:8000/"' >> local_settings.py
cd ../regulations-core
workon reg-core
pip install zc.buildout
buildout
./bin/django syncdb
./bin/django migrate
cd ../regulations-site
workon reg-site
pip install zc.buildout
buildout
cp regulations/settings/base.py regulations/settings/local_settings.py
sed -i -e 's|^DEBUG = False|DEBUG = True|' regulations/settings/local_settings.py
sed -i -e "s|API_BASE = ''|API_BASE = 'http://localhost:8000/'|" regulations/settings/local_settings.py
