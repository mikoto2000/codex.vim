# codex.vim

ピュア Vim script (ただし外部プログラムは使う)の、 必要最低限以下の Codex クライアントです。

## Usage:

以下の関数が定義されているので、お好きなコマンドやキーマッピングを設定して使ってください。

codex にリクエストを送る:

```vim
:call codex#Request("こんにちは！！！！！")
```

リクエスト入力専用バッファから送る:

```vim
" 入力専用バッファを開く（1度だけでOK）
:call codex#OpenRequestBuffer()

" バッファにリクエスト本文を複数行で入力してから送信
:call codex#RequestFromBuffer()
```

コンテキストをリセットする:

```vim
:call codex#ResetContext()
```

### コマンド例:

```vim
" リクエストを送るコマンド
command! -nargs=+ CodexRequest call codex#Request(<q-args>)
command! CodexRequestFromBuffer call codex#RequestFromBuffer()
command! CodexOpenRequestBuffer call codex#OpenRequestBuffer()
command! CodexResetContext call codex#ResetContext()
```

## Requirements:

- Linux only
- curl コマンドにパスが通っていること

## License:

Copyright (C) 2025 mikoto2000

This software is released under the MIT License, see LICENSE

このソフトウェアは MIT ライセンスの下で公開されています。 LICENSE を参照してください。

## Author:

mikoto2000 <mikoto2000@gmail.com>
