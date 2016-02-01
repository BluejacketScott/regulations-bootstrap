#!/usr/bin/env bash

COMPONENTS=""
API_BASE="http://localhost:8000/"
DEBUG=false
VERBOSE=false
SETUP_ERRORS=false

source `which virtualenvwrapper.sh`

try_to() {
    # Try to perform a command, wrapped in nice messages and
    # error/verbose handling.
    message=$1
    command=$2
    echo -n "`tput setaf 2; tput bold`$message... `tput sgr0`"

    if $VERBOSE; then
        echo ""
        $command
    elif ! output=$($command 2>&1); then
        echo "`tput setaf 1; tput bold`error`tput sgr0`"
        echo "$output"
        return 1
    else
        echo "`tput bold`done`tput sgr0`"
    fi
}

## Parser

clone_parser() {
    # For the parser clone regulations-parser, regulations-sub, and
    # fr-notices so that the JSON and XML are both also available.
    git clone -b xml-writer-devel https://github.com/cfpb/regulations-parser
    git clone https://github.com/cfpb/regulations-configs
    git clone https://github.com/cfpb/fr-notices
    git clone https://github.com/cfpb/regulations-schema
    git clone https://github.com/cfpb/regulations-xml
    git clone https://github.com/cfpb/regulations-xml-parser
    git clone https://github.com/cfpb/regulations-stub
}

make_parser_virtualenv() {
    # Make the virtualenvs
    mkvirtualenv --python `which python2.7` regparser
}

setup_parser() {
    # Setup the parser
    workon regparser
    pip install -e regulations-parser -e regulations-configs
    cd regulations-xml-parser
    pip install -r requirements.txt -r requirements_test.txt

    # XXX: XML parser should use these
    cat << 'EOF' >> local_settings.py
# Uncoment the following line to write directly to regulations-core
API_BASE = "$API_BASE"

# Uncoment the following line to write to the regulations-stub stub 
# folder instead
# OUTPUT_DIR="../regulations-stub/stub/"

LOCAL_XML_PATHS = ['../fr-notices/']
EOF

    # Setup the stub folder
    cd ../regulations-stub
    pip install -r requirements.txt
    cd ..
}

test_parser() {
    # Run the parser's tests
    workon regparser
    cd regulations-xml-parser
    tox
}

bootstrap_parser() {
    # Bootstrap the parser. 
    if [[ $COMPONENTS != *"parser"* ]]; then
        exit
    fi

    try_to 'cloning parser repositories' clone_parser
    try_to 'making parser virtualenvs' make_parser_virtualenv
    try_to 'setting up parser' setup_parser
    try_to 'testing parser' test_parser 

    if [ $? -ne 0 ]; then
        SETUP_ERRORS=true
    fi
}

## Core, API

clone_core() {
    git clone https://github.com/cfpb/regulations-core
}

make_core_virtualenv() {
    mkvirtualenv --python `which python2.7` regcore
}
    
setup_core() {
    # Setup the API
    workon regcore
    cd regulations-core
    pip install -r requirements.txt -r requirements_test.txt
    python manage.py syncdb
    python manage.py migrate
    cd ..
}

test_core() {
    # Run core's tests
    workon regcore
    cd regulations-core
    python manage.py test
}

bootstrap_core() {
    # Bootstrap the api
    if [[ $COMPONENTS != *"core"* ]]; then
        exit
    fi

    try_to 'cloning core repository' clone_core
    try_to 'making core virtualenv' make_core_virtualenv
    try_to 'setting up core' setup_core
    try_to 'testing core' test_core

    if [ $? -ne 0 ]; then
        SETUP_ERRORS=true
    fi
}

## Site

clone_site() {
    git clone https://github.com/cfpb/regulations-site
}

make_site_virtualenv() {
    mkvirtualenv --python `which python2.7` regsite
}

setup_site() {
    # Setup the front-end site
    workon regsite
    cd regulations-site
    pip install -r requirements.txt -r requirements_test.txt

    # Setup front-end
    nvm install 4
    nvm use 4
    sh ./frontendbuild.sh

    cp regulations/settings/base.py regulations/settings/local_settings.py
    if $DEBUG; then
        sed -i -e 's|^DEBUG = False|DEBUG = True|' regulations/settings/local_settings.py
    fi
    sed -i -e "s|API_BASE = os.environ.get('EREGS_API_BASE', '')|API_BASE = '$API_BASE'|" regulations/settings/local_settings.py
    cd ..
}

test_site() {
    # Run site's tests
    workon regsite
    cd regulations-site
    python manage.py test
    # The front-end tests run with `grunt build` already
    # grunt test-js
}

bootstrap_site() {
    # Bootstrap the site
    if [[ $COMPONENTS != *"site"* ]]; then
        exit
    fi

    try_to 'cloning site repository' clone_site
    try_to 'making site virtualenv' make_site_virtualenv
    try_to 'setting up site' setup_site
    try_to 'testing site' test_site

    if [ $? -ne 0 ]; then
        SETUP_ERRORS=true
    fi
}

## Usage

usage() { 
    echo "Usage: $0 [-v] [-d] [-c http://api-url] [-b component] [-b ...]" 1>&2
    echo "      -v          verbose — outputs individual commands as they happen" 1>&2
    echo "      -d          set Django debug flags to true" 1>&2
    echo "      -c [URL]    API url to configure for parser and site" 1>&2
    echo "      -b [...]    component to bootstrap, either parser, core, or site" 1>&2
    exit 1
}

while getopts ":b:c:d:vh" OPT; do
    case $OPT in
        b)
            COMPONENTS="$COMPONENTS $OPTARG"
            ;;
        c)
            API_BASE=$OPTARG
            ;;
        d)
            DEBUG=true
            ;;
        v)
            VERBOSE=true
            ;;
        h)
            usage
            ;;
        \?)
            echo "Invalid option: -$OPTARG" >&2
            usage
            ;;
    esac
done

# If we didn't get any components, enable all of them
if [ -z "$COMPONENTS" ]; then
    COMPONENTS="parser core site"
fi

# Perform the bootstrap process

# bootstrap_parser
bootstrap_parser
bootstrap_core
bootstrap_site

if $SETUP_ERRORS; then
    exit 1
fi

# If we're running interactively then provide a bit of help getting started
if [ -z $PS1 ]; then
    echo "`tput bold`Bootstrap completed.`tput sgr0`"
    echo 

    if [[ $COMPONENTS == *"parser"* ]]; then
        echo "`tput bold`To use the parser:`tput sgr0`"
        echo "    $ cd regulations-xml-parser"
        echo "    $ workon regparser"
        echo "      Please see the parser documentation for more information."
        echo "      https://github.com/cfpb/regulations-xml-parser/blob/master/README.md"
        echo 
    fi
    if [[ $COMPONENTS == *"core"* ]]; then
        echo "`tput bold`To use the API:`tput sgr0`"
        echo "    $ cd regulations-core"
        echo "    $ workon regcore"
        echo "    $ python manage.py runserver 0.0.0.0:8000"
        echo 
        
    fi
    if [[ $COMPONENTS == *"site"* ]]; then
        echo "`tput bold`To use the site:`tput sgr0`"
        echo "    $ cd regulations-site"
        echo "    $ workon regsite"
        echo "    $ python manage.py runserver 0.0.0.0:8001"
        echo 
    fi
fi
