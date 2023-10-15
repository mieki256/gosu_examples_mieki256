#! /usr/bin/env ruby
# -*- mode: ruby; coding: utf-8 -*-
# Last updated: <2023/10/15 09:44:26 +0900>
#
# Gosu test. Open window only.
#
# - Ubuntu 18.04.2 x64 + Ruby 2.5.1 p57 x64 + gosu 0.14.5
# - Windows10 x64 + Ruby 2.4.5 p335 mingw32 + Gosu 0.14.5 mingw32

require 'gosu'

class MyWindow < Gosu::Window
  
  def initialize
    super 640, 480, false
    self.caption = 'Hello World!'
  end
  
  def update
  end
  
  def draw
  end
  
  def button_down(id)
    close if id == Gosu::KB_ESCAPE
  end
end

window = MyWindow.new
window.show
