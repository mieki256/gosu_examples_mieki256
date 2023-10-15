#! /usr/bin/env ruby
# -*- mode: ruby; coding: utf-8 -*-
# Last updated: <2023/10/15 09:46:38 +0900>
#
# Gosu test. Draw sprites and BG.
#
# - Ubuntu Linux 18.04.2 LTS x64
# - Ruby 2.5.1p57 (2018-03-29 revision 63029) [x86_64-linux-gnu]
# - Gosu 0.14.5

require 'gosu'

# Sprite class
class MySpr
  
  def initialize(x, y, vx, vy, img, z, scrw, scrh)
    @fpx = x
    @fpy = y
    @fpvx = vx
    @fpvy = vy
    @scrw = scrw
    @scrh = scrh
    @z = z
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
    @image.draw(@x, @y, @z)
  end
end

# Tile map BG class
class Map
  
  # @param wdw_w [Integer] window width
  # @param wdw_h [Integer] window height
  def initialize(wdw_w, wdw_h, z)
    @wdw_w = wdw_w
    @wdw_h = wdw_h
    @z = z
    
    @imgfiles = [
    'res/tmp_bg1.png',
    'res/tmp_bg2.png'
    ]
    @imgs = []
    @imgfiles.each do |fn|
      imgs = Gosu::Image.load_tiles(fn, 32, 32, :tileable => true)
      @imgs.push(imgs)
    end

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

  # draw tile map BG
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
        imgs[k].draw(x * cw - sx, y * ch - sy, @z + n)
      end
    end
  end
end

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

# Main window
class MyWindow < Gosu::Window
  
  def initialize
    super 640, 480, false
    self.caption = 'Draw sprites and BG'
    scrw, scrh = self.width, self.height  # window size

    # font
    @font = Gosu::Font.new(20)

    # BG init.
    @maps = Map.new(scrw, scrh, 0)
    @bgx = [0, 0]
    @bgy = [0, 0]

    # born sprites
    pmax = 512
    img = Gosu::Image.new('res/tmp_ufo.png', :tileable => true)
    x = 320
    y = 240
    @sprgroup = []
    pmax.times do |i|
      rad = (i * 360 / pmax) * Math::PI / 180
      d = 3.0
      dx = d * Math.cos(rad)
      dy = d * Math.sin(rad)
      @sprgroup.push(MySpr.new(x, y, dx, dy, img, 100, scrw, scrh))
    end

    @frate = FrameRate.new

    @frame = 0
    @draw_frame = 0
  end

  def update
    # BG scroll
    ang = Math.cos(@frame * Math::PI / 180.0)
    @bgx[0] = -64 + (64.0 * ang) + 640
    @bgx[1] = -128 + (128.0 * ang) + 640
    @bgy[0] = (@bgy[0] + 2)
    @bgy[1] = (@bgy[1] + 6)

    # update sprite position
    @sprgroup.each do |spr|
      spr.update
    end

    @frame += 1
  end

  def draw
    # draw BG
    2.times do |i|
      @maps.draw(-@bgx[i], -@bgy[i], i)
    end

    # draw sprites
    @sprgroup.each do |spr|
      spr.draw
    end

    @draw_frame += 1

    @frate.update
    f = @frate.framerate.to_s

    # draw text
    col = 0xff_ffff00
    fps = sprintf("%.3f", f)
    @font.draw_text("#{fps} FPS", 10, 10, 2000, 1.0, 1.0, col)
    @font.draw_text("#{@frame} : update frame", 10, 30, 2000, 1.0, 1.0, col)
    @font.draw_text("#{@draw_frame} : draw frame", 10, 50, 2000, 1.0, 1.0, col)
  end

  # check keyboard
  def button_down(id)
    # ESC :  close window and exit.
    close if id == Gosu::KB_ESCAPE
  end
end

window = MyWindow.new
window.show
