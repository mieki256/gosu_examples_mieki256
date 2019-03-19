#! /usr/bin/env ruby
# -*- mode: ruby; coding: utf-8 -*-
# Last updated: <2019/03/19 22:54:19 +0900>
#
# gosu + opengl の動作確認
# gosu-examplesの opengl_integration.rb を弄って OpenGL絡みの部分だけを列挙
# wavefront(.obj)を読み込んで描画
# Draw a model of wavefront (.obj) format using gosu + opengl
#
# == Require
#
# gem install gosu opengl
# or
# gem install gosu opengl-bindings
#
# == References
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

require_relative 'wavefrontobj'

WIDTH, HEIGHT = 640, 480

# モデルデータ
MODELS = [
  "wavefront/airplane.obj",
  "wavefront/airplane_metaseq.obj",
  "wavefront/suzanne.obj",
  "wavefront/robo_01.obj",
  "wavefront/robo_02.obj",
]

# ライト設定
LIGHT_POS = [5.0, 5.0, 5.0, 0.0]  # 位置
LIGHT_AMB = [0.2, 0.2, 0.2, 1.0]  # 環境光
LIGHT_DIF = [0.8, 0.8, 0.8, 1.0]  # 拡散光
LIGHT_SPE = [1.0, 1.0, 1.0, 1.0]  # 鏡面光

TRANS_POS = { :x => 0.0, :y => 0.0, :z => -2.5 }

