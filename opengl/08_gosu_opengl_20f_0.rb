#! /usr/bin/env ruby
# -*- mode: ruby; coding: utf-8 -*-
# Last updated: <2023/10/15 09:50:01 +0900>
#
# Ruby + gosu + opengl の動作確認
# gosu-examples の opengl_integration.rb を弄って
# OpenGL絡みの部分だけを列挙
#
# OpenGL 2.0風。
# GLSLでシェーダを書いて、四角形を回転させるテスト
# 赤一色で塗り潰すだけのシェーダ
#
# == Require
#
# gem install gosu opengl
# or
# gem install gosu opengl-bindings
#
# == References
#
# 床井研究室 - 第１回 シェーダプログラムの読み込み
# http://marina.sys.wakayama-u.ac.jp/~tokoi/?date=20051006
#
# 床井研究室 - 第２回 Gouraud シェーディングと Phong シェーディング
# http://marina.sys.wakayama-u.ac.jp/~tokoi/?date=20051007
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

TEX_FILE = "UVCheckerMap01-1024.png"

WIDTH, HEIGHT = 640, 480

# ライト設定
LIGHT_POS = [0.0, 0.0, 5.0, 1.0]   # 光源の位置
LIGHT_AMB = [0.1, 0.1, 0.1, 1.0]   # 環境光
LIGHT_DIF = [1.0, 1.0, 1.0, 1.0]   # 拡散光
LIGHT_SPE = [1.0, 1.0, 1.0, 1.0]   # 鏡面光

# opengl-bindings 使用時のために pack しておく
LIGHT_POS_PACK = LIGHT_POS.pack("f*")
LIGHT_AMB_PACK = LIGHT_AMB.pack("f*")
LIGHT_DIF_PACK = LIGHT_DIF.pack("f*")
LIGHT_SPE_PACK = LIGHT_SPE.pack("f*")

# 材質設定
DIFFUSE = [0.5, 0.5, 0.5, 1.0]
SPECULAR = [0.3, 0.3, 0.3, 1.0]
SHININESS = 100.0

DIFFUSE_PACK = DIFFUSE.pack("f*")
SPECULAR_PACK = SPECULAR.pack("f*")

class GlObj

  # 初期化
  def initialize(pos_x = 0.0, pos_y = 0.0, pos_z = -3.0)
    @pos = { :x => pos_x, :y => pos_y, :z => pos_z }
    @rot_x = 10.0
    @rot_y = 0.0

    # プラグラマブルシェーダを設定
    init_shader

    # 四角形の頂点データ
    @attrs = [
      # x, y, z, nx, ny, nz,
      -1.0, -1.0, 0.0, 0.0, 0.0, 1.0,
      1.0, -1.0, 0.0, 0.0, 0.0, 1.0,
      1.0, 1.0, 0.0, 0.0, 0.0, 1.0,
      -1.0, 1.0, 0.0, 0.0, 0.0, 1.0,
    ]

    # VBOを用意。バッファを生成してデータを設定。
    unless $glbind
      # opengl
      @buffers = glGenBuffers(1)
      glBindBuffer(GL_ARRAY_BUFFER, @buffers[0])  # バッファ種類を設定
    else
      # opengl-bindings
      @buffers = ' ' * 4
      glGenBuffers(1, @buffers)
      glBindBuffer(GL_ARRAY_BUFFER, @buffers.unpack('L')[0])
    end
    data = @attrs.pack("f*")  # Rubyの場合、データはpackして渡す
    glBufferData(GL_ARRAY_BUFFER, data.size, data, GL_STATIC_DRAW)
  end

  # 更新処理
  def update
    @rot_y = (@rot_y + 1.0) % 360.0
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
    vs_src =<<EOS
#version 120
void main(void)
{
  gl_Position = gl_ModelViewProjectionMatrix * gl_Vertex;
}
EOS

    # フラグメントシェーダ(Fragment Shader)のソース
    fs_src =<<EOS
