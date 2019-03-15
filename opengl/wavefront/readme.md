<!-- -*- encoding: utf-8 -*- -->

Rubyでwavefront形式の3Dモデルデータを読み込んでみる
===================================================

wavefront形式(.obj + .mtl)の3Dモデルデータファイルは、テキストファイルなので解析しやすい、らしい。

Rubyでも読み込めないか試してみたい。
もし読み込めたら、ソレをOpenGLライブラリを使って描画してみたい。


wavefrontライブラリを使ってみる
-------------------------------

[GitHub - MishaConway/wavefront-ruby: wavefront parser and exporter for ruby](https://github.com/MishaConway/wavefront-ruby )

[wavefront | RubyGems.org | your community gem host](https://rubygems.org/gems/wavefront/versions/0.1.2 )

wavefrontファイルを読み込むライブラリが公開されてるように見えるので、試用してみる。

インストールは以下。

    gem install wavefront

blenderでスザンヌ(猿)を置いて、wavefront形式でエクスポートして試してみたが…。

    irb(main):001:0> require "wavefront"
    => true
    irb(main):002:0> w = Wavefront::File.new("suzanne.obj")
    NoMethodError: undefined method `set_smoothing_group' for nil:NilClass
            from C:/Ruby/Ruby22/lib/ruby/gems/2.2.0/gems/wavefront-0.1.2/lib/wavefront/wavefront_object.rb:159:in `parse!'
            from C:/Ruby/Ruby22/lib/ruby/gems/2.2.0/gems/wavefront-0.1.2/lib/wavefront/wavefront_object.rb:9:in `initialize'
            from C:/Ruby/Ruby22/lib/ruby/gems/2.2.0/gems/wavefront-0.1.2/lib/wavefront/wavefront_file.rb:19:in `new'
            from C:/Ruby/Ruby22/lib/ruby/gems/2.2.0/gems/wavefront-0.1.2/lib/wavefront/wavefront_file.rb:19:in `initialize'
            from (irb):2:in `new'
           from (irb):2
           from C:/Ruby/Ruby22/bin/irb:11:in `<main>'

いきなりエラー。

### 一応説明文をメモ

Google翻訳の結果も併記。

So here is a little primer.  
ここには短い入門があります。

A wavefront object basically contains a single object.  
wavefrontオブジェクトは、基本的に単一のオブジェクトを含む。

This single object contains several groups.  
この単一オブジェクトにはいくつかのグループが含まれています。

Each of these groups can contain sub smoothing groups.  
これらの各グループには、サブスムージンググループを含めることができます。

Both groups and smoothing groups have a list of triangles.  
グループとスムージンググループの両方に三角形のリストがあります。

Each triangle contains three vertices while each vertex contains a position, normal, and texture coordinate.  
各三角形には3つの頂点が含まれ、各頂点には位置、法線、およびテクスチャの座標が含まれます。

I've tried to make it so that the parsed WavefrontFile instance represents this hierarchy as much as possible.  
私は、解析されたWavefrontFileインスタンスができるだけこの階層を表すようにしようとしました。

Now with primer aside, let's go over some sample values we can extract from the WavefrontFile instance.  
今プライマリーで、WavefrontFileインスタンスから抽出できるいくつかのサンプル値を見て行きましょう。


チェック用テクスチャ画像について
--------------------------------

[Arahnoid/UVChecker-map: A collection of free images what can be used during unwrapping of 3D models](https://github.com/Arahnoid/UVChecker-map )

Public Domain で使える。


