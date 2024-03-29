#! /usr/bin/env ruby
# -*- mode: ruby; coding: utf-8 -*-
# Last updated: <2023/10/15 09:58:42 +0900>
#
# Gosu test. Check keyboard and gamepad.
#
# Gusuはキーボード入力に加えてゲームパッド入力にも対応しているが、
# ゲームパッド入力に関しては注意点がある。
#
# Windows環境では、利用できるUSBゲームパッド種類に制約がある。
# DirectInputタイプ(旧規格・安価)には非対応で、
# XInputタイプ(新規格・高価)にのみ対応してるように見えた。
# また、左右のアナログスティック・十字ボタンのどれを押しても
# 8方向のデジタル入力として扱われる模様。
#
# 動作確認環境:
# Windows10 x64 + Ruby 2.2.6 p396 mingw32 + Gosu 0.10.8 x86-mingw32
#
# USB接続ゲームパッドの動作確認状況:
# ELECOM JC-U3613M (XInput) : OK (ドライバのインストールが必要)
# ELECOM JC-U3613M (DirectInput) : NG
# ELECOM JC-U2410TWH (DirectInput) : NG
# BUFFALO BSGP801GY (DirectInput) : NG

require 'gosu'

class MyWindow < Gosu::Window

  def initialize
    super 640, 480, false
    self.caption = "Input Test"

    @img = Gosu::Image.new("res/tmp_ufo.png", :tileable => true, :retro => true)
    @x = 320
    @y = 240
    @scale = 1.0
  end

  def update
    spd = 6

    # push LEFT ?
    if button_down?(Gosu::KB_LEFT) or button_down?(Gosu::GP_LEFT)
      @x -= spd
    end

    # push RIGHT ?
    if button_down?(Gosu::KB_RIGHT) or button_down?(Gosu::GP_RIGHT)
      @x += spd
    end

    # push UP ?
    if button_down?(Gosu::KB_UP) or button_down?(Gosu::GP_UP)
      @y -= spd
    end

    # push DOWN ?
    if button_down?(Gosu::KB_DOWN) or button_down?(Gosu::GP_DOWN)
      @y += spd
    end

    # push Z or buttn1 ?
    if button_down?(Gosu::KB_Z) or button_down?(Gosu::GP_BUTTON_0)
      @scale += (8.0 - @scale) * 0.2
    else
      @scale += (1.0 - @scale) * 0.4
    end
  end

  def draw
    x = @x - (@img.width / 2) * @scale
    y = @y - (@img.height / 2) * @scale
    @img.draw(x, y, 0, @scale, @scale)
  end

  # check keyboard
  def button_down(id)
    # ESC : close window and exit
    close if id == Gosu::KB_ESCAPE
  end
end

window = MyWindow.new
window.show
