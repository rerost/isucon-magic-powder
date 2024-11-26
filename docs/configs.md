シンボリックリンクの貼り方をいつも忘れるのでドキュメントに残しておく


```sh
MYSQL_CONF=/etc/mysql

sudo cp -a $MYSQL_CONF $HOME/config/mysql
sudo ln -sf $HOME/config/mysql /etc/mysql

NGINX_CONF=/etc/nginx

sudo cp -a $NGINX_CONF $HOME/config/nginx
sudo ln -sf $HOME/config/nginx /etc/nginx/
```
