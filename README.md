[![Build Status](https://travis-ci.org/tombh/peas.svg?branch=master)](https://travis-ci.org/tombh/peas)
[![Code Climate](https://codeclimate.com/github/tombh/peas/badges/gpa.svg)](https://codeclimate.com/github/tombh/peas)
Peas
====
__PaaS for the People__

Peas is a Heroku-style Platform as a Service written in Ruby using [Docker](http://www.docker.io). It is heavily
inspired by [Deis](http://deis.io) and [Dokku](https://github.com/progrium/dokku).

Peas' philosophy is to be an accessible and easily hackable PaaS. It doesn't aim to be a complete
enterprise solution. Instead it aims to be a relatively unopinionated, but solid starting place using all the goodness
of Ruby;
[Rspec](http://rspec.info/),
[Bundler](http://bundler.io/),
[Guard](https://github.com/guard/guard),
[Rack](http://rack.github.io/),
[Mongoid](http://mongoid.org/en/mongoid/index.html),
[Docker-api](https://github.com/swipely/docker-api),
[Puma](http://puma.io/),
[Grape](http://intridea.github.io/grape/),
[GLI](http://davetron5000.github.io/gli/),
[Celluloid](http://celluloid.io/),
and more.

Peas is still beta software. Expect breaking changes.

#Quickstart for live installation on remote server
```bash
# Remote VPS commands
ssh root@some_vanilla_server.com
curl -sSL https://raw.githubusercontent.com/tombh/peas/master/contrib/bootstrap.sh | sh
#=> (lots of logs about Peas downloading and booting up)

# Local commands
gem install peas-cli
cd /my/cool/app/folder
peas admin settings peas.domain some_vanilla_server.com
peas create
git push peas master
#=>
# -----> Installing dependencies
# -----> ... lots more lines like this
# -----> Discovering process types
# -----> Scaling process 'web:1'
#        Deployed to http://mycoolapp.some_vanilla_server.com"
```

#General Installation Instructions
There is a universal installation script at `contrib/bootstrap.sh`, it can be run directly on most
vanilla *nix systems with root access;

    curl -sSL https://raw.githubusercontent.com/tombh/peas/master/contrib/bootstrap.sh | sh

It works on recent versions of Ubuntu, Debian (>=8), Fedora, Centos and Redhat. It uses [pacapt](https://github.com/icy/pacapt)
to install the OS's native Docker package (ensuring Docker is managed by an init system). It then runs
`contrib/peas-dind/run.sh` to install the Peas image itself, with a restart policy of 'always', ensuring that Peas
starts at boot.

**Local development environment**    
To run on Windows and OSX, please follow the 'vagrant' instructions below.

This is the preferred method for local development, but note that local development is also possible
with the Docker installation method.
All you will need is; Ruby(>=2.1),
[Docker](https://www.docker.io/gettingstarted/)(>=1.1)
and [Mongo DB](http://docs.mongodb.org/manual/installation/)(>=2.6).
All of these are generally installable via your system's package manager, no compiling should be necessary.
```bash
docker pull progrium/buildstep # This runs Heroku buildpacks against repos to create deployable app images
git clone https://github.com/tombh/peas.git
bundle install
bundle exec guard
```

The Peas API will be available at `vcap.me:4443`.

**Docker**   
This installation method will work anywhere that Docker can be installed, so both locally and on
remote servers like AWS and Digital Ocean.

To install and boot just use `./contrib/peas-dind/run.sh` (ie. you will need to have cloned the repo
first). For a detailed explanation read
`contrib/peas-dind/README.md`.

The Peas API will be available at `vcap.me:4443`.

**Vagrant**   
Most likely useful to you if you are on Windows. There is a Vagrantfile in the root of the project.
All it does is boot a recent VM of Ubuntu and then installs Peas using the Docker method above.

The Peas API will be available at `peas.local:4443`.

**CLI client**   
To interact with the Peas API you will need to install the command line client:
`gem install peas-cli`

During development you will find it useful to use the `peas-dev` command. It uses the live code in
your local repo as the CLI client. You can put it in your `$PATH` with something like;
`sudo ln -s $(pwd)/peas-dev /usr/local/bin/peas-dev`

#Usage

**Setup**   
Peas aims to follow the conventions and philosophies of Heroku as closely as possible. So it is worth
bearing in mind that a lot of the [Heroku documentation](https://devcenter.heroku.com/) is relevant to Peas.

First thing is to set the domain that points to your Peas installation. If you're developing locally
you can actually just rely on the default `vcap.me` which has wildcard DNS records to point all subdomains
to `127.0.0.1`.

To use a different domain:
`peas admin settings peas.domain customdomain.com`

**Users**    
Peas is currently authenticated by an API key on a per user basis. The first user is automatically
created when you first interact with the CLI. It uses your default SSH key and username, so there
is no need to register.

At the moment you will need to use the controller's console to add more users:
  1. `peas admin run rake console`
  2. `User.create name: 'newusername', public_key: 'public key string'`

**Deploying**   
Next thing is to get into the directory of the git repo for the app you want to deploy.

Then:
```
peas create
git push peas master
```

The last line of the deployment output should contain the URL for your deployed app.

You can then scale processes using:
`peas scale web=3 worker=2`

**Services**   
If a service URI is provided to Peas' admin settings then all subsequently created apps will be given an instance of
that service. Therefore, by issuing something like;   
`peas admin settings mongodb.uri mongodb://root:password@mongoservice.com`   
all new apps will get created with a config variable of something like;
`MONGDB_URI=mongodb://appname:2f7n87fr@mongoservice.com/appname`

New services can be added by creating a new class in `lib/services`. You can use any of the existing service classes as
a template.

**Debugging**    
You can get a shell to the controller with `peas admin run bash`. There is no root access at the 
moment, but you can view logs, run `rake console` and restart services.

**All current CLI commands**
```
admin      - Admin commands:
  run      - Run commands on the Peas Controller
  settings - Set Peas global system settings
apps       - List all apps
config     - Add, remove and list config for an app
create     - Create an app
destroy    - Destroy an app
help       - Shows a list of commands or help for one command
logs       - Show logs for an app
run        - Run one-off commands
scale      - Scale an app
```

#Roadmap
  * Adding extra users with varying permissions.
  * Auto Pod scaling across servers.  

##Video Presentation
Given at London Ruby User Group on November 10th 2014 (0h31m)
<a href="https://skillsmatter.com/skillscasts/5928-peas-a-docker-and-ruby-based-paas
" target="_blank"><img src="http://i.imgur.com/xxSqCPy.jpg"
alt="Peas presentation" width="480" border="10" /></a>