class GLWaveFrontObj

  # 初期化
  def initialize(objpath)
    # wavefront(.obj) を読み込み
    @objs = WaveFrontObj.new(objpath)

    # テクスチャ読み込み
    objdir = @objs.objdir
    @texs = {}
    @objs.texs.each do |texname|
      fn = File.join(objdir, texname)
      img = Gosu::Image.new(fn, :tileable => true)

      # OpenGL用のテクスチャ情報を取得
      info = img.gl_tex_info
      unless info
        # 巨大テクスチャを与えるとgosu側が gl_tex_info を取得できない時がある
        puts "Error : #{texname} is not load. Can't get gl_tex_info"
      else
        @texs[texname] = { :info => info, :image =>img }
      end
    end

    @y_rot = 0
    @x_rot = 20
  end

  # 更新処理
  def update
    @y_rot = (@y_rot + 1.0) % 360.0
    # @x_rot = (@x_rot + 0.75) % 360.0
  end

  # 描画処理
  def draw(z)
    # Gosu.gl(z値)でOpenGLの描画を行う
    # 描画後、Gosuの描画ができるようにしてくれるらしい
    Gosu.gl(z) { exec_gl }
  end

  # OpenGL関係の処理
  def exec_gl
    glClearColor(0.0, 0.0, 0.0, 1.0)  # 画面クリア色を指定 (r,g,b,a)
    glClearDepth(1.0)  # デプスバッファをクリア
    glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT)  # 画面クリア

    # テクスチャ情報を取得
    info = nil
    @texs.each do |texname, value|
      return unless value[:info]
    end

    # 奥行き比較関数の種類を指定。デフォルトではGL_LESSが指定されてるらしい
    # glDepthFunc(GL_GEQUAL)
    glDepthFunc(GL_LESS)

    glEnable(GL_DEPTH_TEST)  # デプスバッファを使う
    glEnable(GL_BLEND)       # アルファブレンドを有効化

    # glEnable(GL_POLYGON_SMOOTH)  # ポリゴン描画のアンチエイリアスを有効化
    # glHint(GL_POLYGON_SMOOTH_HINT, GL_NICEST)

    glEnable(GL_LIGHTING)  # ライティングを有効化
    glEnable(GL_LIGHT0)    # GL_LIGHT0 を有効化

    # ライト設定. GL_LIGHT0 に対して設定
    unless $glbind
      # opengl
      glLight(GL_LIGHT0, GL_POSITION, LIGHT_POS)  # 光源の位置
      glLight(GL_LIGHT0, GL_AMBIENT, LIGHT_AMB)   # 環境光
      glLight(GL_LIGHT0, GL_DIFFUSE, LIGHT_DIF)   # 拡散光
      glLight(GL_LIGHT0, GL_SPECULAR, LIGHT_SPE)  # 鏡面光
    else
      # opengl-bindings
      glLightfv(GL_LIGHT0, GL_POSITION, LIGHT_POS.pack("f*"))
      glLightfv(GL_LIGHT0, GL_AMBIENT, LIGHT_AMB.pack("f*"))
      glLightfv(GL_LIGHT0, GL_DIFFUSE, LIGHT_DIF.pack("f*"))
      glLightfv(GL_LIGHT0, GL_SPECULAR, LIGHT_SPE.pack("f*"))
    end

    glMatrixMode(GL_PROJECTION)  # 透視投影の設定
    glLoadIdentity
    glFrustum(-0.10, 0.10, -0.075, 0.075, 0.1, 100)

    glMatrixMode(GL_MODELVIEW)  # モデルビュー変換の指定
    glLoadIdentity

    unless $glbind
      glTranslate(TRANS_POS[:x], TRANS_POS[:y], TRANS_POS[:z])  # 位置をずらす
      glRotate(@y_rot, 0.0, 1.0, 0.0)  # y 回転
      glRotate(@x_rot, 1.0, 0.0, 0.0) # x 回転
    else
      glTranslatef(TRANS_POS[:x], TRANS_POS[:y], TRANS_POS[:z])
      glRotatef(@y_rot, 0.0, 1.0, 0.0)
      glRotatef(@x_rot, 1.0, 0.0, 0.0)
    end

    vertexs = @objs.vertexs  # 頂点群
    normals = @objs.normals  # 法線群
    uvs = @objs.uvs          # UV値群
    mtls = @objs.mtls        # マテリアル情報

    @objs.faces.each do |matname, face|
      m = mtls[matname]
      tex_use = false

      if m.key?(:diffuse_tex)
        # マテリアルにテクスチャが使われてる

        texname = m[:diffuse_tex]
        glEnable(GL_TEXTURE_2D)  # テクスチャマッピングを有効化
        info = @texs[texname][:info]
        id = info.tex_name
        glBindTexture(GL_TEXTURE_2D, id) # テクスチャ割り当て

        # テクスチャの補間を指定
        glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR)
        glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR)
        tex_use = true
      end

      # マテリアル(材質)を指定
      # fk = GL_FRONT
      fk = GL_FRONT_AND_BACK
      unless $glbind
        # opengl
        glMaterial(fk, GL_AMBIENT, m[:ambient]) if m.key?(:ambient)  # 環境光
        glMaterial(fk, GL_DIFFUSE, m[:diffuse]) if m.key?(:diffuse)  # 拡散光
        glMaterial(fk, GL_EMISSION, m[:emission]) if m.key?(:emission)  # 放射輝度
        glMaterial(fk, GL_SPECULAR, m[:specular]) if m.key?(:specular)  # 鏡面光
        if m.key?(:shininess)
          # 鏡面光指数を 0-1000 の範囲から 0-128 の範囲に変換
          v = m[:shininess] * 128.0 / 1000.0
          glMaterial(fk, GL_SHININESS, v)
        end
      else
        # opengl-bindings
        glMaterialfv(fk, GL_AMBIENT, m[:ambient].pack("f*")) if m.key?(:ambient)
        glMaterialfv(fk, GL_DIFFUSE, m[:diffuse].pack("f*")) if m.key?(:diffuse)
        glMaterialfv(fk, GL_EMISSION, m[:emission].pack("f*")) if m.key?(:emission)
        glMaterialfv(fk, GL_SPECULAR, m[:specular].pack("f*")) if m.key?(:specular)
        if m.key?(:shininess)
          v = m[:shininess] * 128.0 / 1000.0
          glMaterialf(fk, GL_SHININESS, v)
        end

      end

      # 面を一枚ずつ指定。本来はVBOとやらを使うのではなかろうか…
      face.each do |f|
        smooth = f[:smooth]  # スムーズ (true or false)
        vs = f[:vertexs]     # 頂点インデックス列

        case vs.size
        when 3
          # 三角形
          glBegin(GL_TRIANGLES)
        when 4
          # 四角形
          glBegin(GL_QUADS)
        else
          # ソレ以外
          glBegin(GL_TRIANGLE_STRIP)
        end

        # 頂点群を指定
        vs.each do |vi, vti, vni|
          if vni
            # 法線指定
            x, y, z, _ = normals[vni]
            glNormal3d(x, y, z)
          end

          if vti
            # texture u, v 指定
            u, v, _ = uvs[vti]
            # blenderでエクスポートした .obj と OpenGL は u,v の vが逆
            v = 1.0 - v
            glTexCoord2d(u, v)
          end

          # 頂点指定
          x, y, z, _ = vertexs[vi]
          glVertex3d(x, y, z)
        end

        glEnd
      end

      if tex_use
        glDisable(GL_TEXTURE_2D)  # テクスチャマッピングを無効化
      end
    end
  end
end

# Gosu main window class
class MyWindow < Gosu::Window

  def initialize
    super WIDTH, HEIGHT
    self.caption = "Ruby + Gosu + OpenGL + wavefront(.obj)"

    @kind = 0
    @gl_objs = []
    MODELS.each do |fn|
      gl_obj = GLWaveFrontObj.new(fn)
      @gl_objs.push(gl_obj)
    end

    @font = Gosu::Font.new(20)
  end

  def update
    @gl_objs[@kind].update
  end

  def draw
    z = 0
    @gl_objs[@kind].draw(z)

    z = 1
    @font.draw_text("Left/Right : Change model", 4, 4, z)
    s = MODELS[@kind]
    @font.draw_text(s, 4, 4 + 24, z)
  end

  def button_down(id)
    # ESC : close window and exit.
    close if id == Gosu::KbEscape
  end

  def button_up(id)
    # Modle change : LEFT, RIGHT
    case id
    when Gosu::KbRight
      @kind = (@kind + 1) % @gl_objs.size
    when Gosu::KbLeft
      @kind = (@kind - 1 + @gl_objs.size) % @gl_objs.size
    end
  end
end

MyWindow.new.show
