#!/usr/bin/env bash -l

# Clone the relevent repos
git clone https://github.com/cfpb/regulations-parser
git clone https://github.com/cfpb/regulations-stub
git clone https://github.com/cfpb/regulations-core
git clone https://github.com/cfpb/regulations-site
git clone https://github.com/cfpb/fr-notices.git

# Make virtualenvs for each component.
source `which virtualenvwrapper.sh`
mkvirtualenv reg-parser
mkvirtualenv reg-stub
mkvirtualenv reg-core
mkvirtualenv reg-site

# Setup the parser
cd regulations-parser
workon reg-parser
pip install -r requirements.txt
pip install -r requirements_test.txt
cat << 'EOF' >> local_settings.py
# Uncoment the following line to write directly to regulations-core
API_BASE = "http://localhost:8000/"

# Uncoment the following line to write to the regulations-stub stub 
# folder instead
# OUTPUT_DIR="../regulations-stub/stub/"
EOF

# Setup the stub folder
cd ../regulations-stub
workon reg-stub
pip install -r requirements.txt

# Setup the API
cd ../regulations-core
workon reg-core
pip install zc.buildout
buildout
./bin/django syncdb
./bin/django migrate

# Setup the front-end site
cd ../regulations-site
workon reg-site
pip install zc.buildout
buildout
sh ./frontendbuild.sh
cp regulations/settings/base.py regulations/settings/local_settings.py
sed -i -e 's|^DEBUG = False|DEBUG = True|' regulations/settings/local_settings.py
sed -i -e "s|API_BASE = ''|API_BASE = 'http://localhost:8000/'|" regulations/settings/local_settings.py

