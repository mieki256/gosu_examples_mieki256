#! /usr/bin/env ruby
# -*- mode: ruby; coding: utf-8 -*-
# Last updated: <2019/03/15 02:53:39 +0900>
#
# Ruby + gosu + opengl の動作確認
# gosu-examples の opengl_integration.rb を弄ってOpenGL絡みの部分だけを列挙
#
# OpenGL 1.5風、VBOを使って書いてみるテスト
#
# 算譜記録帳: OpenGLでの頂点データの扱いの変化
# http://mklearning.blogspot.com/2014/08/opengl.html
#
# gosu-examples
# https://github.com/gosu/gosu-examples
# https://github.com/gosu/gosu-examples/blob/master/examples/opengl_integration.rb

require 'gosu'
require 'gl'

DATA_KIND = 1   # 0 : 三角形を描画 , 1 : cubeを描画

TEX_FILE = "res/UVCheckerMap01-1024.png"
WIDTH, HEIGHT = 640, 480

LIGHT_POS = [1.0, 2.0, 4.0]            # 位置
LIGHT_AMBIENT = [0.5, 0.5, 0.5, 1.0]   # 環境光
LIGHT_DIFFUSE = [1.0, 1.0, 1.0, 1.0]   # 拡散光
LIGHT_SPECULAR = [1.0, 1.0, 1.0, 1.0]  # 鏡面光

