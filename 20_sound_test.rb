#! /usr/bin/env ruby
# -*- mode: ruby; coding: utf-8 -*-
# Last updated: <2023/10/15 09:47:27 +0900>
#
# Gosu test. play wav or ogg.
#
# - Windows10 x64 + Ruby 2.2.6 p396 mingw32 + gosu 0.10.8
# - Windows10 x64 + Ruby 2.4.5 p335 mingw32 + gosu 0.14.5
# - Ubuntu 18.04 LTS + Ruby 2.5.1 p57 x64 + gosu 0.14.5

require 'gosu'

class MyWindow < Gosu::Window

  def initialize
    super 320, 240, false
    self.caption = 'Sound Play Test'

    # load wav or ogg
    @sounds = []
    [
      "res/tmp_se_01.wav",
      "res/tmp_se_02.wav",
      "res/tmp_se_03.wav",
      "res/tmp_se_01.ogg",
      "res/tmp_se_02.ogg",
      "res/tmp_se_03.ogg"
    ].each do |fn|
      @sounds.push(Gosu::Sample.new(fn))
    end
    @cnt = 0
  end

  def update
    if @cnt % 60 == 0
      # 一定フレーム数が過ぎたらサウンドを再生
      n = (@cnt / 60) % @sounds.length
      @sounds[n].play
    end
    @cnt += 1
  end

  def draw
  end

  def button_down(id)
    # ESC : close window and exit
    close if id == Gosu::KB_ESCAPE
  end
end

window = MyWindow.new
window.show
