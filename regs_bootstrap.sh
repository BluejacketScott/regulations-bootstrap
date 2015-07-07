#!/usr/bin/env bash -l

COMPONENTS=""
API_BASE="http://localhost:8000"
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
    git clone https://github.com/cfpb/regulations-parser
    git clone https://github.com/cfpb/regulations-stub
    git clone https://github.com/cfpb/fr-notices.git
}

make_parser_virtualenv() {
    # Make the virtualenvs
    mkvirtualenv reg-parser
    mkvirtualenv reg-stub
}

setup_parser() {
    # Setup the parser
    cd regulations-parser
    workon reg-parser
    pip install -r requirements.txt
    pip install -r requirements_test.txt
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
    workon reg-stub
    pip install -r requirements.txt
    cd ..
}

bootstrap_parser() {
    # Bootstrap the parser. 
    if [[ $COMPONENTS != *"parser"* ]]; then
        exit
    fi

    try_to 'cloning parser repositories' clone_parser
    try_to 'making parser virtualenvs' make_parser_virtualenv
    try_to 'setting up parser' setup_parser

    if [ $? -ne 0 ]; then
        SETUP_ERRORS=true
    fi
}

## Core, API

clone_core() {
    git clone https://github.com/cfpb/regulations-core
}

make_core_virtualenv() {
    mkvirtualenv reg-core
}
    
setup_core() {
    # Setup the API
    cd regulations-core
    workon reg-core
    pip install zc.buildout
    buildout
    ./bin/django syncdb
    ./bin/django migrate
    cd ..
}

bootstrap_core() {
    # Bootstrap the api
    if [[ $COMPONENTS != *"core"* ]]; then
        exit
    fi

    try_to 'cloning core repository' clone_core
    try_to 'making core virtualenv' make_core_virtualenv
    try_to 'setting up core' setup_core

    if [ $? -ne 0 ]; then
        SETUP_ERRORS=true
    fi
}

## Site

clone_site() {
    git clone https://github.com/cfpb/regulations-site
}

make_site_virtualenv() {
    mkvirtualenv reg-site
}

setup_site() {
    # Setup the front-end site
    cd regulations-site
    workon reg-site
    pip install zc.buildout
    buildout
    sh ./frontendbuild.sh
    cp regulations/settings/base.py regulations/settings/local_settings.py
    if $DEBUG; then
        sed -i -e 's|^DEBUG = False|DEBUG = True|' regulations/settings/local_settings.py
    fi
    sed -i -e "s|API_BASE = ''|API_BASE = '$API_BASE'|" regulations/settings/local_settings.py
    cd ..
}

bootstrap_site() {
    # Bootstrap the site
    if [[ $COMPONENTS != *"site"* ]]; then
        exit
    fi

    try_to 'cloning site repository' clone_site
    try_to 'making site virtualenv' make_site_virtualenv
    try_to 'setting up site' setup_site

    if [ $? -ne 0 ]; then
        SETUP_ERRORS=true
    fi
}

## Usage

usage() { 
    echo "Usage: $0 [-v] [-d] [-c http://api-url] [-b component] [-b ...]" 1>&2
    echo "      -v  verbose — outputs individual commands as they happen" 1>&2
    echo "      -d  set Django debug flags to true" 1>&2
    echo "      -c  API url to configure for parser and site" 1>&2
    echo "      -b  component to bootstrap, either parser, core, or site" 1>&2
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
        echo "    $ cd regulations-parser"
        echo "    $ workon reg-parser"
        echo "    $ ./build_from.py [XML FILE] [TITLE] [ACT TITLE] [ACT SECTION]"
        echo "Please see the parser documentation for more information."
        echo 
    fi
    if [[ $COMPONENTS == *"core"* ]]; then
        echo "`tput bold`To use the API:`tput sgr0`"
        echo "    $ cd regulations-core"
        echo "    $ workon reg-core"
        echo "    $ ./bin/django runserver 0.0.0.0:8000"
        echo 
        
    fi
    if [[ $COMPONENTS == *"site"* ]]; then
        echo "`tput bold`To use the site:`tput sgr0`"
        echo "    $ cd regulations-site"
        echo "    $ workon reg-site"
        echo "    $ ./bin/django runserver 0.0.0.0:8001"
        echo 
    fi
fi
