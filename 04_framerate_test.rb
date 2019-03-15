#! /usr/bin/env ruby
# -*- mode: ruby; coding: utf-8 -*-
# Last updated: <2019/03/14 23:59:00 +0900>
#
# Gosu test. Get Framerate.
#
# - Ubuntu 18.04.2 x64 + Ruby 2.5.1 p57 x64 + gosu 0.14.5
# - Windows10 x64 + Ruby 2.4.5 p335 mingw32 + Gosu 0.14.5 x86-mingw32

require 'gosu'

# Framerate counter class
class FrameRate
  attr_reader :framerate

  def initialize
    @cnt = 0
    @framerate = 0
    @start_time = Time.now
  end

  def update
    @cnt += 1
    n = Time.now
    nd = n - @start_time
    return if nd < 1.0
    @framerate = @cnt / nd
    @start_time = n
    @cnt = 0
  end
end

# Main window class
class MyWindow < Gosu::Window
  
  def initialize
    super 640, 480, false
    self.caption = 'Framerate counter'
    @font = Gosu::Font.new(20)
    @frate = FrameRate.new
  end

  def update
  end

  def draw
    @frate.update
    f = "%#.05g" % @frate.framerate
    @font.draw_text("FPS #{f}", 10, 10, 0)
  end

  # check keyboard
  def button_down(id)
    # ESC : cloase window and exit.
    close if id == Gosu::KbEscape
  end
end

window = MyWindow.new
window.show
