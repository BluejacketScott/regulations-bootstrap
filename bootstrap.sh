#!/usr/bin/env bash

# Install system dependencies
apt-get update
apt-get install git -y
apt-get install python-dev -y
apt-get install python-pip -y
apt-get install libxml2-dev libxslt1-dev zlib1g-dev -y

# Install Python dependencies
pip install virtualenv
pip install virtualenvwrapper

# Setup eRegs environment
sudo su vagrant <<'EOF'
mkdir ~/.virtualenvs
echo "export WORKON_HOME=~/.virtualenvs" >> ~/.bashrc
echo "export VIRTUALENVWRAPPER_VIRTUALENV=/usr/local/bin/virtualenv" >> ~/.bashrc
echo "source /usr/local/bin/virtualenvwrapper.sh" >> ~/.bashrc
source ~/.bashrc
source /usr/local/bin/virtualenvwrapper.sh
cd /vagrant && ./regs_bootstrap.sh
EOF
