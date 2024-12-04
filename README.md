# magic-powder

isucon用のスクリプト類

- bootstrap 必要なツールを入れるスクリプト
- Makefile よくやるオペレーションがまとまったファイル

## Bootstrap
### 初回実行
```
curl https://raw.githubusercontent.com/rerost/isucon-magic-powder/refs/heads/master/bootstrap -O && chmod +x bootstrap && ./bootstrap -r "git@github.com:rerost/hoge.git" -w "<Discord Webhook URL>"
```

### 2台目以降のサーバ
レポジトリへの保存をスキップ
```
curl https://raw.githubusercontent.com/rerost/isucon-magic-powder/refs/heads/master/bootstrap -O && chmod +x bootstrap && ./bootstrap -r "git@github.com:rerost/hoge.git" -w "<Discord Webhook URL>" -n
```

### デバッグ時
* レポジトリへの保存をスキップ
* ツールのインストールをスキップ
```
curl https://raw.githubusercontent.com/rerost/isucon-magic-powder/refs/heads/master/bootstrap -O && chmod +x bootstrap && ./bootstrap -r "git@github.com:rerost/hoge.git" -w "<Discord Webhook URL>" -n -s
```

## Usage

```
make help
```
