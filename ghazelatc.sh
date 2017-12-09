#!/bin/sh
sed -i 's/ONBOOT=no/ONBOOT=yes/g' /etc/sysconfig/network-scripts/ifcfg-ens33
service network restart
# Activer l'interface reseau ens33
touch /etc/yum.repos.d/nginx.repo
echo "[nginx]
name=nginx repo
baseurl=http://nginx.org/packages/centos/$releasever/$basearch/
gpgcheck=0
enabled=1" >> /etc/yum.repos.d/nginx.repo
#Ajouter la repo de Nginx
yum install nginx -y
systemctl enable nginx.service
yum install httpd -y
systemctl enable httpd.service
#Installation de Nginx et Apache web server
cp -pr /etc/httpd/conf.d/ /etc/https/conf.d1/
cp /etc/httpd/conf/httpd.conf /etc/httpd/conf/httpd2.conf 
#Creer une deuxieme configuration de serveur Apache
sed -i 's/IncludeOptional conf.d/IncludeOptional conf.d2/g' /etc/httpd/conf/httpd2.conf
sed -i 's/Listen 80/Listen 82/g' /etc/httpd/conf/httpd2.conf
#Utiliser le port 82 pour la 2eme configuration d'apache 
sed -i 's/Listen 80/Listen 81/g' /etc/httpd/conf/httpd.conf
#Utiliser le port 81 pour la 1ere configuration d'apache 
echo "PidFile run/httpd.pid2" >> /etc/httpd/conf/httpd2.conf
#Changer le nom du fichier PidFile pour lancer deux instances d'Apache
/usr/sbin/httpd -f /etc/httpd/conf/httpd.conf -k start
/usr/sbin/httpd -f /etc/httpd/conf/httpd2.conf -k start
#Lancer les deux instances d'Apache avec les deux configurations
iptables -F
#supprimer les regles du pare-feu pour avoir acces au ports 80, 81 et 82
rm -f /etc/nginx/nginx.conf
touch /etc/nginx/nginx.conf
echo "user  nginx;
worker_processes  1;
error_log  /var/log/nginx/error.log warn;
pid        /var/run/nginx.pid;


events {
    worker_connections  1024;
}


http {
    include       /etc/nginx/mime.types;
    default_type  application/octet-stream;

    log_format  main  '$remote_addr - $remote_user [$time_local] "$request" '
                      '$status $body_bytes_sent "$http_referer" '
                      '"$http_user_agent" "$http_x_forwarded_for"';

    access_log  /var/log/nginx/access.log  main;
    sendfile        on;
    keepalive_timeout  65;
upstream ha {
                least_conn;
                server 127.0.0.1:81;
                server 127.0.0.1:82;
        }
    server {
        listen       80;
        server_name lbext.pax8.internal;
        location / {
                proxy_pass http://ha;
                proxy_set_header Host $host;
                proxy_set_header X-Real-IP $remote_addr;
                proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
                proxy_set_header X-Forwarded-Proto $scheme;
            root   html;
            index  index.html index.htm;
        }
        }
    include /etc/nginx/conf.d/*.conf;
}" >> /etc/nginx/nginx.conf
#Configurer Nginx pour utiliser les deux instances d'Apache
service nginx reload
#Recharger la configuration dans Nginx




