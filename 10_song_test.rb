#!ruby
# -*- mode: ruby; coding: utf-8 -*-
# Last updated: <2019/03/14 21:36:34 +0900>
#
# Gosu test. Play BGM (.ogg)
#
# ちゃんとループしてくれない。ダメじゃん。
# Loop playback is abnormal. 
#
# - Windows10 x64
# - ruby 2.4.5p335 (2018-10-18 revision 65137) [i386-mingw32]
# - gosu 0.14.5 x86-mingw32

require 'gosu'

class MyWindow < Gosu::Window

  def initialize
    super 320, 240, false
    self.caption = 'Song (BGM) Play Test'
    @fnt = Gosu::Font.new(20)

    # load ogg BGM
    @bgm = Gosu::Song.new("res/tmp_loop01.ogg")
    @play_msg = ""
    @pause_msg = ""
  end

  def update
    # plauing ?
    if @bgm.playing?
      @play_msg = "Playing"
    else
      @play_msg = "Stopped"
    end

    # pause ?
    if @bgm.paused?
      @pause_msg = "Paused"
    else
      @pause_msg = "Not Paused"
    end
  end

  def draw
    @fnt.draw_text("Push A:Play, Z:Stop, X:Pause", 4, 4, 0)
    @fnt.draw_text(@play_msg, 4, 30, 0)
    @fnt.draw_text(@pause_msg, 4, 50, 0)
  end

  def button_down(id)
    close if id == Gosu::KbEscape
  end

  # Called when the key is released.
  def button_up(id)
    @bgm.play(true) if id == Gosu::KbA  # play (loop enabled)
    @bgm.stop if id == Gosu::KbZ  # stop
    @bgm.pause if id == Gosu::KbX  # pause
  end
end

window = MyWindow.new
window.show
