# mruby-license

mruby 及び組み込まれた GEM のライセンス条文をまとめて `<build-dir>/LICENSE.yml` ファイルとして出力します。


## できること

  - ビルド設定時にライセンス条文を追加する
  - 構築する mruby へ GEM のライセンス条文を追加・変更・削除する
  - ビルド時に `<build-dir>/LICENSE.yml` としてライセンス条文をまとめた情報を出力する


## くみこみかた

`build_config.rb` ファイルに GEM として追加して、mruby をビルドして下さい。

```ruby
MRuby::Build.new do |conf|
  conf.gem "mruby-license", github: "dearblue/mruby-license"
end
```


## つかいかた

### `build_config` で指定する追加的なライセンス条文

`conf.terms` プロパティに設定されたライセンス条文は、`<build-dir>/LICENSE.yaml` ファイルの一部となって出力されます。
この初期値は空の配列 (`[]`) です。追加したい場合、次のようにします:

```ruby
conf.terms << "path/to/ADDITIONAL-LICENSE"
```

ファイルパスとして、ビルドディレクトリを基準とした相対パスだけではなく、絶対パスで指定することも可能です。
また、与えられるのはファイルパスだけではなく、名前と条文内容を組み合わせたハッシュを与えることが出来ます。

`conf.terms` に直接指定することが出来るオブジェクトは、`nil`、パスを表す string、array、hash、それに加えて `#to_path` と `#read` メソッドの両方を持つオブジェクト (file や pathname を想定) です。

array の中には `conf.terms` に直接与えられるものが追加できます。

hash の中には、パス (名前) を表すオブジェクトをキーとして、内容とするオブジェクトを組にして指定できます
パスを表すオブジェクトは、文字列か `#to_path` メソッドを持つオブジェクト (file や pathname を想定) です。
内容とするオブジェクトは、条文内容としての文字列、文字列を返す proc、あるいは `#read` メソッドを持つオブジェクト (file、pathname または stringio を想定) です。

次に示す例は全て正しい指定方法です:

```ruby
conf.terms = "path1/to/LICENSE"
conf.terms << [ [ "/path2/to/LICENSE", [ File.open(/path3/to/COPYING) ] ], Pathname.new("path4/to/COPYRIGHT") ]
conf.terms << { "name5" => "License Terms #5" }
conf.terms = { "name6" => File.open("/path6/to/COPYRIGHT"), "name7" => Pathname.new("path7") }
conf.terms << [ { "name8" => proc { File.read("/path8/to/LICENSE") } } ]
```

ライセンス条文の内容が評価されて結果が `nil` となる場合、その項目は単純に無視されます。

### `mrbgem.rake` で指定するライセンス条文

ここで設定した内容は、`<build-dir>/LICENSE.yaml` ファイルに反映されます。

`spec.terms` プロパティの初期値は、各 GEM のトップディレクトリにライセンス条文ファイルがあれば自動で設定されます。
認識されるファイルの優先度は次のとおりです:

```
LICENSE > LICENSE.txt > LICENSE.md >
  COPYRIGHT > COPYRIGHT.txt > COPYRIGHT.md >
  COPYING > COPYING.txt > COPYING.md (lowest priorities)
```

これらのファイルが複数ある場合は優先度の高いファイルが選択されることに注意して下さい。

指定方法については、`MRuby::Build#terms` と同じですが、いくつかの差異があります:

  - `spec.terms` として指定する (`conf.terms` ではなく)
  - 初期値が異なる
  - 相対パスの基準ディレクトリは各 GEM のトップディレクトリ

その他の詳細は [追加的なライセンス条文](#追加的なライセンス条文) を確認して下さい。

ただし自分の GEM で `MRuby::Gem::Specification#terms` プロパティが常に利用可能であると想定するわけにはいかないはずです。
そのため特異メソッド `#terms_setup` を定義してその内部で操作することで、この懸念が無視できるでしょう。

```ruby
# <YOUR-GEM>/mrbgem.rake

MRuby::Gem::Specification.new("YOUR-GEM") do |spec|
  ...
  def spec.terms_setup
    self.terms = ...
  end
end
```

この `#terms_setup` メソッドは `mrbgem.rake` ファイルで定義するべきで、`build_config` ファイルで定義するべきではありません。
`#terms` プロパティを操作する必要がある場合、`build_config` の中であれば `mruby-license` を有効化した状態で行うべきです。

```ruby
# build_config.rb

MRuby::Build.new do |conf|
  ...
  conf.gem github: "dearblue/mruby-license"
  conf.gem mgem: "mruby-lz4" do |g|
    g.terms << "contrib/lz4/LICENSE"
  end
end
```

### 環境変数

  - `MRUBY_LICENSE_GEM_HIDDEN`

    環境変数 `MRUBY_LICENSE_GEM_HIDDEN` に `1` 以上の数値を入れると、ライブラリに含まれないように出来ます。
    ただし `MRuby::Build#gem` メソッドに渡したブロックが無視されます。


## Specification

  - Package name: mruby-license
  - Version: 1.0
  - Product quality: Public Preview
  - Author: [dearblue](https://github.com/dearblue)
  - Project page: <https://github.com/dearblue/mruby-license>
  - Licensing: [Creative Commons Zero License (CC0; Public Domain)](LICENSE)
  - Dependency external mrbgems: (NONE)
  - Bundled C libraries: (NONE)
