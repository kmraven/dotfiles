# dotfiles

macOS と Linux の SSH 環境で共通利用するための dotfiles です。設定ファイルはコピーせず、この clone へのシンボリックリンクとして配置します。

## Linux への導入

最低限 `git`、`bash`、`zsh`、`vim` が必要です。代表的なディストリビューションでは次のように導入できます。

```sh
# Debian / Ubuntu
sudo apt update && sudo apt install git bash zsh vim

# Fedora / RHEL 系
sudo dnf install git bash zsh vim-enhanced

# Arch Linux
sudo pacman -S git bash zsh vim

# Alpine Linux
sudo apk add git bash zsh vim
```

clone 後にインストーラーを実行します。既存の設定がある場合、`--backup` はそれらを `~/.dotfiles-backup/<日時>/` へ退避してからリンクします。

```sh
git clone https://github.com/kmraven/dotfiles.git ~/.dotfiles
cd ~/.dotfiles
./install.sh --backup
./doctor.sh
exec zsh -l
```

GitHub に SSH 鍵を登録済みなら、clone URL は `git@github.com:kmraven/dotfiles.git` でも構いません。

ログインシェルを恒久的に変更できる環境では、次も実行できます。

```sh
chsh -s "$(command -v zsh)"
```

管理されたサーバーで `chsh` が許可されていない場合は、ログイン後に `exec zsh -l` を実行するか、`ssh -t HOST zsh -l` で接続します。

## オプション機能

設定は、次のコマンドが未導入でも zsh の起動に失敗しないようになっています。必要な機能だけ各 OS のパッケージマネージャーで追加してください。

| コマンド | 有効になる機能 |
| --- | --- |
| `starship` | Starship プロンプト |
| `yazi`, `ya` | `y` 関数とファイルマネージャー |
| `micromamba` | 初期化と `conda` エイリアス |
| `pwgen` | 12 文字パスワード生成エイリアス |
| `docker` | `dc`, `dps` エイリアス |
| `g++` | `gpp` エイリアス |
| `git-lfs` | Git LFS フィルター |
| `latexmk` | `.latexmkrc` |

Yazi を導入したホストでは、リンク作成後に SSHFS プラグインを取得します。

```sh
ya pkg install
```

Starship の記号を正しく表示するには、SSH クライアント側のターミナルに Nerd Font を設定してください。

## ホスト固有の設定

秘密情報やホスト固有設定は、このリポジトリに追加せず `~/.zshrc.local` に記述します。このファイルは `.zshrc` の最後に読み込まれます。

既定値は環境変数で変更できます。

```sh
# micromamba の環境保存先
export MAMBA_ROOT_PREFIX="$HOME/micromamba"
```

`JAVA_HOME` と `DISPLAY` がすでに設定されている場合は上書きしません。特に SSH の X11 forwarding で設定された `DISPLAY` は保持されます。

## 安全性と更新

- `install.sh` は `manifest.txt` に明記されたファイルだけを扱います。
- `--backup` なしでは、内容の異なる既存ファイルや別リンクを上書きしません。
- `doctor.sh` は依存コマンド、構文、リンク状態、Git TLS 設定を読み取り専用で確認します。
- `tests/test.sh` は一時 HOME で導入、競合保護、バックアップ、旧形式リンク、削除を検証します。
- clone を削除するとリンクが切れるため、不要になった場合は先に `./uninstall.sh` を実行してください。

更新は clone 内で行います。

```sh
cd ~/.dotfiles
git pull --ff-only
./install.sh
./doctor.sh
```

変更後の回帰テストは次で実行できます。

```sh
./tests/test.sh
```

## アンインストール

```sh
cd ~/.dotfiles
./uninstall.sh
```

この clone を参照しているリンクだけを削除します。バックアップは自動では復元・削除しません。
