# regulations-bootstrap

[eRegulations](http://cfpb.github.io/eRegulations) is a web-based tool that makes regulations easier to find, read and understand with features such as inline official interpretations, highlighted defined terms, and a revision comparison view.

eRegs is made up of three core components:

* [regulations-parser](https://github.com/cfpb/regulations-parser): Parse regulations
* [regulations-core](https://github.com/cfpb/regulations-core): Regulations API
* [regulations-site](https://github.com/cfpb/regulations-site): Display the regulations

This repository contains scripts that boostrap a coherent eRegulations working envionrment, either locally or in a [Vagrant](https://www.vagrantup.com/) virtual machine.

## Bootstrap Locally

To bootstrap a local (i.e. not virtualized) eRegs environment, you'll
need to install Python's virtualenv and virtualenvwrapper. 

### Requirements

Install [virtualenv](https://virtualenv.pypa.io/en/latest/):

```shell
pip install virtualenv
```

Then install and configure 
[virtualenvwrapper](https://virtualenvwrapper.readthedocs.org/en/latest/). 
More information on how virtualenvwrapper works and how you may wish to 
set it up in your shell can be found in the 
[virtualenvwrapper documentation](https://virtualenvwrapper.readthedocs.org/en/latest/install.html).

```shell
pip install virtualenvwrapper
export WORKON_HOME=~/envs
mkdir -p $WORKON_HOME
source `which virtualenvwrapper.sh`
```

### Bootstrapping

Once you have these requirements installed you can run the
`regs_bootstrap.sh`:

```shell
./regs_bootstrap.sh
```

This will clone all of the eRegs repositories, make seperate virtualenvs 
for them, and setup their dependencies.

## Bootstrap with Vagrant

To bootstrap eRegs in a [Vagrant](https://www.vagrantup.com/) virtual 
machine, you'll need to install Vagrant locally. Everything else should 
be taken care of by this repository's `Vagrantfile`.

### Requirements

Install [Vagrant](https://www.vagrantup.com/). On Mac OS X, this can be
done with [Homebrew](http://brew.sh):

```shell
brew install vagrant
```

### Bootstrapping

The eRegs bootstrapping process will be performed as part of the Vagrant
provisioning process. All one needs to do is provision the Vagrant
virtual machine. 

```shell
vagrant up
```

Once the virtual machine is running, you should be able to access
regulations-core at [http://localhost:8000](http://localhost:8000) and 
regulations-site at [http://localhost:8001](http://localhost:8001).

You can also connect to the virtual machine via SSH.

```shell
vagrant ssh
```

## Using

Before you can use regulations-site to browse any regulations, you'll
need to parse some with regulations-parser. To do this you'll need to
SSH into the virtual machine and run the parser. 

To parse the [CFPB's Regulation E](http://www.consumerfinance.gov/eregulations/1005), 
for example, you would do the following:

```shell
workon reg-parser
cd /vagrant/regulations-parser
./build_from.py ../fr-notices/annual/CFR-2012-title12-vol8-part1026.xml 12 2011-31715 15 1601
```

Once completed, the JSON for this regulation can be browsed in
regulations-core at [http://localhost:8000](http://localhost:8000) and
can be viewed in regulations-site at [http://localhost:8001](http://localhost:8001).

Because all of the components are stored in your Vagrant project
directory you can use your favorite IDE or editor to work on them and
see your changes running in the virtual machine.


