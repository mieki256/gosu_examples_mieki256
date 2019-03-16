#! /usr/bin/env ruby
# -*- mode: ruby; coding: utf-8 -*-
# Last updated: <2019/03/17 02:57:07 +0900>
#
# gosu + opengl の動作確認
# gosu-examplesの opengl_integration.rb を弄って、
# OpenGL 絡みの部分だけを列挙
# 横スクロールで地形の上を進むイメージで描画
#
# gosu-examples
# https://github.com/gosu/gosu-examples
# https://github.com/gosu/gosu-examples/blob/master/examples/opengl_integration.rb

require 'gosu'

begin
  # gem install opengl
require 'gl'
  include Gl
  puts "load opengl"
rescue LoadError
  # gem install opengl-bindings
  require 'opengl'
  require 'glu'

  OpenGL.load_lib
  GLU.load_lib

  include OpenGL
  include GLU
  puts "load opengl-bindings"
end


WIDTH, HEIGHT = 640, 480

# OpenGLを使って背景描画するためのクラス
class GLBackground
  # Height map size
  POINTS_X = 16
  POINTS_Y = 16

  # Scrolling speed
  SCROLLS_PER_STEP = 20

  # 初期化
  def initialize
    @image = Gosu::Image.new("res/uv.png", :tileable => true)  # テクスチャ読み込み
    @scrolls = 0
    @height_map = Array.new(POINTS_Y) { Array.new(POINTS_X) { rand } }
  end

  # 更新処理
  def update
    @scrolls += 1
    if @scrolls == SCROLLS_PER_STEP
      @scrolls = 0
      @height_map.shift
      @height_map.push Array.new(POINTS_X) { rand }
    end
  end

  # 描画処理
  def draw(z)
    # Gosu.gl(z値)でOpenGLの描画を行う
    # 描画後、Gosuの描画ができるようにしてくれるらしい
    Gosu.gl(z) { exec_gl }
  end

  # OpenGL関係の処理
  def exec_gl
    glClearColor(0.2, 0.2, 0.2, 1.0)  # 画面クリア色を指定 (r,g,b,a)
    glClearDepth(1.0)  # デプスバッファをクリア
    glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT)  # 画面クリア

    # テクスチャ情報が取得できないなら何もせずに戻る
    info = @image.gl_tex_info
    return unless info

    # 奥行き比較関数の種類を指定。デフォルトではGL_LESSが指定されてるらしい
    # glDepthFunc(GL_GEQUAL)
    glDepthFunc(GL_LESS)

    glEnable(GL_DEPTH_TEST)  # デプスバッファを使う
    # glEnable(GL_BLEND)  # アルファブレンドを有効化

    glMatrixMode(GL_PROJECTION)  # 透視投影の設定
    glLoadIdentity
    # glFrustum(-0.10, 0.10, -0.075, 0.075, 1, 100)
    glFrustum(-0.035, 0.035, -0.075, 0.075, 0.1, 100)

    glMatrixMode(GL_MODELVIEW)  # モデルビュー変換の指定
    glLoadIdentity
    glRotatef(35.0, 1.0, 0.0, 0.0) # 回転させる (ang, x, y, z)
    glTranslatef(0.0, -0.35, -0.8)  # 位置をずらす

    glEnable(GL_TEXTURE_2D)  # テクスチャマッピングを有効化
    glBindTexture(GL_TEXTURE_2D, info.tex_name)

    # スクロールオフセット値を得る
    offs_y = 1.0 * @scrolls / SCROLLS_PER_STEP

    dy = 0.2
    dz = 1.5

    0.upto(POINTS_Y - 2) do |y|
      0.upto(POINTS_X - 2) do |x|
        glBegin(GL_TRIANGLE_STRIP)  # 三角ポリゴンを連続で描画

        px0 = -0.5 + (x - 0.0) / (POINTS_X - 1)
        px1 = -0.5 + (x + 1.0) / (POINTS_X - 1)
        py0 = -0.5 + (y - 0.0 - offs_y) / (POINTS_Y - 2)
        py1 = -0.5 + (y + 1.0 - offs_y) / (POINTS_Y - 2)

        z = @height_map[y][x]
        # glColor4d(1, 1, 1, z)  # 透過度を指定してフォグに近い効果を出してる
        glTexCoord2d(info.left, info.top)  # テクスチャ座標を指定
        # 頂点を指定
        glVertex3d(py0, z * dy, px0 * dz)

        z = @height_map[y + 1][x]
        # glColor4d(1, 1, 1, z)
        glTexCoord2d(info.left, info.bottom)
        glVertex3d(py1, z * dy, px0 * dz)

        z = @height_map[y][x + 1]
        # glColor4d(1, 1, 1, z)
        glTexCoord2d(info.right, info.top)
        glVertex3d(py0, z * dy, px1 * dz)

        z = @height_map[y+1][x + 1]
        # glColor4d(1, 1, 1, z)
        glTexCoord2d(info.right, info.bottom)
        glVertex3d(py1, z * dy, px1 * dz)

        glEnd
      end
    end
  end
end

class MyWindow < Gosu::Window

  def initialize
    super WIDTH, HEIGHT
    self.caption = "Ruby + Gosu + OpenGL Test"
    @gl_background = GLBackground.new
  end

  def update
    @gl_background.update
  end

  def draw
    @gl_background.draw(0)
  end
  
  def button_down(id)
    # ESC : close window and exit.
    close if id == Gosu::KbEscape
  end
end

MyWindow.new.show
