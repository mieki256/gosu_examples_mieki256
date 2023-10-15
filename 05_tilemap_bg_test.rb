#! /usr/bin/env ruby
# -*- mode: ruby; coding: utf-8 -*-
# Last updated: <2023/10/15 09:46:20 +0900>
#
# Gosu test. Draw time map.
#
# - Ubuntu 18.04.2 x64 + Ruby 2.5.1 p57 x64 + gosu 0.14.5
# - Windows10 x64 + Ruby 2.4.5 p335 mingw32 + Gosu 0.14.5 x86-mingw32

require 'gosu'

# Tile map BG class
class Map

  # constructor
  # @param wdw_w [Integer] Window width
  # @param wdw_h [Integer] Window height
  def initialize(wdw_w, wdw_h)
    @wdw_w = wdw_w
    @wdw_h = wdw_h

    # load image
    @imgfiles = [
    "res/tmp_bg1.png",
    "res/tmp_bg2.png"
    ]
    @imgs = []
    @imgfiles.each do |fn|
      # Images can be divided and loaded using Gosu::Image.load_tiles().
      # src image: 512x512, 1chip : 32x32 -> 16 x 16 = 256 images
      imgs = Gosu::Image.load_tiles(fn, 32, 32, :tileable => true)
      @imgs.push(imgs)
    end

    # make tile map array.
    @bgarr = []
    c = 0
    16.times do |by|
      @bgarr[by] = []
      16.times do |bx|
        @bgarr[by][bx] = c
        c = (c + 1) % 256
      end
    end
  end

  # draw
  # @param bx [Integer] BG x position
  # @param by [Integer] BG y position
  # @param n [Integer] BG number (0 or 1)
  def draw(bx, by, n)
    cw, ch = 32, 32  # cell size
    bx = bx.to_i
    by = by.to_i

    imgs = @imgs[n]
    lenx = @bgarr[0].length
    leny = @bgarr.length
    cx = (bx / cw) % lenx
    cy = (by / ch) % leny
    sx = (bx % cw)
    sy = (by % ch)
    wcnt = @wdw_w / cw + 1
    hcnt = @wdw_h / ch + 1
    hcnt.times do |y|
      wcnt.times do |x|
        k = @bgarr[(cy + y) % leny][(cx + x) % lenx]
        imgs[k].draw(x * cw - sx, y * ch - sy, 0)
      end
    end
  end
end

# Main window
class MyWindow < Gosu::Window

  def initialize
    super 640, 480, false
    self.caption = "Tilemap BG draw"
    
    # tile map
    @maps = Map.new(self.width, self.height)
    # self.width、self.height : window size

    @bgx = [0, 0]
    @bgy = [0, 0]
    @frame = 0
  end

  def update
    # BG scroll
    ang = Math::cos(@frame * Math::PI / 180.0)
    @bgx[0] = -64 + (64.0 * ang) + 640
    @bgx[1] = -128 + (128.0 * ang) + 640
    @bgy[0] = (@bgy[0] + 2)
    @bgy[1] = (@bgy[1] + 6)

    @frame += 1
  end

  def draw
    2.times do |i|
      @maps.draw(@bgx[i], @bgy[i], i)
    end
  end

  # check keyboard
  def button_down(id)
    # ESC : close window and exit
    close if id == Gosu::KB_ESCAPE
  end
end

window = MyWindow.new
window.show
