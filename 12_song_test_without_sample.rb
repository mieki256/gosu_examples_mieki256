#! /usr/bin/env ruby
# -*- mode: ruby; coding: utf-8 -*-
# Last updated: <2023/10/15 10:08:16 +0900>
#
# Gosu test. Play BGM (.ogg)
# An example using the Sample class without using the Song class.
# Loop boundaries are connected smoothly.
#
# - Windows10 x64 + Ruby 2.2.6 p396 mingw32 + gosu 0.10.8
# - Windows10 x64 + Ruby 2.4.5 p335 mingw32 + gosu 0.14.5
# - Ubuntu 16.04 LTS + Ruby 2.3.1 p112 + gosu 0.10.8
# - Ubuntu 18.04 LTS + Ruby 2.5.1 p57 x64 + gosu 0.14.5

require 'gosu'

class MyWindow < Gosu::Window

  def initialize
    super 320, 240, false
    self.caption = 'Sample (BGM) Play Test'
    @fnt = Gosu::Font.new(20)

    # load ogg BGM
    @bgm = Gosu::Sample.new("res/tmp_loop01.ogg")
    @bgm_si = nil
    @play_msg = ""
    @pause_msg = ""
  end

  def update
    # playing ?
    @play_msg = (@bgm_si and @bgm_si.playing?)? "Playing" : "Stopped"
    
    # pause ?
    @pause_msg = (@bgm_si and @bgm_si.paused?)? "Paused" : "Not Paused"
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
      if @bgm_si == nil or !@bgm_si.playing?
        @bgm_si = @bgm.play(1, 1, true)  # play (loop enabled)
      end
    elsif id == Gosu::KB_Z
      if @bgm_si
        @bgm_si.stop  # stop
      end
    elsif id == Gosu::KB_P
      if @bgm_si
        if @bgm_si.paused?
          @bgm_si.resume # resume
        elsif @bgm_si.playing?
          @bgm_si.pause  # pause
        end
      end
    end
  end

  # Called when the key is released.
  def button_up(id)
  end

  def stop_bgm
    return unless @bgm_si
    @bgm_si.stop
  end

  def dispose_bgm
    @bgm_si = nil
    @bgm = nil
  end

  def bgm_playing?
    return false unless @bgm_si
    return @bgm_si.playing?
  end
end

wdw = MyWindow.new
wdw.show

wdw.stop_bgm

while wdw.bgm_playing?
  puts "BGM playing"
  sleep(1)
end
puts "BGM not playing"

wdw.dispose_bgm
wdw = nil
GC.start
exit
