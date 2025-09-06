# codex.vim

ピュア Vim script (ただし外部プログラムは使う)の、 必要最低限以下の Codex クライアントです。

## Usage:

codex にリクエストを送る:

```vim
:call codex#Request("こんにちは！！！！！")
```

コンテキストをリセットする:

```vim
:call codex#ResetContext()
```

## Requirements:

curl コマンドにパスが通っていること。

## License:

Copyright (C) 2025 mikoto2000

This software is released under the MIT License, see LICENSE

このソフトウェアは MIT ライセンスの下で公開されています。 LICENSE を参照してください。

## Author:

mikoto2000 <mikoto2000@gmail.com>
