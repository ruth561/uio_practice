ドキュメントのURL https://www.kernel.org/doc/html/v4.12/driver-api/uio-howto.html

# memo
### UIOのメリット
① 極小のカーネルモジュールを書くだけで管理できる
② 開発の大部分をユーザー空間で行える。つまり、慣れ親しんだツールなどを用いてデバッグなどができる。
③ kernel crashが起きない。
④ カーネルの再コンパイルをしないでアップデートができる。

