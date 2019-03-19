#! /usr/bin/env ruby
# -*- mode: ruby; coding: utf-8 -*-
# Last updated: <2019/03/19 01:58:33 +0900>
#
# Ruby + gosu + opengl の動作確認
# gosu-examples の opengl_integration.rb を弄ってOpenGL絡みの部分だけを列挙
#
# OpenGL 2.0風。GLSLでシェーダを書いて描画するテスト
# phongシェーディング + テクスチャマッピング
# tinywavefrontobj.rb を使って .objファイルを読んで描画してみる
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

require_relative './tinywavefrontobj'

TEX_FILE = "wavefront/UVCheckerMap01-1024.png"

# OBJ_FILE = "wavefront/plane2_tri_simple.obj"
# OBJ_FILE = "wavefront/cube_tri_simple.obj"
# OBJ_FILE = "wavefront/cube_tri_tex.obj"
# OBJ_FILE = "wavefront/airplane_02.obj"
OBJ_FILE = "wavefront/suzanne_tri.obj"

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

# ライト設定
LIGHT_POS = [0.0, 0.0, 3.0, 1.0]   # 光源の位置
LIGHT_AMB = [0.1, 0.1, 0.1, 1.0]   # 環境光
LIGHT_DIF = [1.0, 1.0, 1.0, 1.0]   # 拡散光
LIGHT_SPE = [1.0, 1.0, 1.0, 1.0]   # 鏡面光

# opengl-bindings 使用時のために pack しておく
LIGHT_POS_PACK = LIGHT_POS.pack("f*")
LIGHT_AMB_PACK = LIGHT_AMB.pack("f*")
LIGHT_DIF_PACK = LIGHT_DIF.pack("f*")
LIGHT_SPE_PACK = LIGHT_SPE.pack("f*")

# 材質設定
AMBIENT = [0.5, 0.5, 0.5, 1.0]
DIFFUSE = [0.5, 0.5, 0.5, 1.0]
SPECULAR = [0.3, 0.3, 0.3, 1.0]
SHININESS = 100.0

AMBIENT_PACK = AMBIENT.pack("f*")
DIFFUSE_PACK = DIFFUSE.pack("f*")
SPECULAR_PACK = SPECULAR.pack("f*")

