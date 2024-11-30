.DEFAULT_GOAL := help

APP_DIR := TODO
APP_UNIT_NAME := TODO
IF_NAME := TODO # e.g. enp39s0

NGINX_LOG := /var/log/nginx/access.log
MYSQL_SLOW_LOG := /var/log/mysql/slow.log

MYSQL_CONFIG := /etc/mysql/my.cnf
NGINX_CONFIG := /etc/nginx/nginx.conf

DB_HOST := 127.0.0.1
DB_PORT := 3306
DB_USER := TODO
DB_PASS := TODO
DB_NAME := TODO

EDIT_MYSQL_CONFIG := $(APP_DIR)/my.cnf
EDIT_NGINX_CONFIG := $(APP_DIR)/nginx.conf

.PHONY: help
help: ## show help
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' ${MAKEFILE_LIST} | sort | awk 'BEGIN {FS = ":.*?## "}; { \
		printf "\033[36m%-20s\033[0m %s\n", $$1, $$2 \
	}'

.PHONY: log_reset
log_reset: ## logファイルを初期化する
	@sudo cp /dev/null $(MYSQL_SLOW_LOG)
	@sudo cp /dev/null $(NGINX_LOG)
	@sudo cp /dev/null profile.pb.gz
	@sudo cp /dev/null profile.html
	@sudo cp /dev/null profile.png

.PHONY: alp
alp: ## alpのログを見る
	@sudo cat $(NGINX_LOG) | alp ltsv --sort sum -r
	# -m "/posts/[0-9]+,/@\w+,/image/\d+"

.PHONY: slow
slow: ## スロークエリを見る
	@sudo pt-query-digest $(MYSQL_SLOW_LOG)

.PHONY: slow_on
slow_on: ## mysqlのslowログをonにする
	@sudo mysql -e "set global slow_query_log_file = '$(MYSQL_SLOW_LOG)'; set global long_query_time = 0; set global slow_query_log = ON;"

.PHONY: slow_off
slow_off: ## mysqlのslowログをoffにする
	@sudo mysql -e "set global slow_query_log = OFF;"

.PHONY: show_slow_config
show_slow_config: ## mysqlのslowログ設定を確認するコマンド
	@sudo mysql -e "show variables like 'slow_query%'"

.PHONY: send_result
send_result: ## discordにalpとslowの出力を送信する
	@make alp  > tmp.txt && discocat -f tmp.txt --filename alp.md
	@make slow > tmp.txt && discocat -f tmp.txt --filename slow_log.txt
	discocat -f profile.pb.gz --filename profile.pb.gz
	discocat -f profile.html --filename profile.html
	discocat -f profile.png --filename profile.png

.PHONY: dump_schema
dump_schema:
	mysqldef -h $(DB_HOST) -u $(DB_USER) -p$(DB_PASS) $(DB_NAME) --export > schema.sql

.PHONY: dry_run_schema
dry_run_schema:
	mysqldef -h $(DB_HOST) -u $(DB_USER) -p$(DB_PASS) $(DB_NAME) --dry-run < schema.sql

.PHONY: apply_schema
apply_schema:
	mysqldef -h $(DB_HOST) -u $(DB_USER) -p$(DB_PASS) $(DB_NAME) < schema.sql


.PHONY: mysql
mysql: ## mysql接続コマンド
	mysql -h $(DB_HOST) -u $(DB_USER) -p$(DB_PASS) $(DB_NAME)

.PHONY: pprof
pprof:
	curl -o profile.pb.gz http://localhost:6060/debug/pprof/profile?seconds=60
	go tool pprof --no_browser -http=:1234 profile.pb.gz < /dev/null & echo $$! > pprof.pid
	sleep 2
	wget -O profile.html http://localhost:1234/ui/flamegraph
	kill `cat pprof.pid`
	rm -f pprof.pid
	html2png -html=profile.html -output=profile.png

.PHONY: application_build
application_build: ## application build (wip)
	cd $(APP_DIR) && make
	# TODO: ローカルでの確認ができるようになったら
	# @make apply_schema

.PHONY: application_restart
application_restart: ## application restart (wip)
	# TODO systemctl を利用しているか確認する
	sudo systemctl stop $(APP_UNIT_NAME)
	sudo systemctl start $(APP_UNIT_NAME)

.PHONY: middleware_restart
middleware_restart: ## mysqlとnginxのrestart
	sudo systemctl restart mysql
	sudo systemctl restart nginx

.PHONY: restart
restart: application_restart middleware_restart ## application, mysql, nginxのリスタート

.PHONY: daemon_reload
daemon_reload:
	sudo systemctl daemon-reload

.PHONY: bench
bench: daemon_reload log_reset application_build restart slow_on ## bench回す前に実行するコマンド(これで全ての前処理が完了する状態を作る)
	# TODO: ローカルでの確認ができるようになったら
	# @make apply_schema

.PHONY: log
log: ## logをtailする
	sudo journalctl -u $(APP_UNIT_NAME) -f

.PHONY: ifstat
ifstat: ## ifstatを見る
	ifstat -i $(IF_NAME) 1

.PHONY: check
check: application_build dry_run_schema

.PHONY: commit
commit:
	git add -u .
	git commit --allow-empty -m "isucon"
	git push origin HEAD

.PHONY: db_dump
db_dump:
	mysqldump -u$(DB_USER) -p$(DB_PASS) $(DB_NAME) > dump.sql

.PHONY: setup-local-db
setup-local-db:
	mysql -u root -e "CREATE DATABASE IF NOT EXISTS $(DB_NAME);"
	mysql -u root -e "CREATE USER IF NOT EXISTS '$(DB_USER)'@'localhost' IDENTIFIED BY '$(DB_PASS)';"
	mysql -u root -e "GRANT ALL PRIVILEGES ON $(DB_NAME).* TO '$(DB_USER)'@'localhost';"

.PHONY: restore-local-db
restore-local-db:
	scp isucon:/home/isucon/dump.sql dump.sql
	mysql -u $(DB_USER) -p$(DB_PASS) $(DB_NAME) < dump.sql