class GlObj

  # 初期化
  def initialize(posx, posy, posz)
    @trans_pos = { :x => posx, :y => posy, :z => posz }
    @rot_y = 0
    @rot_x = 35

    # テクスチャ画像読み込み
    @img = Gosu::Image.new(TEX_FILE, :tileable => true)

    # OpenGL用のテクスチャ情報を取得
    @texinfo = @img.gl_tex_info
    unless @texinfo
      # 巨大テクスチャを与えるとgosu側が gl_tex_info を取得できない時がある
      puts "Error : #{TEX_FILE} is not load. Can't get gl_tex_info"
    end

    # モデルデータを用意
    case DATA_KIND
    when 0
      init_triangle   # 三角形
    when 1
      init_cube       # cube
    end
  end

  # 三角形のデータで初期化
  def init_triangle
    # 三角形用の頂点群
    @vtx_a = [
      -1.0, -1.0, 0.0,
      1.0, -1.0, 0.0,
      0.0, 1.0, 0.0,
    ]

    # 三角形用の法線群
    @nml_a = [
      0.0, 0.0, 1.0,
      0.0, 0.0, 1.0,
      0.0, 0.0, 1.0,
    ]

    # VBO作成
    @buffers = glGenBuffers(2)  # 頂点用と法線用の2つのバッファを生成

    # 頂点群
    glBindBuffer(GL_ARRAY_BUFFER, @buffers[0])  # バッファの種類を設定
    vtx = @vtx_a.pack("f*")  # データはpackして渡すらしい
    glBufferData(
                 GL_ARRAY_BUFFER,
                 vtx.size,          # データ群の長さ
                 vtx,               # データ群。packして渡すらしい
                 GL_STATIC_DRAW
                 )

    # 法線群
    glBindBuffer(GL_ARRAY_BUFFER, @buffers[1])
    nml = @nml_a.pack("f*")
    glBufferData(
                 GL_ARRAY_BUFFER,
                 nml.size,          # データ群の長さ
                 nml,               # データ群
                 GL_STATIC_DRAW
                 )
  end

  # cubeデータで初期化
  def init_cube
    # cube用の頂点群
    @vtx_b = [
      -0.75, -0.75, 0.75,  # 0
      -0.75, 0.75, 0.75,  # 1
      -0.75, 0.75, -0.75,  # 2
      -0.75, -0.75, -0.75,  # 3
      -0.75, -0.75, -0.75,  # 4
      -0.75, 0.75, -0.75,  # 5
      0.75, 0.75, -0.75,  # 6
      0.75, -0.75, -0.75,  # 7
      0.75, -0.75, -0.75,  # 8
      0.75, 0.75, -0.75,  # 9
      0.75, 0.75, 0.75,  # 10
      0.75, -0.75, 0.75,  # 11
      0.75, -0.75, 0.75,  # 12
      0.75, 0.75, 0.75,  # 13
      -0.75, 0.75, 0.75,  # 14
      -0.75, -0.75, 0.75,  # 15
      -0.75, -0.75, -0.75,  # 16
      0.75, -0.75, -0.75,  # 17
      0.75, -0.75, 0.75,  # 18
      -0.75, -0.75, 0.75,  # 19
      0.75, 0.75, -0.75,  # 20
      -0.75, 0.75, -0.75,  # 21
      -0.75, 0.75, 0.75,  # 22
      0.75, 0.75, 0.75,  # 23
    ]

    # cube用のuv群
    @uvs_b = [
      1.0, 0.25,  # 0
      1.0, 0.0,  # 1
      0.75, 0.0,  # 2
      0.75, 0.25,  # 3
      0.75, 0.25,  # 4
      0.75, 0.0,  # 5
      0.5, 0.0,  # 6
      0.5, 0.25,  # 7
      0.5, 0.25,  # 8
      0.5, 0.0,  # 9
      0.25, 0.0,  # 10
      0.25, 0.25,  # 11
      0.25, 0.25,  # 12
      0.25, 0.0,  # 13
      0.0, 0.0,  # 14
      0.0, 0.25,  # 15
      0.5, 0.75,  # 16
      0.75, 0.75,  # 17
      0.75, 0.5,  # 18
      0.5, 0.5,  # 19
      0.25, 0.5,  # 20
      0.0, 0.5,  # 21
      0.0, 0.75,  # 22
      0.25, 0.75,  # 23
    ]

    # cube用の法線群
    @nml_b = [
      -1.0, 0.0, 0.0,  # 0
      -1.0, 0.0, 0.0,  # 1
      -1.0, 0.0, 0.0,  # 2
      -1.0, 0.0, 0.0,  # 3
      0.0, 0.0, -1.0,  # 4
      0.0, 0.0, -1.0,  # 5
      0.0, 0.0, -1.0,  # 6
      0.0, 0.0, -1.0,  # 7
      1.0, 0.0, 0.0,  # 8
      1.0, 0.0, 0.0,  # 9
      1.0, 0.0, 0.0,  # 10
      1.0, 0.0, 0.0,  # 11
      0.0, 0.0, 1.0,  # 12
      0.0, 0.0, 1.0,  # 13
      0.0, 0.0, 1.0,  # 14
      0.0, 0.0, 1.0,  # 15
      0.0, -1.0, 0.0,  # 16
      0.0, -1.0, 0.0,  # 17
      0.0, -1.0, 0.0,  # 18
      0.0, -1.0, 0.0,  # 19
      0.0, 1.0, 0.0,  # 20
      0.0, 1.0, 0.0,  # 21
      0.0, 1.0, 0.0,  # 22
      0.0, 1.0, 0.0,  # 23
    ]

    # cube用のインデックス群
    @face_b = [
      0, 1, 2, 3,
      4, 5, 6, 7,
      8, 9, 10, 11,
      12, 13, 14, 15,
      16, 17, 18, 19,
      20, 21, 22, 23,
    ]

    # VBOを作成

    # 頂点、法線、uv、インデックス用に、4つのバッファを生成
    @buffers = glGenBuffers(4)

    # 頂点群
    glBindBuffer(GL_ARRAY_BUFFER, @buffers[0])  # バッファの種類を設定
    vtx = @vtx_b.pack("f*")
    glBufferData(GL_ARRAY_BUFFER, vtx.size, vtx, GL_STATIC_DRAW)

    # 法線群
    glBindBuffer(GL_ARRAY_BUFFER, @buffers[1])
    nml = @nml_b.pack("f*")
    glBufferData(GL_ARRAY_BUFFER, nml.size, nml, GL_STATIC_DRAW)

    # uv群
    glBindBuffer(GL_ARRAY_BUFFER, @buffers[2])
    uv = @uvs_b.pack("f*")
    glBufferData(GL_ARRAY_BUFFER, uv.size, uv, GL_STATIC_DRAW)

    # インデックス群。他と違って GL_ELEMENT_ARRAY_BUFFER を指定してることに注意
    glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, @buffers[3])
    face = @face_b.pack("S*")
    glBufferData(GL_ELEMENT_ARRAY_BUFFER, face.size, face, GL_STATIC_DRAW)
  end

  def dispose_buffers
    # 使い終わったらバッファを削除…ってこういう書き方でいいの？
    glDeleteBuffers(@buffers)
  end

  # 更新処理
  def update
    @rot_y = (@rot_y + 1.0) % 360.0
    # @rot_x = (@rot_x + 2.0) % 360.0
  end

  # 描画処理
  def draw(z)
    # Gosu.gl(z値)でOpenGLの描画を行う
    # 描画後、Gosuの描画ができるようにしてくれるらしい
    Gosu.gl(z) { exec_gl }
  end

  private

  include Gl

  # OpenGL関係の処理
  def exec_gl
    glClearColor(0.0, 0.0, 0.0, 1.0)  # 画面クリア色を指定 (r,g,b,a)
    glClearDepth(1.0)  # デプスバッファをクリア
    glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT)  # 画面クリア

    # 奥行き比較関数の種類を指定。デフォルトではGL_LESSが指定されてるらしい
    # glDepthFunc(GL_GEQUAL)
    glDepthFunc(GL_LESS)

    glEnable(GL_DEPTH_TEST)  # デプスバッファを使う
    glEnable(GL_BLEND)       # アルファブレンドを有効化

    # glEnable(GL_POLYGON_SMOOTH)  # ポリゴン描画のアンチエイリアスを有効化
    # glHint(GL_POLYGON_SMOOTH_HINT, GL_NICEST)

    # ライト設定. GL_LIGHT0 に対して設定
    glLight(GL_LIGHT0, GL_POSITION, LIGHT_POS)
    glLight(GL_LIGHT0, GL_AMBIENT, LIGHT_AMBIENT)
    glLight(GL_LIGHT0, GL_DIFFUSE, LIGHT_DIFFUSE)
    glLight(GL_LIGHT0, GL_SPECULAR, LIGHT_SPECULAR)

    glEnable(GL_LIGHTING)    # ライティングを有効化
    glEnable(GL_LIGHT0)    # GL_LIGHT0 を有効化

    glMatrixMode(GL_PROJECTION)  # 透視投影の設定
    glLoadIdentity
    glFrustum(-0.10, 0.10, -0.075, 0.075, 0.1, 100)

    glMatrixMode(GL_MODELVIEW)  # モデルビュー変換の指定
    glLoadIdentity

    # 位置をずらす
    glTranslate(@trans_pos[:x], @trans_pos[:y], @trans_pos[:z])

    glRotate(@rot_x, 1.0, 0.0, 0.0) # 回転
    glRotate(@rot_y, 0.0, 1.0, 0.0) # 回転

    case DATA_KIND
    when 0
      # VBO(Vertex Buffer Object)を作って三角形を描画する例
      draw_triangle
    when 1
      # VBOを使ってcubeを描画する例
      draw_cube
    end
  end

  # VBOを使って三角形を描画
  def draw_triangle
    # バッファのデータと関連付け
    glEnableClientState(GL_VERTEX_ARRAY)  # 頂点配列を有効化
    glEnableClientState(GL_NORMAL_ARRAY)  # 法線配列を有効化

    # 頂点配列を関連付け
    glBindBuffer(GL_ARRAY_BUFFER, @buffers[0])
    glVertexPointer(
                    3,  # size. 1頂点に値をいくつ使うか。x,yなら2 x,y,zなら3
                    GL_FLOAT,    # 値の型
                    0,           # stride. データの間隔。詰まってるなら0
                    0            # バッファオフセット
                    )

    # 法線配列を関連付け
    glBindBuffer(GL_ARRAY_BUFFER, @buffers[1])
    glNormalPointer(
                    # size. 法線は必ずx,y,zを渡すので指定しなくていい
                    GL_FLOAT,    # 値の型
                    0,           # stride. データの間隔。詰まってるなら0
                    0            # バッファオフセット
                    )

    # 描画
    glDrawArrays(
                 GL_TRIANGLE_STRIP,  # プリミティブの種類
                 0,                  # スタート地点
                 3                   # 頂点数
                 )

    # バッファを削除
    # glDeleteBuffers(@buffers)
  end

  # VBOを使ってcubeを描画
  def draw_cube
    # バッファのデータと関連付け
    glEnableClientState(GL_VERTEX_ARRAY)         # 頂点配列を有効化
    glEnableClientState(GL_NORMAL_ARRAY)         # 法線配列を有効化
    glEnableClientState(GL_TEXTURE_COORD_ARRAY)  # uv配列を有効化

    # 頂点配列を関連付け
    glBindBuffer(GL_ARRAY_BUFFER, @buffers[0])
    glVertexPointer(3, GL_FLOAT, 0, 0)

    # 法線配列を関連付け
    glBindBuffer(GL_ARRAY_BUFFER, @buffers[1])
    glNormalPointer(GL_FLOAT, 0, 0)

    # uv配列を関連付け
    glBindBuffer(GL_ARRAY_BUFFER, @buffers[2])
    glTexCoordPointer(2, GL_FLOAT, 0, 0)

    # インデックス配列を関連付け
    glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, @buffers[3])

    glEnable(GL_TEXTURE_2D)                          # テクスチャ有効化
    glBindTexture(GL_TEXTURE_2D, @texinfo.tex_name)  # テクスチャ割り当て

    # 描画
    glDrawElements(
                   GL_QUADS,              # プリミティブ種類
                   @face_b.size,          # インデックスの個数
                   GL_UNSIGNED_SHORT,     # インデックスの型
                   0                      # バッファオフセット
                   )

    glDisable(GL_TEXTURE_2D)  # テクスチャ無効化

    # 頂点配列、法線配列、uv配列を無効化
    glDisableClientState(GL_VERTEX_ARRAY)
    glDisableClientState(GL_NORMAL_ARRAY)
    glDisableClientState(GL_TEXTURE_COORD_ARRAY)

    # バッファを削除
    # glDeleteBuffers(@buffers)
  end
end

# メインクラス
class MyWindow < Gosu::Window

  # 初期化
  def initialize
    super WIDTH, HEIGHT
    self.caption = "Ruby + Gosu + OpenGL, VBO"
    @gl_obj = GlObj.new(0.0, 0.0, -2.0)
  end

  # 更新
  def update
    @gl_obj.update
  end

  # 描画
  def draw
    z = 0
    @gl_obj.draw(z)
  end

  def button_down(id)
    # ESCが押されたら終了
    if id == Gosu::KbEscape
      close
    end
  end
end

MyWindow.new.show
