Docker MISP Container
=====================
### Latest Update: 4-10-2018

Latest Upstream Change Included: 6df6cc79bc0dbbc0307d57767ac47c09f1a0bf1c

Github repo + build script here:
[https://github.com/opendxl-community/docker-misp](https://github.com/opendxl-community/docker-misp)
(note: after a git pull, update ```build.sh``` with your own passwords/FQDN, and then build the image)

Docker hub image here:
[https://hub.docker.com/r/opendxlcommunity/misp](https://hub.docker.com/r/opendxlcommunity/misp)

# What is this?

This is a fork of the excellent
[harvard-itsecurity/docker-misp](https://github.com/harvard-itsecurity/docker-misp)
project. The only difference between this fork and the upstream project at
present is some additional work in the Docker image to allow for data volumes to
be automatically mounted and initialized on startup of a new MISP container.
This fork exists as an experiment for quick standup of a MISP container in the
[Docker Kitematic UI](https://kitematic.com/) with a bit less reliance on
executing commands from the Docker shell. This fork will likely lag behind the
well-maintained upstream project. For purposes other than quick testing of a
MISP setup with Kitematic, it would be much better to use the
[harvard-itsecurity/docker-misp](https://github.com/harvard-itsecurity/docker-misp)
project directly rather than this fork.

This is an easy and highly customizable Docker container with MISP -
Malware Information Sharing Platform & Threat Sharing (http://www.misp-project.org)

Our goal was to provide a way to setup + run MISP in less than a minute!

We follow the official MISP installation steps everywhere possible,
while adding automation around tedious manual steps and configurations.

We have done this without sacrificing options and the ability to
customize MISP for your unique environment! Some examples include:
auto changing the salt hash, auto initializing the database, auto generating GPG
keys, auto generating working + secure configs, and adding custom
passwords/domain names/email addresses/ssl certificates.

The misp-modules extensions functionality has been included and can be
accessed from http://[dockerhostip]:6666/modules.
(thanks to Conrad)

# Build Docker container vs using Dockerhub binary?

We always recommend building your own Docker MISP image using our "build.sh" script.
This allows you to change all the passwords and customize a few config options.

That said, you can pull down the Dockerhub binary image, but this is
_not_ supported or recommended. It's there purely for convenience, and so that you can "get
a feel" for MISP without building it. It will by default contain "LOCALHOST" as all configured host everywhere, and this will only work on the same system or if you proxy/port forward.


Building your own MISP Docker image is incredibly simple:
```
git clone https://github.com/opendxl-community/docker-misp.git
cd docker-misp

# modify build.sh, specifically for:
# 1.) all passwords (ROOT, MYSQL)
# 2.) change at LEAST "MISP_FQDN" to your FQDN (domain)

# Build the docker image - will take a bit, but it's a one time thing!
# Run this from the root of "docker-misp"
./build.sh
```

This will produce an image called: ```opendxlcommunity/misp```

# How to run it in 2 steps:

About ```$docker-root``` - If you are running Docker on a Mac, there are some mount directory restrictions by default (see: https://docs.docker.com/docker-for-mac/osxfs/#namespaces). Your ```$docker-root``` needs to be either one of the supported defaults ("Users", "Volumes", "private", or "tmp"), otherwise, you must go to "Preferences" -> "File Sharing" and add your chosen $docker-root to the list.

We would suggest using ```/docker``` for your ```$docker-root```, and if using a Mac, adding that to the File Sharing list.

## 1. Start the container (Docker Kitematic)

If you just want to quickly spin up a new MISP container from [Docker
Kitematic](https://kitematic.com/), you can just create a new container from the
[latest opendxlcommunity/misp image on Docker Hub](https://hub.docker.com/r/opendxlcommunity/misp).

When Kitematic launches the new container, it dynamically assigns external
(published) port numbers to each of the ports that the container exposes. For
example, it may map the local Docker host's published port 32776 to the
container's SSL/TLS web server port, 443. On container restart, a different web
server port may then be mapped by default, for example, 32786.

In order for the application web server to be hosted properly, you should assign
a specific published port number for port 443 on the "Hostname / Ports" tab and
and then add a value for the `MISP_BASE_URL` environment variable on the
"General" tab which uses the same hostname and port.

For example if the "published ip:port" value on the "Hostname / Ports" tab
has "192.168.99.100:50443", the value for the `MISP_BASE_URL` environment
variable should be "https://192.168.99.100:50443". (Note that the "https://"
scheme is added by default for the `MISP_BASE_URL` variable, if not specified,
so you could also just enter "192.168.99.100:50443" as the value on the
"General" tab for brevity, if desired.)

If you want to have the container preserve / use data from external volumes, you
can map "local folder" values for the "docker folder" entries listed on the
"Volumes" tab:

* /etc/ssl/private - SSL/TLS certificates. See
  [this section](#how-to-use-custom-ssl-certificates) for more details.
* /var/lib/mysql - Database directory
* /var/www/MISP/app/Config - MISP application configuration  

During container startup, files will be copied / generated into the directory
volumes if they are empty at startup. The contents of the directories should be
preserved even if the container is restarted (or a new container referencing the
same volume(s) is created).

## 1. Start the container (Command-Line)

If you just want to quickly spin up a new MISP container from the command line
without needing to preserve any application data beyond the lifetime of the new
container, you can run the following command:

```
docker run -it --rm \
    -p 443:443 \
    -p 80:80 \
    -p 3306:3306 \
    -p 50000:50000 \
    opendxlcommunity/misp
```

In this mode, the container will, on its initial startup, generate an internal
database, app, and SSL certificate/key configuration.

If you want to have the container preserve / use data from external volumes, you
can run the following command instead:

```
docker run -it -d \
    -p 443:443 \
    -p 80:80 \
    -p 3306:3306 \
    -p 50000:50000 \
    -v $docker-root/misp-db:/var/lib/mysql \
    -v $docker-root/misp-config:/var/www/MISP/app/Config \
    opendxlcommunity/misp
```

A new database will automatically be created and stored into the
`$docker-root/misp-db` directory if the directory is empty as the container is
started up for the first time. The contents of the directory should be preserved
even if the container is restarted (or a new container referencing the same
volume is created).

Similarly, the contents of the `$docker-root/misp-config` directory will be
populated with default MISP configuration data only if the directory is
empty at container startup time.

If you intend to have the application web server be exposed on a non-default URL
&mdash; for example, on a port other than 443 &mdash; and/or the application web
server is not being externally hosted under "localhost" from the Docker host,
you should also specify a value for the `MISP_BASE_URL` environment variable
when starting the container. For example, the following command would specify
that the application be hosted on port 50443:

```
docker run -it -d \
    -e "MISP_BASE_URL=https://localhost:50443" \
    -p 50443:443 \
    -p 80:80 \
    -p 3306:3306 \
    -p 50000:50000 \
    -v $docker-root/misp-db:/var/lib/mysql \
    -v $docker-root/misp-config:/var/www/MISP/app/Config \
    opendxlcommunity/misp
```

## 2. Access Web URL
```
Go to: https://localhost (or your "MISP_FQDN" setting)

Login: admin@admin.test
Password: admin
```

And change the password! :)

# What can you customize/pass during build?
You can customize the ```build.sh``` script to pass custom:

* MYSQL_ROOT_PASSWORD
* MYSQL_MISP_PASSWORD
* POSTFIX_RELAY_HOST
* MISP_FQDN
* MISP_EMAIL

See build.sh for an example on how to customize and build your own image with custom defaults.

# How to use custom SSL Certificates:

During run-time, override ```/etc/ssl/private```

```
docker run -it -d \
    -p 443:443 \
    -p 80:80 \
    -p 3306:3306 \
    -p 50000:50000 \
    -v $docker-root/certs:/etc/ssl/private \
    -v $docker-root/misp-db:/var/lib/mysql \
    -v $docker-root/misp-config:/var/www/MISP/app/Config \
    opendxlcommunity/misp
```

And in your ```/certs``` dir, create private/public certs with file names:

* misp.key
* misp.crt

If the ```/certs``` dir does not contain a ```misp.crt``` and ```misp.key```
file at container startup time, a self-signed ```misp.crt``` and associated
```misp.key``` will be automatically generated.

# Security note in regards to key generation:
We have added "rng-tools" in order to help with entropy generation,
since users have mentioned that during the pgp generation, some
systems have a hard time creating enough "randomness". This in turn
uses a pseudo-random generator, which is not 100% secure. If this is a
concern for a production environment, you can either 1.) take out the
"rng-tools" part from the Dockerfile and re-build the container, or
2.) replace the keys with your own! For most users, this should not
ever be an issue. The "rng-tools" is removed as part of the build
process after it has been used.

# Contributions:
Conrad Crampton: conrad.crampton@secdata.com - @radder5 - RNG Tools and MISP Modules
