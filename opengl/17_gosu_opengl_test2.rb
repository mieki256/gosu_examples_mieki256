#! /usr/bin/env ruby
# -*- mode: ruby; coding: utf-8 -*-
# Last updated: <2019/03/15 02:51:10 +0900>
#
# gosu + opengl の動作確認
# gosu-examplesの opengl_integration.rb を弄って、
# OpenGL 絡みの部分だけを列挙
# 円柱の中を進むイメージで描画
#
# gosu-examples
# https://github.com/gosu/gosu-examples
# https://github.com/gosu/gosu-examples/blob/master/examples/opengl_integration.rb

require 'gosu'
require 'gl'

WIDTH, HEIGHT = 640, 480

# OpenGLを使って背景描画するためのクラス
class GLBackground

  # 初期化
  def initialize
    # テクスチャ読み込み
    @image = Gosu::Image.new("res/mecha.png", :tileable => true)
    @scrolls = 0
    @rot_v = 0
    @rot_v2 = 0
  end

  # 更新処理
  def update
    @scrolls += 1
    @rot_v = (@rot_v + 0.3) % 360.0
    @rot_v2 = (@rot_v2 + 0.5) % 360.0
    if @scrolls == SCROLLS_PER_STEP
      @scrolls = 0
    end
  end

  # 描画処理
  def draw(z)
    # Gosu.gl(z値)でOpenGLの描画を行う
    # 描画後、Gosuの描画ができるようにしてくれるらしい
    Gosu.gl(z) { exec_gl }
  end

  private

  include Gl

  # Scrolling speed
  SCROLLS_PER_STEP = 15

  # OpenGL関係の処理
  def exec_gl
    glClearColor(0.0, 0.0, 0.0, 1.0)  # 画面クリア色を指定 (r,g,b,a)
    glClearDepth(1.0)  # デプスバッファをクリア
    glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT)  # 画面クリア

    # テクスチャ情報が取得できないなら何もせずに戻る
    info = @image.gl_tex_info
    return unless info

    # 奥行き比較関数の種類を指定。デフォルトではGL_LESSが指定されてるらしい
    # glDepthFunc(GL_GEQUAL)
    glDepthFunc(GL_LESS)

    glEnable(GL_DEPTH_TEST)  # デプスバッファを使う
    glEnable(GL_BLEND)  # アルファブレンドを有効化

    glMatrixMode(GL_PROJECTION)  # 透視投影の設定
    glLoadIdentity
    glFrustum(-0.10, 0.10, -0.075, 0.075, 0.1, 100)

    glMatrixMode(GL_MODELVIEW)  # モデルビュー変換の指定
    glLoadIdentity
    glTranslate(0, 0.0, -0.8)  # 位置をずらす

    ry = 25.0 * Math.sin(@rot_v * Math::PI / 180.0)
    glRotate(ry, 0.0, 1.0, 0.0) # 回転
    rz = 20.0 * Math.sin(@rot_v2 * Math::PI / 180.0)
    glRotate(rz, 0.0, 0.0, 1.0) # 回転

    # スクロールオフセット値を得る
    offs_y = 1.0 * @scrolls / SCROLLS_PER_STEP

    glEnable(GL_TEXTURE_2D)  # テクスチャマッピングを有効化
    glBindTexture(GL_TEXTURE_2D, info.tex_name) # テクスチャを割り当て

    # テクスチャの補間を指定
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR)
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR)

    mx = 15.0
    my = 1.2
    mz = 1.2
    ra = @rot_v * 4.0
    lx = 28
    0.upto(lx) do |bx|
      px0 = (-0.5 + (bx - 0.0 - offs_y) / lx) * mx
      px1 = (-0.5 + (bx + 0.6 - offs_y) / lx) * mx

      aa = 15
      0.step(360, aa) do |ang|
        rad0 = (ang + ra) * Math::PI / 180.0
        pz0 = Math.cos(rad0) * mz
        py0 = Math.sin(rad0) * my

        rad1 = (ang + ra + aa) * Math::PI / 180.0
        pz1 = Math.cos(rad1) * mz
        py1 = Math.sin(rad1) * my

        glBegin(GL_TRIANGLE_STRIP)

        glTexCoord2d(info.left, info.top)
        glVertex3d(px0, py0, pz0)

        glTexCoord2d(info.left, info.bottom)
        glVertex3d(px0, py1, pz1)

        glTexCoord2d(info.right, info.top)
        glVertex3d(px1, py0, pz0)

        glTexCoord2d(info.right, info.bottom)
        glVertex3d(px1, py1, pz1)

        glEnd
      end
    end
  end
end

# Main window
class MyWindow < Gosu::Window

  def initialize
    super WIDTH, HEIGHT
    self.caption = "Ruby + Gosu + OpenGL Test"
    @gl_background = GLBackground.new
    @bg_img = Gosu::Image.new("res/bg.png", :tileable => true)
  end

  def update
    @gl_background.update
  end

  def draw
    @gl_background.draw(2)
    @bg_img.draw(0, 0, 0)
  end
  
  def button_down(id)
    # ESC : close window and exit.
    close if id == Gosu::KbEscape
  end
end

MyWindow.new.show
