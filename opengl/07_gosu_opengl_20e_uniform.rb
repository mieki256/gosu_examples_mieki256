#! /usr/bin/env ruby
# -*- mode: ruby; coding: utf-8 -*-
# Last updated: <2023/10/15 09:49:55 +0900>
#
# Ruby + gosu + opengl の動作確認
# gosu-examples の opengl_integration.rb を弄ってOpenGL絡みの部分だけを列挙
#
# OpenGL 2.0風。
# GLSLでシェーダを書いて、三角形をVBOで描画しつつ、頂点カラーも付加するテスト
# 頂点配列中に頂点カラー情報も混在させて処理してみる。
# また、シェーダにグローバル情報を渡してみる
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
# OpenGLプログラミング - Wikibooks
# https://ja.wikibooks.org/wiki/OpenGLプログラミング
#
# gosu-examples
# https://github.com/gosu/gosu-examples

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

    @fade_v = 0.5
    @fade_v_d = 0.01

    init_shader   # プラグラマブルシェーダを設定

    # 三角形のデータ。頂点座標 + 頂点カラーの配列
    @attrs = [
      # x, y, r, g, b
      0.0, 1.0, 1.0, 1.0, 0.0,
      -1.0, -0.8, 0.0, 0.0, 1.0,
      1.0, -0.8, 1.0, 0.0, 0.0,
    ]

    # VBOを用意。バッファを生成
    unless $glbind
      # opengl
      @buffers = glGenBuffers(1)
      glBindBuffer(GL_ARRAY_BUFFER, @buffers[0])
    else
      # opengl-bindings
      @buffers = ' ' * 4
      glGenBuffers(1, @buffers)
      glBindBuffer(GL_ARRAY_BUFFER, @buffers.unpack('L')[0])
    end

    data = @attrs.pack("f*")
    glBufferData(GL_ARRAY_BUFFER, data.size, data, GL_STATIC_DRAW)
  end

  # 更新処理
  def update
    # フェード値を変化
    @fade_v += @fade_v_d
    if @fade_v < 0.0
      @fade_v = 0.0
      @fade_v_d *= -1
    elsif @fade_v > 1.0
      @fade_v = 1.0
      @fade_v_d *= -1
    end
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
    # coord2d に x,y を、v_color に r,g,b を渡す
    vs_src_a =<<EOS
#version 120
attribute vec2 coord2d;
attribute vec3 v_color;
varying vec3 f_color;
void main(void) {
  gl_Position = vec4(coord2d, 0.0, 1.0);
  f_color = v_color;
}
EOS

    # フラグメントシェーダ(Fragment Shader)のソース
    # グローバル情報(uniform)を持っている
    fs_src =<<EOS
#version 120
varying vec3 f_color;
uniform float fade;
void main(void) {
  gl_FragColor = vec4(f_color.x, f_color.y, f_color.z, fade);
}
EOS

    # 頂点シェーダを設定
    # ----------------------------------------
    vs = glCreateShader(GL_VERTEX_SHADER) # 1. シェーダオブジェクトを作成

    unless $glbind
      # opengl
      glShaderSource(vs, vs_src_a) # 2. シェーダのソースを渡す
      glCompileShader(vs)          # 3. シェーダをコンパイル

      # 4. 正しくコンパイルできたか確認
      compiled = glGetShaderiv(vs, GL_COMPILE_STATUS)
      abort "Error : Compile error in vertex shader" if compiled == GL_FALSE
    else
      # opengl-bindings
      glShaderSource(vs, 1, [vs_src_a].pack('p'), [vs_src_a.size].pack('I'))
      glCompileShader(vs)

      compiled = ' ' * 4
      glGetShaderiv(vs, GL_COMPILE_STATUS, compiled)
      abort "Error : Compile error in vertex shader" if compiled == 0
    end


    # フラグメントシェーダを設定
    # ----------------------------------------
    fs = glCreateShader(GL_FRAGMENT_SHADER) # 1. シェーダオブジェクトを作成

    unless $glbind
      # opengl
      glShaderSource(fs, fs_src) # 2. シェーダのソースを渡す
      glCompileShader(fs)        # 3. シェーダをコンパイル

      # 4. 正しくコンパイルできたか確認
      compiled = glGetShaderiv(fs, GL_COMPILE_STATUS)
      abort "Error : Compile error in fragment shader" if compiled == GL_FALSE
    else
      # opengl-bindings
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
    @id_coord2d = glGetAttribLocation(@shader, attr_name)
    abort "Error : Could not bind attribute #{attr_name}" if @id_coord2d == -1

    attr_name = "v_color"
    @id_v_color = glGetAttribLocation(@shader, attr_name)
    abort "Error : Could not bind attribute #{attr_name}" if @id_v_color == -1

    attr_name = "fade"
    @id_fade = glGetUniformLocation(@shader, attr_name)
    abort "Error : Could not bind uniform #{attr_name}" if @id_fade == -1
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

    # glUseProgram(@shader)

    glUniform1f(@id_fade, @fade_v)  # シェーダのグローバル情報を変更

    # float型のバイト数を求める
    # コレ、他にいい方法があるんじゃないの…？
    nf = [0.0].pack("f*").size

    glEnableVertexAttribArray(@id_coord2d)   # 頂点配列を有効化
    glEnableVertexAttribArray(@id_v_color)   # 頂点カラー配列を有効化

    unless $glbind
      # opengl
      glBindBuffer(GL_ARRAY_BUFFER, @buffers[0])   # 使用バッファを指定

      # 頂点配列を指定
      glVertexAttribPointer(@id_coord2d,  # 属性
                            2,         # 1頂点に値をいくつ使うか。x,yなら2
                            GL_FLOAT,  # 値の型
                            GL_FALSE,  # データ型が整数型なら正規化するか否か
                            5 * nf,    # stride. データの間隔
                            0          # オフセット
                           )

      # 頂点カラー配列を指定
      glVertexAttribPointer(@id_v_color,
                            3,         # 1頂点に値をいくつ使うか。x,y,zなら3
                            GL_FLOAT,
                            GL_FALSE,
                            5 * nf,
                            2 * nf
                           )
    else
      # opengl-bindings
      glBindBuffer(GL_ARRAY_BUFFER, @buffers.unpack('L')[0])
      glVertexAttribPointer(@id_coord2d, 2, GL_FLOAT, GL_FALSE, 5 * nf, 0)
      glVertexAttribPointer(@id_v_color, 3, GL_FLOAT, GL_FALSE, 5 * nf, 2 * nf)
    end

    # 描画
    glDrawArrays(GL_TRIANGLES,    # プリミティブの種類
                 0,               # 開始インデックス
                 @attrs.size / 5  # 頂点数
                )

    glDisableVertexAttribArray(@id_coord2d)  # 頂点配列を無効化
    glDisableVertexAttribArray(@id_v_color)  # 頂点カラー配列を無効化
  end
end

# Gosu main window class
class MyWindow < Gosu::Window

  def initialize
    super WIDTH, HEIGHT
    self.caption = "Ruby + Gosu + OpenGL, programmable shader + VBO + Vertex color"
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
