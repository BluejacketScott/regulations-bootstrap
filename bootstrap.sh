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

# Fetch a more recent nodejs than what's available from apt
curl -s -o- https://raw.githubusercontent.com/creationix/nvm/v0.30.2/install.sh | NVM_DIR="/opt/nvm" bash
export NVM_DIR=/opt/nvm
source $NVM_DIR/nvm.sh
nvm install 4
nvm use 4
npm install -g grunt-cli browserify

# mkdir /opt/nodejs && cd /opt/nodejs && curl -L -s http://nodejs.org/dist/v0.12.2/node-v0.12.2-linux-x64.tar.gz | tar --strip-components 1 -xz
# Install Node dependencies
# /opt/nodejs/bin/npm install -g grunt-cli bower browserify 

# Setup eRegs environment
sudo su vagrant <<'EOF'
# Setup Python virtualenv
mkdir ~/.virtualenvs
echo "export PATH=/opt/nodejs/bin:$PATH" >> ~/.bashrc
echo "export WORKON_HOME=~/.virtualenvs" >> ~/.bashrc
echo "export VIRTUALENVWRAPPER_VIRTUALENV=/usr/local/bin/virtualenv" >> ~/.bashrc
echo "source /usr/local/bin/virtualenvwrapper.sh" >> ~/.bashrc

# Setup Node nvm
echo "export NVM_DIR=/opt/nvm" >> ~/.bashrc
echo "source /opt/nvm/nvm.sh" >> ~/.bashrc

source ~/.bashrc

cd /vagrant && bash -l regs_bootstrap.sh
EOF
