## 事前準備
- [x] https://github.com/settings/ssh/new で `~/.ssh/isucon.pub` を登録
    - [ ] `ssh-keygen -f ~/.ssh/isucon && cat ~/.ssh/isucon.pub`
- [ ] レポジトリを作る https://github.com/new
- [ ] issueにこのTODOをコピペ & 置き換え
	- [ ] `<GITHUB_REPOSITORY>` e.g git@github.com:rerost/hoge.git
	- [ ] `<DISCORD_WEBHOOK_URL>`
	- [ ] `<DD_API_KEY>`

## サーバの初期設定
- [ ] ~/.ssh/config にIPアドレスを追加
- [ ] GitHubのSSH キーを配布する`scp ~/.ssh/isucon isucon-1:~/.ssh/id_rsa && ssh isucon-1 'sudo chown isucon:isucon ~/.ssh/id_rsa && sudo mv ~/.ssh/id_rsa /home/isucon/.ssh/id_rsa'`
- [ ] ベンチ回す
- [ ] 言語をGoにする
- [ ] ベンチ回す
- [ ] `git add` で必要そうなものをaddしておく。`.gitignore` もこのとき修正
- [ ] `ssh isucon-1 -tt 'cd /home/isucon && sudo -u isucon bash -c "curl https://raw.githubusercontent.com/rerost/isucon-magic-powder/refs/heads/master/bootstrap -O && chmod +x bootstrap && ./bootstrap -r <GITHUB_REPOSITORY> -w <DISCORD_WEBHOOK_URL> -d <DD_API_KEY>"'`
- [ ] ファイルディスクリプタの設定
- [ ] ベンチ回す

```
$ ulimit -n
1024

$ sudo vi /etc/security/limits.conf
isucon  hard  nofile  10000
isucon  soft  nofile  10000

# 入り直して確認
$ ulimit -n
```

## 2台目以降
- [ ] ~/.ssh/config にIPアドレスを追加
- [ ] GitHubのSSH キーを配布する`scp ~/.ssh/isucon  isucon-1:~/.ssh/id_rsa && ssh isucon-1 'sudo chown isucon:isucon ~/.ssh/id_rsa && sudo mv ~/.ssh/id_rsa /home/isucon/.ssh/id_rsa'`
- [ ] 言語をGoにする
- [ ] `ssh isucon-2 -tt 'cd /home/isucon && sudo -u isucon bash -c "curl https://raw.githubusercontent.com/rerost/isucon-magic-powder/refs/heads/master/bootstrap -O && chmod +x bootstrap && ./bootstrap -r <GITHUB_REPOSITORY> -w <DISCORD_WEBHOOK_URL> -n -d <DD_API_KEY>"'`

## 初期設定
- [ ] Makefileの準備
    - [ ] `cat Makefile | grep TODO`
- [ ] deployスクリプトの確認
    - [ ] Go(pprof))
    - [ ] `./deploy`
        - [  ] SSHのホスト名を設定する
- [ ] ベンチ回す
- [ ] バックアップ
    - [ ] `make schema_dump`
    - [ ] `make db_dump`
- [ ] ローカル環境の構築
    - [ ] `make setup-local-db`
    - [ ] `make restore-local-db`
    - [ ] `make check`
- [ ] メトリクスの設定
    - [ ] Nginx
    - [ ] `make alp` の結果をいい感じにする
- [ ] モニタリング
    - [ ] `htop`
    - [ ] `make ifstat`
- [ ] `go work init ./webapp/go`
- [ ] 2台目以降の動くようにする

Nginx
```
http {
...

	log_format ltsv "time:$time_local"
					"\thost:$remote_addr"
					"\tforwardedfor:$http_x_forwarded_for"
					"\treq:$request"
					"\tstatus:$status"
					"\tmethod:$request_method"
					"\turi:$request_uri"
					"\tsize:$body_bytes_sent"
					"\treferer:$http_referer"
					"\tua:$http_user_agent"
					"\treqtime:$request_time"
					"\tcache:$upstream_http_x_cache"
					"\truntime:$upstream_http_x_runtime"
					"\tapptime:$upstream_response_time"
					"\tvhost:$host";

	access_log /var/log/nginx/access.log ltsv;

...
}
```

Go(pprof)

