#! /usr/bin/env ruby
# -*- mode: ruby; coding: utf-8 -*-
# Last updated: <2019/03/15 02:52:38 +0900>
#
# Ruby + gosu + opengl の動作確認
# gosu-examples の opengl_integration.rb を弄ってOpenGL絡みの部分だけを列挙
#
# OpenGL 2.0風。GLSLでシェーダを書いて描画するテスト
# phongシェーディング + テクスチャマッピング
# tinywavefrontobj.rb で出力した json を読んで描画してみる
#
# 床井研究室 - 第１回 シェーダプログラムの読み込み
# http://marina.sys.wakayama-u.ac.jp/~tokoi/?date=20051006
#
# 床井研究室 - 第２回 Gouraud シェーディングと Phong シェーディング
# http://marina.sys.wakayama-u.ac.jp/~tokoi/?date=20051007
#
# 床井研究室 - 第３回 テクスチャの参照
# http://marina.sys.wakayama-u.ac.jp/~tokoi/?date=20051008
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
require 'gl'
require 'json'

TEX_FILE = "wavefront/UVCheckerMap01-1024.png"

# JSON_FILE = "wavefront/cube_tri_simple.json"
JSON_FILE = "wavefront/cube_tri_tex.json"

USE_MY_SHADER = true

# プログラマブルシェーダのソースファイル名
SHADER_SRC_LIST = [
  [
    # 0 : テクスチャ無し
    "shaders/phong_shading.vert",  # 頂点シェーダ
    "shaders/phong_shading.frag",  # フラグメントシェーダ
  ],
  [
    # 1 : テクスチャ有り
    "shaders/phong_shading_with_tex.vert",
    "shaders/phong_shading_with_tex.frag",
  ],
]

WIDTH, HEIGHT = 640, 480

LIGHT_POS = [0.0, 0.0, 3.0, 1.0]   # 光源の位置
LIGHT_AMB = [0.1, 0.1, 0.1, 1.0]   # 環境光
LIGHT_DIF = [1.0, 1.0, 1.0, 1.0]   # 拡散光
LIGHT_SPE = [1.0, 1.0, 1.0, 1.0]   # 鏡面光

