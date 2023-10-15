#! /usr/bin/env ruby
# -*- mode: ruby; coding: utf-8 -*-
# Last updated: <2023/10/15 10:07:53 +0900>
#
# Gosu test. Play BGM (.ogg)
#
# ちゃんとループしてくれない。ダメじゃん。
#
# Ubuntu上でスクリプト終了時に警告メッセージが出る状態を
# 回避するように対処してみた。
#
# - Failure : Ubuntu 16.04 LTS + Ruby 2.3.1 p112 + gosu 0.10.8
#
# - Good : Windows10 x64
# - ruby 2.4.5p335 (2018-10-18 revision 65137) [i386-mingw32]
# - gosu 0.14.5 x86-mingw32
#
# - Good : Ubuntu Linux 18.04.2 LTS x64
# - Ruby 2.5.1p57 (2018-03-29 revision 63029) [x86_64-linux-gnu]
# - Gosu 0.14.5

require 'gosu'

class MyWindow < Gosu::Window

  def initialize
    super 320, 240, false
    self.caption = 'Song (BGM) Play Test'
    @fnt = Gosu::Font.new(20)

    @bgm = Gosu::Song.new("res/tmp_loop01.ogg")
    @play_msg = ""
    @pause_msg = ""
  end

  def update
    @play_msg = (@bgm.playing?)? "Playing" : "Stopped"

    @pause_msg = (@bgm.paused?)? "Paused" : "Not Paused"
  end

  def draw
    @fnt.draw_text("Push A:Play, Z:Stop, P:Pause", 4, 4, 0)
    @fnt.draw_text(@play_msg, 4, 30, 0)
    @fnt.draw_text(@pause_msg, 4, 50, 0)
  end

  # Called when a key is pressed.
  def button_down(id)
    if id == Gosu::KB_ESCAPE
      close
    elsif id == Gosu::KB_A
      unless @bgm.playing?
        @bgm.play(true)  # play (loop enabled)
      end
    elsif id == Gosu::KB_Z
      @bgm.stop  # stop
    elsif id == Gosu::KB_P
      if @bgm.paused?
        @bgm.play(true)
      elsif @bgm.playing?
        @bgm.pause  # pause
      end
    end
  end

  # Called when the key is released.
  def button_up(id)
  end

  def stop_bgm
    return unless @bgm
    @bgm.stop
  end

  def dispose_bgm
    @bgm = nil
  end

  def bgm_playing?
    return false unless @bgm
    return @bgm.playing?
  end
end

wdw = MyWindow.new
wdw.show

# Request to stop BGM
wdw.stop_bgm

# Wait for BGM to stop
while wdw.bgm_playing?
  puts "BGM playing"
  sleep(1)
end
puts "BGM not playing"

wdw.dispose_bgm
wdw = nil
GC.start
exit
