FROM ubuntu:18.04
MAINTAINER "ceceppa" <info@ceceppa.me>

# Let the conatiner know that there is no tty
ENV DEBIAN_FRONTEND noninteractive

#
# Set timezone to "Europe/London"
#
RUN echo Europe/London | tee /etc/timezone

ARG config=wp

#
# Install required packages
#
RUN apt-get update
RUN apt-get -y upgrade
RUN apt-get install -y software-properties-common
RUN add-apt-repository ppa:ondrej/php
RUN apt-get update
RUN apt-get install -y php7.2-fpm php7.2-mysql nginx curl vim
RUN apt-get -y install php7.2-curl php7.2-gd php7.2-intl php7.2-imagick php7.2-imap php7.2-memcache php7.2-pspell php7.2-recode php7.2-tidy php7.2-xmlrpc php7.2-xsl php7.2-xdebug php7.2-gd
RUN apt-get -y install php7.2-soap
RUN apt-get -y install php7.2-mbstring
RUN apt-get clean
RUN apt-get autoclean
RUN apt-get -y autoremove

#
# Copy nginx.conf
#
ADD files/nginx.conf /etc/nginx/nginx.conf
ADD files/mime.types /etc/nginx/mime.types
ADD files/default.${config}.conf /etc/nginx/sites-available/default

#
# Enable xDebug
#
RUN echo "xdebug.remote_enable = 1" >> /etc/php/7.2/mods-available/xdebug.ini
RUN echo "xdebug.remote_autostart = 1" >> /etc/php/7.2/mods-available/xdebug.ini
RUN echo "xdebug.remote_connect_back=0" >> /etc/php/7.2/mods-available/xdebug.ini
RUN echo "xdebug.remote_port=9000" >> /etc/php/7.2/mods-available/xdebug.ini
RUN echo 'xdebug.idekey=docker' >> /etc/php/7.2/mods-available/xdebug.ini
RUN echo 'xdebug.remote_log="/tmp/xdebug.log"' >> /etc/php/7.2/mods-available/xdebug.ini

# remote_host will be replaced with the environmental variable DOCKER_HOST_IP (see start.sh)
RUN echo 'xdebug.remote_host=' >> /etc/php/7.2/mods-available/xdebug.ini

#
# Adjust php fpm settings
#
RUN sed -i -e 's/upload_max_filesize = 2M/upload_max_filesize = 512M/g' etc/php/7.2/fpm/php.ini
RUN sed -i -e 's/upload_max_filesize = 8M/upload_max_filesize = 512M/g' etc/php/7.2/fpm/php.ini
RUN sed -i -e 's/max_execution_time = 30/max_execution_time = 300/g' /etc/php/7.2/fpm/php.ini
RUN sed -i -e 's/default_socket_timeout = 60/default_socket_timeout = 300/g' /etc/php/7.2/fpm/php.ini

# Copy the "start" script
ADD files/start.sh /usr/local/bin
RUN chmod 755 /usr/local/bin/start.sh

#nginx
EXPOSE 80
EXPOSE 443

#xdebug
EXPOSE 9000

VOLUME ["/var/www/html"]

CMD ["/usr/local/bin/start.sh"]