class GlObj

  # 初期化
  def initialize(pos_x = 0.0, pos_y = 0.0, pos_z = -3.0)
    @pos = { :x => pos_x, :y => pos_y, :z => pos_z }
    @rot_x = 10.0
    @rot_y = 0.0

    # テクスチャ画像読み込み
    @img = Gosu::Image.new(TEX_FILE, :tileable => true)

    # OpenGL用のテクスチャ情報を取得
    @texinfo = @img.gl_tex_info

    # 巨大テクスチャを与えるとgosu側が gl_tex_info を取得できない時がある
    abort "Error : #{TEX_FILE} is not load. Can't get gl_tex_info" unless @texinfo

    # プラグラマブルシェーダを設定
    # テクスチャ未使用/使用版の2つを設定
    @shader = []
    if USE_MY_SHADER
      SHADER_SRC_LIST.each do |vert_src_fn, frag_src_fn|
        @shader.push(init_shader(vert_src_fn, frag_src_fn))
      end
    end

    # Wavefront(.obj)のモデルデータを読み込み
    File.open(JSON_FILE) { |file|
      hash = JSON.load(file)
      @vtx = hash["vertex"]
      @nml = hash["normal"] if hash.key?("normal")
      @uv = hash["uv"] if hash.key?("uv")
      @face = hash["face"]
    }

    # VBOを用意。バッファを生成。
    # 頂点配列、法線配列、uv配列、頂点インデックス配列の4つを確保
    @buffers = glGenBuffers(4)

    # バッファにデータを設定
    # 頂点配列
    data = @vtx.pack("f*")  # Rubyの場合、データはpackして渡す
    glBindBuffer(GL_ARRAY_BUFFER, @buffers[0])  # バッファ種類を設定
    glBufferData(GL_ARRAY_BUFFER, data.size, data, GL_STATIC_DRAW)

    # 法線配列
    if @nml
      data = @nml.pack("f*")
      glBindBuffer(GL_ARRAY_BUFFER, @buffers[1])
      glBufferData(GL_ARRAY_BUFFER, data.size, data, GL_STATIC_DRAW)
    end

    # uv配列
    if @uv
      data = @uv.pack("f*")
      glBindBuffer(GL_ARRAY_BUFFER, @buffers[2])
      glBufferData(GL_ARRAY_BUFFER, data.size, data, GL_STATIC_DRAW)
    end

    # 頂点インデックス配列
    @face_size = @face.size
    data = @face.pack("S*")
    glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, @buffers[3])
    glBufferData(GL_ELEMENT_ARRAY_BUFFER, data.size, data, GL_STATIC_DRAW)
  end

  # 更新処理
  def update
    @rot_y = (@rot_y + 0.5) % 360.0
  end

  # 描画処理
  def draw(z)
    # Gosu.gl(z値)でOpenGLの描画を行う
    # 描画後にGosu側の描画ができるようにしてくれるらしい
    Gosu.gl(z) { exec_gl }
  end

  private

  include Gl

  # プログラマブルシェーダの初期化
  def init_shader(vert_src_fn, frag_src_fn)

    # 1. シェーダオブジェクト作成
    vert_shader = glCreateShader(GL_VERTEX_SHADER)
    frag_shader = glCreateShader(GL_FRAGMENT_SHADER)

    # 頂点シェーダを設定
    File.open(vert_src_fn, "rb") { |file|
      src = file.read
      glShaderSource(vert_shader, src)    # 2. シェーダのソースを渡す
      glCompileShader(vert_shader)        # 3. シェーダをコンパイル

      # 4. 正しくコンパイルできたか確認
      compiled = glGetShaderiv(vert_shader, GL_COMPILE_STATUS)
      abort "Error : Compile error in vertex shader" if compiled == GL_FALSE
    }

    # フラグメントシェーダを設定
    File.open(frag_src_fn, "rb") { |file|
      src = file.read
      glShaderSource(frag_shader, src)    # 2. シェーダのソースを渡す
      glCompileShader(frag_shader)        # 3. シェーダをコンパイル

      # 4. 正しくコンパイルできたか確認
      compiled = glGetShaderiv(frag_shader, GL_COMPILE_STATUS)
      abort "Error : Compile error in fragment shader" if compiled == GL_FALSE
    }

    shader = glCreateProgram             # 5. プログラムオブジェクト作成
    glAttachShader(shader, vert_shader)  # 6. シェーダオブジェクトを登録
    glAttachShader(shader, frag_shader)
    glLinkProgram(shader)                # 7. シェーダプログラムをリンク

    # 8. 正しくリンクできたか確認
    linked = glGetProgramiv(shader, GL_LINK_STATUS)
    abort "Error : Linke error" if linked == GL_FALSE

    glUseProgram(shader)                 # 9. シェーダプログラムを適用

    glDeleteShader(vert_shader)          # 10. 設定が終わったので後始末
    glDeleteShader(frag_shader)

    return shader
  end

  # OpenGL関係の処理
  def exec_gl
    glClearColor(0.3, 0.3, 1.0, 0.0)    # 画面クリア色を r,g,b,a で指定
    glClearDepth(1.0)                   # デプスバッファをクリア
    glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT)  # 画面クリア
    glDepthFunc(GL_LESS)       # 奥行き比較関数の種類を指定
    glEnable(GL_DEPTH_TEST)    # デプスバッファを使う

    glDisable(GL_CULL_FACE)    # 片面表示を無効化

    glEnable(GL_BLEND)         # アルファブレンドを有効化
    glBlendFunc(GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA)

    glLightfv(GL_LIGHT0, GL_POSITION, LIGHT_POS)  # 光源の位置
    glLightfv(GL_LIGHT0, GL_AMBIENT, LIGHT_AMB)   # 環境光
    glLightfv(GL_LIGHT0, GL_DIFFUSE, LIGHT_DIF)   # 拡散光
    glLightfv(GL_LIGHT0, GL_SPECULAR, LIGHT_SPE)  # 鏡面光
    glEnable(GL_LIGHTING)      # 光源の有効化
    glEnable(GL_LIGHT0)        # 0番目のライトを有効化

    glMatrixMode(GL_PROJECTION)  # 透視投影の設定
    glLoadIdentity               # 変換行列の初期化
    glFrustum(-0.10, 0.10, -0.075, 0.075, 0.1, 100)  # 視野範囲を設定

    glMatrixMode(GL_MODELVIEW)  # モデルビュー変換の指定
    glLoadIdentity              # 変換行列の初期化
    glTranslate(@pos[:x], @pos[:y], @pos[:z])  # 平行移動
    glRotate(@rot_x, 1.0, 0.0, 0.0)            # 回転
    glRotate(@rot_y, 0.0, 1.0, 0.0)            # 回転

    # 材質を設定
    ambient = [0.5, 0.5, 0.5, 1.0]
    diffuse = [0.5, 0.5, 0.5, 1.0]
    specular = [0.3, 0.3, 0.3, 1.0]
    shininess = 100.0
    glMaterial(GL_FRONT_AND_BACK, GL_AMBIENT, ambient)
    glMaterial(GL_FRONT_AND_BACK, GL_DIFFUSE, diffuse)
    glMaterial(GL_FRONT_AND_BACK, GL_SPECULAR, specular)
    glMaterial(GL_FRONT_AND_BACK, GL_SHININESS, shininess)

    # モデルデータを描画
    # ----------------------------------------

    # 利用シェーダを指定
    if USE_MY_SHADER
      if @uv
        glUseProgram(@shader[1])  # テクスチャ使用シェーダ
      else
        glUseProgram(@shader[0])  # テクスチャ未使用シェーダ
      end
    end

    # float型(C言語)のバイト数を求める。…他にいい方法があるのでは？
    nf = [0.0].pack("f*").size

    glEnableClientState(GL_VERTEX_ARRAY)        # 頂点配列を有効化
    glEnableClientState(GL_NORMAL_ARRAY) if @nml  # 法線配列を有効化
    glEnableClientState(GL_TEXTURE_COORD_ARRAY) if @uv  # uv配列を有効化

    # 頂点配列を指定
    glBindBuffer(GL_ARRAY_BUFFER, @buffers[0])  # 使用バッファを指定
    glVertexPointer(
                    3,         # 1頂点に値をいくつ使うか。x,y,zなら3
                    GL_FLOAT,  # 値の型
                    0,         # stride. データの間隔
                    0          # バッファオフセット
                    )

    if @nml
      # 法線配列を指定。法線は必ずx,y,zを渡すのでサイズ指定は不要
      glBindBuffer(GL_ARRAY_BUFFER, @buffers[1])
      glNormalPointer(
                      GL_FLOAT,  # 値の型
                      0,         # stride. データの間隔
                      0,         # バッファオフセット
                      )
    end

    if @uv
      # uv配列を指定
      glBindBuffer(GL_ARRAY_BUFFER, @buffers[2])
      glTexCoordPointer(
                        2,         # 1頂点に値をいくつ使うか。u,vなら2
                        GL_FLOAT,  # 値の型
                        0,         # stride. データの間隔
                        0,         # バッファオフセット
                        )
    end

    glEnable(GL_TEXTURE_2D)                          # テクスチャ有効化
    glBindTexture(GL_TEXTURE_2D, @texinfo.tex_name)  # テクスチャ割り当て

    # テクスチャの補間を指定
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR)
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR)

    # 頂点インデックス配列を指定して描画
    glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, @buffers[3])
    glDrawElements(
                   GL_TRIANGLES,          # プリミティブ種類
                   @face_size,            # 頂点インデックスの個数
                   GL_UNSIGNED_SHORT,     # 頂点インデックスの型
                   0                      # バッファオフセット
                   )

    glDisable(GL_TEXTURE_2D)                      # テクスチャ無効化

    glDisableClientState(GL_VERTEX_ARRAY)         # 頂点配列を無効化
    glDisableClientState(GL_NORMAL_ARRAY) if @nml  # 法線配列を無効化
    glDisableClientState(GL_TEXTURE_COORD_ARRAY) if @uv  # uv配列を無効化
  end
end

# メインクラス
class MyWindow < Gosu::Window

  # 初期化
  def initialize
    super WIDTH, HEIGHT
    self.caption = "Ruby + Gosu + OpenGL, programmable shader (Phong) + VBO"
    @gl_obj = GlObj.new(0.0, 0.0, -3.5)
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
    close if id == Gosu::KbEscape
  end
end

MyWindow.new.show