```go
improt (
	_ "net/http/pprof"
)

func initialize(c echo.Context) error {
    var eg errgroup.Group
    eg.Go(func() error {
        // もともとある処理
        ...
        return nil
    })

    if err := eg.Wait(); err != nil {
        c.Logger().Errorf("failed to initialize: %v", err)
        return echo.NewHTTPError(http.StatusInternalServerError, "failed to initialize: "+err.Error())
    }

    ...
    startPprof()
    ...
}

....

func startPprof() {
	startTime := time.Now()
	log.Println("Starting pprof ...")
	// 非同期でコマンドを実行
	go func() {
		// ログファイルを開く（存在しない場合は作成）
		logFile, err := os.OpenFile("pprof_logs.txt", os.O_APPEND|os.O_CREATE|os.O_WRONLY, 0644)
		if err != nil {
			log.Printf("Failed to open log file: %v", err)
			return
		}
		defer logFile.Close()

		if err := runMakeCommand("/home/isucon", "pprof", logFile, startTime); err != nil {
			log.Printf("Failed to run 'make pprof': %v", err)
			return
		}

		if err := runMakeCommand("/home/isucon", "send_result", logFile, startTime); err != nil {
			log.Printf("Failed to run 'make send_result': %v", err)
			return
		}

		log.Println("End pprof")
	}()
}

func runMakeCommand(dir string, target string, out *os.File, startTime time.Time) error {
	cmd := exec.Command("make", target)
	cmd.Dir = dir // 実行ディレクトリを指定

	cmd.Stdout = out
	cmd.Stderr = out

	// 標準出力とエラー出力を結合して取得
	err := cmd.Run()
	if err != nil {
		log.Printf("Error executing 'make %s' in %s: %v\n", target, dir, err)
		return err
	}
	log.Printf("Output of 'make %s'", target)
	return nil
}

...

func main() {
	runtime.SetBlockProfileRate(1)
	runtime.SetMutexProfileFraction(1)
	go func() {
		log.Println(http.ListenAndServe("localhost:6060", nil))
	}()
}
```

## interpolateParams=true
```
	dsn := fmt.Sprintf(
		"%s:%s@tcp(%s:%s)/%s?charset=utf8mb4&parseTime=true&loc=Local&interpolateParams=true",
		user,
		password,
		host,
		port,
		dbname,
	)
```

もしくは
```go
	conf := mysql.NewConfig()
	...
	conf.InterpolateParams = true
```

## sshコマンド
```
ssh isucon -tt "cd /home/isucon && sudo su isucon"
```

## ポートフォワード
```
ssh -NL 1234:localhost:1234 isucon
```

## 環境変数をSystemdのEnvironmentFileから読み込む
```
set -a && source env.sh && set +a
```

## デプロイコマンド
```
make deploy
```

## シンボリックリンク
`/usr/bin/go` にアクセスすると `/usr/local/go/bin/go`  を参照する
`ln -sf <dst> <src>`

```
ln -sf /usr/local/go/bin/go /usr/bin/go
```

## 設定ファイルのGitHub同期
例:
```
MYSQL_CONF=/etc/mysql

sudo cp -a $MYSQL_CONF $HOME/config/mysql
sudo rm -rf $MYSQL_CONF
sudo ln -sf $HOME/config/mysql /etc
```

## MySQL
MySQL周りで `ERROR 29 (HY000) at line 1: File '/var/log/mysql/slow.log' not found (OS errno 13 - Permission denied)` が出たら
```
sudo chown mysql:mysql /var/log/mysql/slow.log
```

## MySQLのディスクへの書き込み頻度とかの調整
`config/mysql/mysql.conf.d/mysqld.cnf`

```
[mysqld]
bind-address = 0.0.0.0
innodb_flush_log_at_trx_commit = 2
disable-log-bin = 1
```

## MySQLに外からアクセスできないとき
`sudo mysql -u` で権限付与
isucon ユーザーに付与する場合

```
CREATE USER 'isucon'@'%' IDENTIFIED BY 'isucon';
GRANT ALL PRIVILEGES ON *.* TO 'isucon'@'%' WITH GRANT OPTION;
FLUSH PRIVILEGES;
```

## デバッグ用のテストファイル
```go
package main

import (
	"context"
	"fmt"
	"testing"
)

func TestHoge(t *testing.T) {
	sqlxDb, err := connectDB(nil)
	if err != nil {
		t.Fatal(err)
	}

	tx, err := sqlxDb.BeginTxx(context.Background(), nil)
	if err != nil {
		t.Fatal(err)
	}
	defer tx.Rollback()

	res, err := fillUsersResponse(context.Background(), tx, []UserModel{
		{ID: 1},
	})
	if err != nil {
		t.Fatal(err)
	}
	fmt.Println(res[0].IconHash)
	t.Error("OK")
}
```
