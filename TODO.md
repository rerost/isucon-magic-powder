## 事前準備
- [ ] レポジトリを作る https://github.com/new
- [ ] issueにこのTODOをコピペ

## サーバの初期設定
- [ ] ~/.ssh/config にIPアドレスを追加
- [ ] ベンチ回す
- [ ] 言語をGoにする
- [ ] ベンチ回す
- [ ] `git add` で必要そうなものをaddしておく。`.gitignore` もこのとき修正
- [ ] `curl https://raw.githubusercontent.com/rerost/isucon-magic-powder/refs/heads/master/bootstrap -O && chmod +x bootstrap && ./bootstrap`
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

## 初期設定
- [ ] Makefileの準備
    - [ ] `cat Makefile | grep TODO`
- [ ] deployスクリプトの確認
    - [ ] Go(pprof))
    - [ ] `./deploy`
        - [  ] SSHのホスト名を設定する
- [ ] ベンチ回す
- [ ] バックアップ
    - [ ] `make dump_schema`
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
    ...
    startPprof()
}

....

func startPprof() {
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

		if err := runMakeCommand("/home/isucon", "pprof", logFile); err != nil {
			log.Printf("Failed to run 'make pprof': %v", err)
			return
		}

		if err := runMakeCommand("/home/isucon", "send_result", logFile); err != nil {
			log.Printf("Failed to run 'make send_result': %v", err)
			return
		}

		log.Println("End pprof")
	}()
}

func runMakeCommand(dir string, target string, out *os.File) error {
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

## sshコマンド
```
ssh isucon -tt "cd /home/isucon && sudo su isucon"
```

## デプロイコマンド
```
make check && git push origin HEAD && ./deploy $(git branch --show-current)
```
