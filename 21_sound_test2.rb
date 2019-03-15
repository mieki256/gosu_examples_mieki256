#! /usr/bin/env ruby
# -*- mode: ruby; coding: utf-8 -*-
# Last updated: <2019/03/14 22:03:48 +0900>
#
# Gosu test. play wav or ogg.
# Try changing the volume and playback speed.
#
# Aキー : play. normal volume.
# Bキー : play. small volume.
# Cキー : play. slow.
# Dキー : play. fast.
# Eキー : play. loop.
# Pキー : pause, resume.
# Vキー : volume is 0.
# Zキー : stop.
#
# - Windows10 x64 + Ruby 2.4.5 p335 mingw32 + gosu 0.14.5
# - Ubuntu 18.04 LTS + Ruby 2.5.1 p57 x64 + gosu 0.14.5

require 'gosu'

class MyWindow < Gosu::Window

  def initialize
    super 320, 240, false
    self.caption = 'Sound Play Test'
    @fnt = Gosu::Font.new(20)

    # load wav.
    @sound = Gosu::Sample.new("res/tmp_voice.wav")

    @si = nil  # SampleInstance
    @play_msg = ""
    @pause_msg = ""
  end

  def update
    if @si
      if @si.playing?
        @play_msg = "Playing"
      else
        @play_msg = "Stopped"
      end
      if @si.paused?
        @pause_msg = "Paused"
      else
        @pause_msg = "Not Paused"
      end
    else  # not play
      @play_msg = "Not Play Start"
      @pause_msg = "Not Play Start"
    end
  end

  def draw
    @fnt.draw_text("Push A,B,C,D,E,P,V and Z", 4, 4, 0)
    @fnt.draw_text(@play_msg, 4, 30, 0)
    @fnt.draw_text(@pause_msg, 4, 50, 0)
  end

  def button_down(id)
    close if id == Gosu::KbEscape
  end

  def button_up(id)
    @si = @sound.play if id == Gosu::KbA  # normal play
    @si = @sound.play(0.2, 1, false) if id == Gosu::KbB  # small volume
    @si = @sound.play(1, 0.5, false) if id == Gosu::KbC  # slow
    @si = @sound.play(1, 2.0, false) if id == Gosu::KbD  # fast
    @si = @sound.play(1, 1, true) if id == Gosu::KbE  # loop

    if @si
      if id == Gosu::KbZ
        if @si.playing?
          @si.stop
        end
      elsif id == Gosu::KbP
        if @si.paused?
          @si.resume
        elsif @si.playing?
          @si.pause
        end
      elsif id == Gosu::KbV
        if @si.playing?
          @si.volume = 0
        end
      end
    end
  end
end

window = MyWindow.new
window.show