#version 120
void main (void)
{
  gl_FragColor = vec4(1.0, 0.0, 0.0, 1.0);
}
EOS

    # 頂点シェーダを設定
    vs = glCreateShader(GL_VERTEX_SHADER)  # 1. シェーダオブジェクト作成
    unless $glbind
      glShaderSource(vs, vs_src)           # 2. シェーダのソースを渡す
      glCompileShader(vs)                  # 3. シェーダをコンパイル

      # 4. 正しくコンパイルできたか確認
      compiled = glGetShaderiv(vs, GL_COMPILE_STATUS)
      abort "Error : Compile error in vertex shader" if compiled == GL_FALSE
    else
      glShaderSource(vs, 1, [vs_src].pack('p'), [vs_src.size].pack('I'))
      glCompileShader(vs)
      compiled = ' ' * 4
      glGetShaderiv(vs, GL_COMPILE_STATUS, compiled)
      abort "Error : Compile error in vertex shader" if compiled == 0
    end

    # フラグメントシェーダを設定
    fs = glCreateShader(GL_FRAGMENT_SHADER)  # 1.
    unless $glbind
      glShaderSource(fs, fs_src)             # 2.
      glCompileShader(fs)                    # 3.
      compiled = glGetShaderiv(fs, GL_COMPILE_STATUS)  # 4.
      abort "Error : Compile error in fragment shader" if compiled == GL_FALSE
    else
      glShaderSource(fs, 1, [fs_src].pack('p'), [fs_src.size].pack('I'))
      glCompileShader(fs)
      compiled = ' ' * 4
      glGetShaderiv(fs, GL_COMPILE_STATUS, compiled)
      abort "Error : Compile error in fragment shader" if compiled == 0
    end

    @shader = glCreateProgram    # 5. プログラムオブジェクト作成
    glAttachShader(@shader, vs)  # 6. シェーダオブジェクトを登録
    glAttachShader(@shader, fs)
    glLinkProgram(@shader)       # 7. シェーダプログラムをリンク

    # 8. 正しくリンクできたか確認
    unless $glbind
      linked = glGetProgramiv(@shader, GL_LINK_STATUS)
      abort "Error : Linke error" if linked == GL_FALSE
    else
      linked = ' ' * 4
      glGetProgramiv(@shader, GL_LINK_STATUS, linked)
      linked = linked.unpack('L')[0]
      abort "Error : Linke error" if linked == 0
    end

    glUseProgram(@shader)        # 9. シェーダプログラムを適用

    glDeleteShader(vs)           # 10. 設定が終わったので後始末
    glDeleteShader(fs)
  end

  # OpenGL関係の処理
  def exec_gl
    glClearColor(0.3, 0.3, 1.0, 0.0)    # 画面クリア色を r,g,b,a で指定
    glClearDepth(1.0)                   # デプスバッファをクリア
    glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT)  # 画面クリア

    glDepthFunc(GL_LESS)       # 奥行き比較関数の種類を指定

    glEnable(GL_DEPTH_TEST)    # デプスバッファを使う

    glEnable(GL_BLEND)         # アルファブレンドを有効化
    glBlendFunc(GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA)

    glDisable(GL_CULL_FACE)    # 片面表示を無効化

    glEnable(GL_LIGHTING)      # 光源の有効化
    glEnable(GL_LIGHT0)        # 0番目のライトを有効化

    unless $glbind
      glLightfv(GL_LIGHT0, GL_POSITION, LIGHT_POS)  # 光源の位置
      glLightfv(GL_LIGHT0, GL_AMBIENT, LIGHT_AMB)   # 環境光
      glLightfv(GL_LIGHT0, GL_DIFFUSE, LIGHT_DIF)   # 拡散光
      glLightfv(GL_LIGHT0, GL_SPECULAR, LIGHT_SPE)  # 鏡面光
    else
      glLightfv(GL_LIGHT0, GL_POSITION, LIGHT_POS_PACK)
      glLightfv(GL_LIGHT0, GL_AMBIENT, LIGHT_AMB_PACK)
      glLightfv(GL_LIGHT0, GL_DIFFUSE, LIGHT_DIF_PACK)
      glLightfv(GL_LIGHT0, GL_SPECULAR, LIGHT_SPE_PACK)
    end

    glMatrixMode(GL_PROJECTION)  # 透視投影の設定
    glLoadIdentity               # 変換行列の初期化
    glFrustum(-0.10, 0.10, -0.075, 0.075, 0.1, 100)  # 視野範囲を設定

    glMatrixMode(GL_MODELVIEW)  # モデルビュー変換の指定
    glLoadIdentity              # 変換行列の初期化

    unless $glbind
      glTranslate(@pos[:x], @pos[:y], @pos[:z])  # 平行移動
      glRotate(@rot_x, 1.0, 0.0, 0.0)            # 回転
      glRotate(@rot_y, 0.0, 1.0, 0.0)            # 回転
    else
      glTranslatef(@pos[:x], @pos[:y], @pos[:z])
      glRotatef(@rot_x, 1.0, 0.0, 0.0)
      glRotatef(@rot_y, 0.0, 1.0, 0.0)
    end

    # 材質を設定
    unless $glbind
      glMaterialfv(GL_FRONT_AND_BACK, GL_AMBIENT_AND_DIFFUSE, DIFFUSE)
      glMaterialfv(GL_FRONT_AND_BACK, GL_SPECULAR, SPECULAR)
      glMaterialf(GL_FRONT_AND_BACK, GL_SHININESS, SHININESS)
    else
      glMaterialfv(GL_FRONT_AND_BACK, GL_AMBIENT_AND_DIFFUSE, DIFFUSE_PACK)
      glMaterialfv(GL_FRONT_AND_BACK, GL_SPECULAR, SPECULAR_PACK)
      glMaterialf(GL_FRONT_AND_BACK, GL_SHININESS, SHININESS)
    end

    # 四角形を描画
    # ----------------------------------------

    # float型(C言語)のバイト数を求める。…他にいい方法があるのでは？
    nf = [0.0].pack("f*").size
    stride = 6 * nf

    glUseProgram(@shader)

    glEnableClientState(GL_VERTEX_ARRAY)         # 頂点配列を有効化
    glEnableClientState(GL_NORMAL_ARRAY)         # 法線配列を有効化

    # 使用バッファを指定
    unless $glbind
      glBindBuffer(GL_ARRAY_BUFFER, @buffers[0])
    else
      glBindBuffer(GL_ARRAY_BUFFER, @buffers.unpack('L')[0])
    end

    # 頂点配列を指定
    glVertexPointer(3,         # 1頂点に値をいくつ使うか。x,y,zなら3
                    GL_FLOAT,  # 値の型
                    stride,    # stride. データの間隔
                    0          # バッファオフセット
                   )

    # 法線配列を指定
    # 法線は必ず x,y,z を渡すのでサイズ指定は不要
    glNormalPointer(GL_FLOAT,  # 値の型
                    stride,    # stride. データの間隔
                    3 * nf     # バッファオフセット
                   )

    # 描画
    glDrawArrays(GL_QUADS,  # プリミティブ種類
                 0,         # 開始インデックス
                 4          # 頂点数
                )

    glDisableClientState(GL_VERTEX_ARRAY)         # 頂点配列を無効化
    glDisableClientState(GL_NORMAL_ARRAY)         # 法線配列を無効化
    glDisableClientState(GL_TEXTURE_COORD_ARRAY)  # 法線配列を無効化
  end
end

# Gosu main window class
class MyWindow < Gosu::Window

  def initialize
    super WIDTH, HEIGHT
    self.caption = "Ruby + Gosu + OpenGL, programmable shader + VBO"
    @gl_obj = GlObj.new(0.0, 0.0, -2.5)
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
