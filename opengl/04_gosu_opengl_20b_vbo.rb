#! /usr/bin/env ruby
# -*- mode: ruby; coding: utf-8 -*-
# Last updated: <2023/10/15 09:49:38 +0900>
#
# Ruby + gosu + opengl の動作確認
# gosu-examples の opengl_integration.rb を弄ってOpenGL絡みの部分だけを列挙
#
# OpenGL 2.0風、GLSLでシェーダを書いて三角形をVBOを使って描画するテスト
#
# == Require
#
# gem install gosu opengl
# or
# gem install gosu opengl-bindings
#
# == References
#
# 算譜記録帳: OpenGLでの頂点データの扱いの変化
# http://mklearning.blogspot.com/2014/08/opengl.html
#
# gosu-examples
# https://github.com/gosu/gosu-examples
# https://github.com/gosu/gosu-examples/blob/master/examples/opengl_integration.rb

require 'gosu'

$glbind = false

begin
  # gem install opengl
  require 'gl'
  include Gl
  puts "load opengl"
  $glbind = false
rescue LoadError
  # gem install opengl-bindings
  require 'opengl'
  OpenGL.load_lib
  include OpenGL
  puts "load opengl-bindings"
  $glbind = true
end

WIDTH, HEIGHT = 640, 480

class GlObj

  # 初期化
  def initialize

    init_shader   # プラグラマブルシェーダを設定

    # 三角形用の頂点配列. x,y のみを列挙
    @vtx = [
      0.0, 1.0,
      -1.0, -0.8,
      1.0, -0.8,
    ]

    # VBOを用意する
    unless $glbind
      # opengl
      @buffers = glGenBuffers(1)  # 頂点配列用のバッファを1つ生成
      glBindBuffer(GL_ARRAY_BUFFER, @buffers[0])  # バッファ種類を設定
    else
      # opengl-bindings
      @buffers = ' ' * 4
      glGenBuffers(1, @buffers)
      glBindBuffer(GL_ARRAY_BUFFER, @buffers.unpack('L')[0])
    end

    # バッファにデータを設定
    vtx = @vtx.pack("f*")  # Rubyの場合、データはpackして渡す
    glBufferData(GL_ARRAY_BUFFER,
                 vtx.size,          # データ群の長さ
                 vtx,               # データ群
                 GL_STATIC_DRAW
                )
  end

  # 更新処理
  def update
  end

  # 描画処理
  def draw(z)
    # Gosu.gl(z値)でOpenGLの描画を行う
    # 描画後にGosu側の描画ができるようにしてくれるらしい
    Gosu.gl(z) { exec_gl }
  end

  # プログラマブルシェーダの初期化
  def init_shader
    # 頂点シェーダ(Vertex Shader)のソース
    # gl_position に (x, y, 0.0, 1.0) を渡してる
    vs_src_a =<<EOS
#version 120
attribute vec2 coord2d;
void main(void) {
  gl_Position = vec4(coord2d, 0.0, 1.0);
}
EOS

    # フラグメントシェーダ(Fragment Shader)のソース
    # (r,g,b,a) の r,g をx,y座標で変化させるのでグラデーションになる
    # aを1ライン毎に変化させてるので縞々になる
    fs_src =<<EOS
