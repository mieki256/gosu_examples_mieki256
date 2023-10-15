#! /usr/bin/env ruby
# -*- mode: ruby; coding: utf-8 -*-
# Last updated: <2023/10/15 09:45:06 +0900>
#
# Gosu test. Draw image.
#
# - Ubuntu 18.04.2 x64 + Ruby 2.5.1 p57 x64 + gosu 0.14.5
# - Windows10 x64 + Ruby 2.4.5 p335 mingw32 + Gosu 0.14.5 x86-mingw32

require 'gosu'

$fullscr = false

class MyWindow < Gosu::Window
  
  def initialize
    super 640, 480, $fullscr
    self.caption = 'Draw image'
    
    # Font
    @font = Gosu::Font.new(32)
    
    # BG, Sprite image
    @bg_img = Gosu::Image.new("res/tmp_bg.png", :tileable => true)
    @spr_img = Gosu::Image.new("res/tmp_ufo.png", :tileable => true)
  end
  
  def update
  end
  
  def draw
    @bg_img.draw(0, 0, 100)
    @spr_img.draw(320, 240, 200)
    @font.draw_text("Hello World", 10, 10, 300)
  end
  
  def button_down(id)
    close if id == Gosu::KB_ESCAPE
  end
end

window = MyWindow.new
window.show
