`Duca` is a Docker image by [Ceceppa](https://ceceppa.me) for local PHP, WordPress and Laravel development.

**NOTE:** The image is intended for local development only!

## Features

The image is powered by nginx and is intented to be used with Nginx reverse proxy to local domain name.
The containers created with this image contains:

- nginx
- php-fpm 7.2
- XDEBUG
- HTTPs support
- you can access to your development site using a nice `https://[sitename].localhost` url

it _does_ not contain MySQL server and a shared MySQL instanced is intended to be used, also _no_ WordPress/Laravel instance will be downloaded/installed automatically.

## Setup

1. Built the image
2. Create the network
3. MySQL container
4. Nginx reverse proxy

### 1. Build the image

To build the image run:

#### For WordPress usage

```sh
docker build --no-cache . -t ducadev
```

#### For Laravel

```sh
docker --build-arg config=laravel --no-cache -- . -t ducadev
```

### 2. Create the network

A shared netword is needed to allow the containers to communicate with the MySQL and nginx instances.

To create you the following command:

```sh
docker network create --subnet=172.18.0.0/16 [network_name]
```

where `[network_name]` is the name of your choise for the network, for example `ducanet`:

```sh
docker network create --subnet=172.18.0.0/16 ducanet
```

_NOTE_: `network_name` cannot contain space or special characters.

## MySQL

A single shared MySQL container is needed:

```
docker run --name mysql --network ducanet -e MYSQL_ROOT_PASSWORD=[YOUR PASSWORD GOES HERE] -p 3306:3306 -v ~/Docker/mysql:/var/lib/mysql -d mysql/mysql-server
```

_NOTE_:

1. Replace `[YOUR PASSWORD GOES HERE]` with your password
1. Where: `~/Docker/mysql:/var/lib/mysql` is your local path where to store MySQL data

### Enable Remote connections

Let's create a user that we can use to connect our WordPress sites.

Access to the MySQL container with:

```
docker exec -t -i mysql bash
```

and after run the following command:

```
env # TO check the MYSQL_ROOT_PASSWORD
mysql -u root -p
```

once logged-in on MySQL server run the following commands:

```sql
CREATE USER '[YOUR USER NAME]'@'%' IDENTIFIED WITH mysql_native_password BY '[YOUR PASSWORD GOES HERE]';
GRANT ALL PRIVILEGES ON *.* TO '[YOUR USER NAME]'@'%' with grant option;
```

_don't forget to replace [YOUR PASSWORD GOES HERE] with your password_

## Example:

```sql
CREATE USER 'mysql'@'%' IDENTIFIED WITH mysql_native_password BY 'password';
GRANT ALL PRIVILEGES ON *.* TO 'mysql'@'%' with grant option;
```

## Nginx reverse proxy

Let's install and run the [NGINX Reverse Proxy](https://github.com/jwilder/nginx-proxy) container.

```
docker run -d --name nginx-proxy --network ducanet -p 80:80 -p 443:443 -e VIRTUAL_PROTO=https -e VIRTUAL_PORT=443 -v /var/run/docker.sock:/tmp/docker.sock:ro -v /etc/nginx/certs:/etc/nginx/certs jwilder/nginx-proxy
```

The parameter:

`-v /etc/nginx/certs:/etc/nginx/certs` is used to specify where to look up for the self-signed certificates for HTTPS.

`VIRTUAL_PROTO=https` and `VIRTUAL_PORT=443` are used for the HTTPs support

### HTTPs support

> Using certificates from real certificate authorities (CAs) for development can be dangerous or impossible.

And so, we have to generate self signed certificates to have https support.

We have two option to create them:

1. openssl
2. mkcert utils

#### openssl

This option allows us to create a certificate for each DOMAIN name we're going to use, and not for each single website.
So, suppose our DOMAIN name is `.localhost`, we can generate our keys:

```
openssl genrsa 4096 > localhost.key
chmod 400 localhost.key
openssl req -new -x509 -nodes -newkey rsa:4096 -days 365 -key localhost.key -out localhost.crt
```

now all the websites using that domain will use HTTPs;

_CONS:_

All our `*.localhost` domains are going to use the `httpS` protocol, but the browser will not recognise the certificate as valid. The same also happen with tools like [lighthouse](https://developers.google.com/web/tools/lighthouse/).

#### mkcert

> [mkcert](https://github.com/FiloSottile/mkcert) is a simple tool for making locally-trusted development certificates. It requires no configuration.

**Example:**

```sh
mkcert ${SITENAME}.localhost

sudo cp ${SITENAME}.localhost-key.pem /etc/nginx/certs/${SITENAME}.localhost.key
  sudo cp ${SITENAME}.localhost.pem /etc/nginx/certs/${SITENAME}.localhost.crt
```

_NOTE_: The certificates have to be copied in the nginx certs folder we created previously. Also the naming chosen by mkcert is slightly different from the one needed by nginx.

## PhpMyAdmin

We can install [phpmyadmin](https://www.phpmyadmin.net/) with the following command:

```
docker run --name phpmyadmin -d --link mysql:db --network ducanet -e VIRTUAL_HOST=phpmyadmin.localhost phpmyadmin/phpmyadmin
```

to be able to access to the domain `phpmyadmin.localhost` you need to edit your `/etc/hosts` file, and add the following line:

`127.0.0.1 phpmyadmin.localhost`

## Use the image

Once we have set up all the other containers needed, we can use our image to create WordPress or Laravel containers.

### Manual

#### WordPress

```
docker container run -d --name ceceppa.me --link mysql:db --network ducanet -e VIRTUAL_HOST=[MYDOMAIN.LOCALHOST] -v /home/ceceppa/Progetti/mysite:/var/www/html ducadev
```

You can also specify the path for the log folder using the option

```
 -v /home/alex/Progetti/mysite-logs:/var/log/nginx
```

##### wp-config

In your `wp-config.php` file the `DB_HOST` needs to be set to **mysql**

#### Laravel

```
docker container run -d --name ceceppa.me --link mysql:db --network ducanet -e VIRTUAL_HOST=[MYDOMAIN.LOCALHOST] -v /home/ceceppa/Progetti/mylaravelsite:/var/www/html ducadev
```

NOTE: To use for laravel development the image needs to be built using the additional `--build-arg config=laravel` parameter!

## Fix 401 Request entry too large & Customise nginx configuration

We need to increase the max upload size to be able to upload big files:

```
docker exec -it nginx-proxy bash

apt update
apt install -y vim
vi /etc/nginx/nginx.conf
```

add the following lines:

```
    keepalive_timeout  365;
    client_max_body_size 512M;
    proxy_connect_timeout       300;
    proxy_send_timeout          300;
    proxy_read_timeout          300;
    send_timeout                300;
    #proxy_set_header   Host             $http_host;
    proxy_set_header   X-Real-IP        $remote_addr;
    proxy_set_header   X-Forwarded-For  $proxy_add_x_forwarded_for;
    proxy_set_header   X-Forwared-User  $http_authorization;
```

uncomment `#gzip on;`

to save and exit press `ESC` and type `:w`

now restart the container with:

```
docker container restart nginx-proxy
```

## Duca script

This repo contains a easy to use bash script to help you to easily build/update the image and create the container needed.

```
DUCA: My docker image for local PHP, WordPress and Laravel development

Usage:
  duca [options] [project-name]

  OPTIONS:
    -w configure container for WordPress development
    -l configure container for Laravel development
    -d download WordPress
    -u download and compile the docker image
```

A part generating the container the script will also automatically set up the SSL certificate for you.

### Example

Create a **WordPress** container:

```
./duca -w mysite
```

For **Laravel**:

```
./duca -l mysite
```

Once the script is completed you can access to your website using **https://mysite.localhost**