#version 120
void main(void) {
  gl_FragColor[0] = gl_FragCoord.x / 640.0;
  gl_FragColor[1] = gl_FragCoord.y / 480.0;
  gl_FragColor[2] = 0.5;
  gl_FragColor[3] = floor(mod(gl_FragCoord.y, 2.0));
}
EOS

    # 頂点シェーダを設定
    # ----------------------------------------
    unless $glbind
      # opengl
      # 1. シェーダオブジェクトを作成
      vs = glCreateShader(GL_VERTEX_SHADER)

      # 2. シェーダのソースを渡す
      glShaderSource(vs, vs_src_a)

      # 3. シェーダをコンパイル
      glCompileShader(vs)

      # 4. 正しくコンパイルできたか確認
      compiled = glGetShaderiv(vs, GL_COMPILE_STATUS)
      abort "Error : Compile error in vertex shader" if compiled == GL_FALSE
    else
      # opengl-bindings
      vs = glCreateShader(GL_VERTEX_SHADER)
      glShaderSource(vs, 1, [vs_src_a].pack('p'), [vs_src_a.size].pack('I'))
      glCompileShader(vs)
      compiled = ' ' * 4
      glGetShaderiv(vs, GL_COMPILE_STATUS, compiled)
      abort "Error : Compile error in vertex shader" if compiled == 0
    end

    # フラグメントシェーダを設定
    # ----------------------------------------
    unless $glbind
      # opengl
      # 1. シェーダオブジェクトを作成
      fs = glCreateShader(GL_FRAGMENT_SHADER)

      # 2. シェーダのソースを渡す
      glShaderSource(fs, fs_src)

      # 3. シェーダをコンパイル
      glCompileShader(fs)

      # 4. 正しくコンパイルできたか確認
      compiled = glGetShaderiv(fs, GL_COMPILE_STATUS)
      abort "Error : Compile error in fragment shader" if compiled == GL_FALSE
    else
      # opengl-bindings
      fs = glCreateShader(GL_FRAGMENT_SHADER)
      glShaderSource(fs, 1, [fs_src].pack('p'), [fs_src.size].pack('I'))
      glCompileShader(fs)
      compiled = ' ' * 4
      glGetShaderiv(fs, GL_COMPILE_STATUS, compiled)
      abort "Error : Compile error in fragment shader" if compiled == 0
    end

    # 5. プログラムオブジェクトを作成
    @shader = glCreateProgram

    # 6. プログラムオブジェクトに対してシェーダオブジェクトを登録
    glAttachShader(@shader, vs)
    glAttachShader(@shader, fs)

    # 7. シェーダプログラムをリンク
    glLinkProgram(@shader)

    # 8. 正しくリンクできたか確認
    unless $glbind
      # opengl
      linked = glGetProgramiv(@shader, GL_LINK_STATUS)
      abort "Error : Linke error" if linked == GL_FALSE
    else
      # opengl-bindings
      linked = ' ' * 4
      glGetProgramiv(@shader, GL_LINK_STATUS, linked)
      linked = linked.unpack('L')[0]
      abort "Error : Linke error" if linked == 0
    end

    # 9. シェーダプログラムを適用
    glUseProgram(@shader)

    # 設定が終わったので後始末
    glDeleteShader(vs)
    glDeleteShader(fs)

    # シェーダに渡す属性のインデックス値(0,1,2,3等)を得る
    attr_name = "coord2d"
    @coord2d = glGetAttribLocation(@shader, attr_name)
    abort "Error : Could not bind attribute #{attr_name}" if @coord2d == -1
  end

  # OpenGL関係の処理
  def exec_gl
    glClearColor(0.0, 0.0, 0.0, 1.0)    # 画面クリア色を指定 (r,g,b,a)
    glClearDepth(1.0)                   # デプスバッファをクリア
    glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT)  # 画面クリア

    glEnable(GL_DEPTH_TEST)  # デプスバッファを使う

    glEnable(GL_BLEND)       # アルファブレンドを有効化
    glBlendFunc(GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA)

    # 三角形を描画
    # ----------------------------------------
    unless $glbind
      # opengl
      # glUseProgram(@shader)
      glBindBuffer(GL_ARRAY_BUFFER, @buffers[0])   # 使用するバッファを指定

      glEnableVertexAttribArray(@coord2d)   # 頂点配列を有効化

      glVertexAttribPointer(@coord2d,  # 属性
                            2,         # 1頂点に値をいくつ使うか。x,yなら2
                            GL_FLOAT,  # 値の型
                            GL_FALSE,  # データ型が整数型なら正規化するか否か
                            0,         # stride. データの間隔。詰まってるなら0
                            0          # オフセット
                           )

      # 描画
      glDrawArrays(GL_TRIANGLES,    # プリミティブの種類
                   0,               # 開始インデックス
                   @vtx.size / 2    # 頂点数
                  )
    else
      # opengl-bindings
      glBindBuffer(GL_ARRAY_BUFFER, @buffers.unpack('L')[0])
      glEnableVertexAttribArray(@coord2d)
      glVertexAttribPointer(@coord2d, 2, GL_FLOAT, GL_FALSE, 0, 0)
      glDrawArrays(GL_TRIANGLES, 0, @vtx.size / 2)
    end

    glDisableVertexAttribArray(@coord2d)  # 頂点配列を無効化
  end
end

# Gosu main window class
class MyWindow < Gosu::Window

  def initialize
    super WIDTH, HEIGHT
    self.caption = "Ruby + Gosu + OpenGL, programmable shader + VBO"
    @gl_obj = GlObj.new()
  end

  def update
    @gl_obj.update
  end

  def draw
    z = 0
    @gl_obj.draw(z)
  end

  def button_down(id)
    close if id == Gosu::KB_ESCAPE
  end
end

MyWindow.new.show
