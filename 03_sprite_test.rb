#! /usr/bin/env ruby
# -*- mode: ruby; coding: utf-8 -*-
# Last updated: <2019/03/14 23:57:24 +0900>
#
# Gosu test. Draw Sprites.
#
# - Ubuntu 18.04.2 x64 + Ruby 2.5.1 p57 x64 + gosu 0.14.5
# - Windows10 x64 + Ruby 2.4.5 p335 mingw32 + Gosu 0.14.5 x86-mingw32

require 'gosu'

$fullscr = false

# Sprite class
class MySpr

  def initialize(x, y, vx, vy, img, scrw, scrh)
    @fpx = x
    @fpy = y
    @fpvx = vx
    @fpvy = vy
    @scrw = scrw
    @scrh = scrh
    @w = img.width
    @h = img.height
    @whf = @w / 2
    @hhf = @h / 2
    @image = img
    @x = (@fpx - @whf).to_i
    @y = (@fpy - @hhf).to_i
  end

  def update
    @fpx += @fpvx
    @fpy += @fpvy
    @x = (@fpx - @whf).to_i
    @y = (@fpy - @hhf).to_i
    @fpvx *= -1 if @x + @w >= @scrw or @x <= 0
    @fpvy *= -1 if @y + @h >= @scrh or @y <= 0
  end

  def draw
    @image.draw(@x, @y, 0)
  end
end

# Main window
class MyWindow < Gosu::Window

  def initialize
    super 640, 480, $fullscr
    self.caption = "Sprite Test"
    scrw = self.width
    scrh = self.height

    # born sprites
    pmax = 512
    img = Gosu::Image.new("res/tmp_ufo.png", :tileable => true)
    x, y = 320, 240
    @sprs = []
    pmax.times do |i|
      rad = (i * 360 / pmax) * Math::PI / 180
      dx = 3.0 * Math::cos(rad)
      dy = 3.0 * Math::sin(rad)
      @sprs.push(MySpr.new(x, y, dx, dy, img, scrw, scrh))
    end

    @frame = 0
  end

  def update
    @sprs.each do |spr|
      spr.update
    end

    @frame += 1
  end

  def draw
    @sprs.each do |spr|
      spr.draw
    end
  end

  # check keyboard
  def button_down(id)
    # ESC : close window and exit.
    # close window by call Gosu::Window.close()
    close if id == Gosu::KbEscape
  end
end

window = MyWindow.new
window.show
