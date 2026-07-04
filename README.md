# apple-container-compose

Swift で書いた、Apple `container` CLI 向けの小さな Compose 風ランナーです。
`compose.yaml` から `container network create` / `container volume create` / `container run` などのコマンド列を作り、実行します。

## Requirements

- macOS
- Swift 6+
- Apple `container` CLI

Apple `container` は Apple silicon Mac と macOS 26 以降が前提です。

## Usage

```bash
swift run apple-container-compose up --dry-run
swift run apple-container-compose up
swift run apple-container-compose down
swift run apple-container-compose config
```

別ファイルを使う場合:

```bash
swift run apple-container-compose up -f compose.example.yaml --dry-run
```

## YAML

対応している基本フィールド:

- `project` または `name`
- `services.<name>.image`
- `services.<name>.ports`
- `services.<name>.environment`
- `services.<name>.volumes`
- `services.<name>.networks`
- `services.<name>.depends_on`
- `services.<name>.command`
- `volumes.<name>.size`
- `networks.<name>.internal`

`depends_on` は起動順と停止順に使います。ヘルスチェック待ちはまだ行いません。
