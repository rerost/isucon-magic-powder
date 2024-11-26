シンボリックリンクの貼り方をいつも忘れるのでドキュメントに残しておく


```sh
MYSQL_CONF=/etc/mysql/my.cnf

sudo cp $MYSQL_CONF $HOME/config/mysql
sudo ln -sf $HOME/config/mysql/my.cnf /etc/mysql

NGINX_CONF=/etc/nginx

sudo cp -a $NGINX_CONF $HOME/config/nginx
sudo ln -sf $HOME/config/nginx /etc/nginx/
```
