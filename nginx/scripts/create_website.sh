#!/bin/bash
echo "Welcome to this script to create a new nginx host"
mkdir -p tmp
chmod 777 tmp
script=false
echo "What is the hostname to be used?"
read -r hostname

echo "What port do you want to use?"
read -r port

# If use ssl
if [ "$port" = "443" ]
then
	echo "What is the path to the SSL certificate?"
	read -r sslcert
	echo "What is the path to the SSL Private Key?"
	read -r sslkey
fi

echo "Do you want to enable PHP?"
read -r enablephp

if [ "$enablephp" = "yes" ]
then
	echo "Enabled PHP"
else
	echo "Do you want to use WSGI?"
	read -r enablewsgi
	if [ "$enablewsgi" = "yes" ]
	then
		script=true
		echo "What is the path to the socket?"
		read -r wsgisocket
	fi
fi

if [ "$script" = false ]
then
	echo "What is the webroot of the website?"
	read -r webroot
fi
config=("# Generated by $(basename)")

config+=("server {")
if [ "$port" = "443" ]
then
	config+=("  listen $port ssl;")
	config+=("")
	config+=("  # Generated by enabling SSL")
	config+=("  ssl_certificate $sslcert;")
	config+=("  ssl_certificate_key $sslkey;")
else
	config+=("  listen $port;")
fi
config+=("")
config+=("  server_name $hostname;")
if [ $script = false ]
then
	config+=("  root $webroot;")
	config+=("  index index.html index.php;")
	config+=("")
	config+=("  location / {")
	config+=('    try_files $uri $uri/ =404;')
	config+=("  }")
fi
config+=("")
if [ "$enablephp" = "yes" ]
then
	config+=("  # Generated by enabling PHP")
	config+=("  location ~\.php$ {")
	config+=("    include snippets/fastcgi-php.conf;")
	config+=("    fastcgi_pass unix:/run/php/php8.1-fpm.sock;")
	config+=("  }")
	config+=("")
	config+=("  location ~ /\.ht {")
	config+=("    deny all;")
	config+=("  }")
fi
if [ "$enablewsgi" = "yes" ]
then
	config+=("  # Generated by enabling WSGI")
	config+=("  location / {")
	config+=("    include uwsgi_params;")
	config+=("    uwsgi_pass unix:$wsgisocket;")
	config+=("  }")
fi
config+=("}")
printf "%s\n" "${config[@]}" > "tmp/$hostname"
sudo cp "tmp/$hostname" "/etc/nginx/sites-available/$hostname"
sudo ln "/etc/nginx/sites-available/$hostname" "/etc/nginx/sites-enabled/$hostname"