# OpenGLで描画するクラス
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

    # gosu側が巨大テクスチャの gl_tex_info を取得できない時があるのでチェック
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
    @obj = TinyWaveFrontObj.new(OBJ_FILE)
    vtx = @obj.get_vertex_array  # 頂点配列を取得
    nml = @obj.get_normal_array  # 法線配列を取得
    uv = @obj.get_uv_array       # uv配列を取得
    face = @obj.get_face_array   # 頂点インデックス配列を取得

    # VBOを用意。バッファを生成。
    unless $glbind
      # opengl
      # 頂点配列、法線配列、uv配列、頂点インデックス配列の4つを確保
      @buffers = glGenBuffers(4)

      # バッファにデータを設定
      data = vtx.pack("f*")  # Rubyの場合、データはpackして渡す
      glBindBuffer(GL_ARRAY_BUFFER, @buffers[0])  # バッファ種類を設定
      glBufferData(GL_ARRAY_BUFFER, data.size, data, GL_STATIC_DRAW)

      if @obj.use_normal
        data = nml.pack("f*")
        glBindBuffer(GL_ARRAY_BUFFER, @buffers[1])
        glBufferData(GL_ARRAY_BUFFER, data.size, data, GL_STATIC_DRAW)
      end

      if @obj.use_uv
        data = uv.pack("f*")
        glBindBuffer(GL_ARRAY_BUFFER, @buffers[2])
        glBufferData(GL_ARRAY_BUFFER, data.size, data, GL_STATIC_DRAW)
      end

      @face_size = face.size
      data = face.pack("S*")
      glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, @buffers[3])
      glBufferData(GL_ELEMENT_ARRAY_BUFFER, data.size, data, GL_STATIC_DRAW)
    else
      # opengl-bindings
      @buffers = ' ' * (4 * 4)
      glGenBuffers(4, @buffers)

      data = vtx.pack("f*")
      glBindBuffer(GL_ARRAY_BUFFER, @buffers.unpack('L4')[0])
      glBufferData(GL_ARRAY_BUFFER, data.size, data, GL_STATIC_DRAW)

      if @obj.use_normal
        data = nml.pack("f*")
        glBindBuffer(GL_ARRAY_BUFFER, @buffers.unpack('L4')[1])
        glBufferData(GL_ARRAY_BUFFER, data.size, data, GL_STATIC_DRAW)
      end

      if @obj.use_uv
        data = uv.pack("f*")
        glBindBuffer(GL_ARRAY_BUFFER, @buffers.unpack('L4')[2])
        glBufferData(GL_ARRAY_BUFFER, data.size, data, GL_STATIC_DRAW)
      end

      @face_size = face.size
      data = face.pack("S*")
      glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, @buffers.unpack('L4')[3])
      glBufferData(GL_ELEMENT_ARRAY_BUFFER, data.size, data, GL_STATIC_DRAW)
    end
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

  # プログラマブルシェーダの初期化
  def init_shader(vert_src_fn, frag_src_fn)

    # 1. シェーダオブジェクト作成
    vs = glCreateShader(GL_VERTEX_SHADER)
    fs = glCreateShader(GL_FRAGMENT_SHADER)

    # 頂点シェーダを設定
    File.open(vert_src_fn, "rb") { |file|
      src = file.read
      unless $glbind
        glShaderSource(vs, src)  # 2. シェーダのソースを渡す
        glCompileShader(vs)      # 3. シェーダをコンパイル

        # 4. 正しくコンパイルできたか確認
        compiled = glGetShaderiv(vs, GL_COMPILE_STATUS)
        abort "Error : Compile error in vertex shader" if compiled == GL_FALSE
      else
        glShaderSource(vs, 1, [src].pack('p'), [src.size].pack('I'))
        glCompileShader(vs)
        compiled = ' ' * 4
        glGetShaderiv(vs, GL_COMPILE_STATUS, compiled)
        abort "Error : Compile error in vertex shader" if compiled == 0
      end
    }

    # フラグメントシェーダを設定
    File.open(frag_src_fn, "rb") { |file|
      src = file.read
      unless $glbind
        glShaderSource(fs, src)    # 2. シェーダのソースを渡す
        glCompileShader(fs)        # 3. シェーダをコンパイル

        # 4. 正しくコンパイルできたか確認
        compiled = glGetShaderiv(fs, GL_COMPILE_STATUS)
        abort "Error : Compile error in fragment shader" if compiled == GL_FALSE
      else
        glShaderSource(fs, 1, [src].pack('p'), [src.size].pack('I'))
        glCompileShader(fs)
        compiled = ' ' * 4
        glGetShaderiv(fs, GL_COMPILE_STATUS, compiled)
        abort "Error : Compile error in fragment shader" if compiled == 0
      end
    }

    shader = glCreateProgram    # 5. プログラムオブジェクト作成
    glAttachShader(shader, vs)  # 6. シェーダオブジェクトを登録
    glAttachShader(shader, fs)
    glLinkProgram(shader)       # 7. シェーダプログラムをリンク

    # 8. 正しくリンクできたか確認
    unless $glbind
      linked = glGetProgramiv(shader, GL_LINK_STATUS)
      abort "Error : Linke error" if linked == GL_FALSE
    else
      linked = ' ' * 4
      glGetProgramiv(shader, GL_LINK_STATUS, linked)
      linked = linked.unpack('L')[0]
      abort "Error : Linke error" if linked == 0
    end

    glUseProgram(shader)  # 9. シェーダプログラムを適用
    glDeleteShader(vs)    # 10. 設定が終わったので後始末
    glDeleteShader(fs)

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
      glRotate(@rot_x, 1.0, 0.0, 0.0)            # x 回転
      glRotate(@rot_y, 0.0, 1.0, 0.0)            # y 回転
    else
      glTranslatef(@pos[:x], @pos[:y], @pos[:z])
      glRotatef(@rot_x, 1.0, 0.0, 0.0)
      glRotatef(@rot_y, 0.0, 1.0, 0.0)
    end

    # 材質を設定
    unless $glbind
      glMaterial(GL_FRONT_AND_BACK, GL_AMBIENT, AMBIENT)
      glMaterial(GL_FRONT_AND_BACK, GL_DIFFUSE, DIFFUSE)
      glMaterial(GL_FRONT_AND_BACK, GL_SPECULAR, SPECULAR)
      glMaterial(GL_FRONT_AND_BACK, GL_SHININESS, SHININESS)
    else
      glMaterialfv(GL_FRONT_AND_BACK, GL_AMBIENT, AMBIENT_PACK)
      glMaterialfv(GL_FRONT_AND_BACK, GL_DIFFUSE, DIFFUSE_PACK)
      glMaterialfv(GL_FRONT_AND_BACK, GL_SPECULAR, SPECULAR_PACK)
      glMaterialf(GL_FRONT_AND_BACK, GL_SHININESS, SHININESS)
    end

    # モデルデータを描画
    # ----------------------------------------

    # float型(C言語)のバイト数を求める。…他にいい方法があるのでは？
    nf = [0.0].pack("f*").size

    # 利用シェーダを指定
    if USE_MY_SHADER
      if @obj.use_uv
        glUseProgram(@shader[1])  # テクスチャ使用シェーダ
      else
        glUseProgram(@shader[0])  # テクスチャ未使用シェーダ
      end
    end

    glEnableClientState(GL_VERTEX_ARRAY)        # 頂点配列を有効化
    glEnableClientState(GL_NORMAL_ARRAY) if @obj.use_normal  # 法線配列を有効化
    glEnableClientState(GL_TEXTURE_COORD_ARRAY) if @obj.use_uv  # uv配列を有効化

    unless $glbind
      # 頂点配列を指定
      glBindBuffer(GL_ARRAY_BUFFER, @buffers[0])  # 使用バッファを指定
      glVertexPointer(3,         # 1頂点に値をいくつ使うか。x,y,zなら3
                      GL_FLOAT,  # 値の型
                      0,         # stride. データの間隔
                      0          # バッファオフセット
                     )

      if @obj.use_normal
        # 法線配列を指定。法線は必ずx,y,zを渡すのでサイズ指定は不要
        glBindBuffer(GL_ARRAY_BUFFER, @buffers[1])
        glNormalPointer(GL_FLOAT,  # 値の型
                        0,         # stride. データの間隔
                        0          # バッファオフセット
                       )
      end

      if @obj.use_uv
        # uv配列を指定
        glBindBuffer(GL_ARRAY_BUFFER, @buffers[2])
        glTexCoordPointer(2,         # 1頂点に値をいくつ使うか。u,vなら2
                          GL_FLOAT,  # 値の型
                          0,         # stride. データの間隔
                          0          # バッファオフセット
                         )
      end

      glEnable(GL_TEXTURE_2D)                          # テクスチャ有効化
      glBindTexture(GL_TEXTURE_2D, @texinfo.tex_name)  # テクスチャ割り当て

      # テクスチャの補間を指定
      glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR)
      glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR)

      # 頂点インデックス配列を指定して描画
      glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, @buffers[3])
      glDrawElements(GL_TRIANGLES,          # プリミティブ種類
                     @face_size,            # 頂点インデックスの個数
                     GL_UNSIGNED_SHORT,     # 頂点インデックスの型
                     0                      # バッファオフセット
                    )

      glDisable(GL_TEXTURE_2D)                      # テクスチャ無効化
    else
      glBindBuffer(GL_ARRAY_BUFFER, @buffers.unpack('L4')[0])
      glVertexPointer(3, GL_FLOAT, 0, 0)

      if @obj.use_normal
        glBindBuffer(GL_ARRAY_BUFFER, @buffers.unpack('L4')[1])
        glNormalPointer(GL_FLOAT, 0, 0)
      end

      if @obj.use_uv
        glBindBuffer(GL_ARRAY_BUFFER, @buffers.unpack('L4')[2])
        glTexCoordPointer(2, GL_FLOAT, 0, 0)
      end

      glEnable(GL_TEXTURE_2D)
      glBindTexture(GL_TEXTURE_2D, @texinfo.tex_name)
      glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR)
      glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR)

      glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, @buffers.unpack('L4')[3])
      glDrawElements(GL_TRIANGLES, @face_size, GL_UNSIGNED_SHORT, 0)

      glDisable(GL_TEXTURE_2D)
    end

    glDisableClientState(GL_VERTEX_ARRAY)                     # 頂点配列を無効化
    glDisableClientState(GL_NORMAL_ARRAY) if @obj.use_normal  # 法線配列を無効化
    glDisableClientState(GL_TEXTURE_COORD_ARRAY) if @obj.use_uv  # uv配列を無効化
  end
end

# Gosu main window class
class MyWindow < Gosu::Window

  def initialize
    super WIDTH, HEIGHT
    self.caption = "Ruby + Gosu + OpenGL, programmable shader (Phong) + VBO"
    @gl_obj = GlObj.new(0.0, 0.0, -3.5)
  end

  def update
    @gl_obj.update
  end

  def draw
    z = 0
    @gl_obj.draw(z)
  end

  def button_down(id)
    close if id == Gosu::KbEscape
  end
end

MyWindow.new.show
