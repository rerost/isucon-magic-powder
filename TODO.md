## サーバの初期設定
- [  ] `curl https://raw.githubusercontent.com/rerost/isucon-magic-powder/refs/heads/master/bootstrap -O && chmod +x bootstrap && ./bootstrap`
- [  ] ファイルディスクリプタの設定

```
$ ulimit -n
1024

$ vi etc/security/limits.conf
isucon  hard  nofile  10000
isucon  soft  nofile  10000

# 入り直して確認
$ ulimit -n
```

## メトリクス周り
- [  ] Nginx
- [  ] Go(pprof))

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

func main() {
	go func() {
		log.Println(http.ListenAndServe("localhost:6060", nil))
	}()
}
```

## Makefile 周りに変数を入れる
- [  ] `cat Makefile | grep TODO`

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
