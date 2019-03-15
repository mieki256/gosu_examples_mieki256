#! /usr/bin/env ruby
# -*- mode: ruby; coding: utf-8 -*-
# Last updated: <2019/03/14 22:09:41 +0900>
#
# Gosu test. play wav or ogg.
#
# Ubuntu Linux 16.04上で動かした際に警告が出る症状に対処してみたものの解決せず。
# Ubuntu 18.04上なら問題は出ない。
#
# 動作確認環境:
# - Windows10 x64 + Ruby 2.2.6 p396 mingw32 + gosu 0.10.8
# - Ubuntu 16.04 LTS + Ruby 2.3.1 p112 + gosu 0.10.8
# - Ubuntu 18.04 LTS + Ruby 2.5.1 p57 + gosu 0.14.5

require 'gosu'

class MyWindow < Gosu::Window

  def initialize
    super 320, 240, false
    self.caption = 'Sound Play Test'

    # load wav
    @sounds = []
    @sis = []
    [
      "res/tmp_se_01.wav",
      "res/tmp_se_02.wav",
      "res/tmp_se_03.wav",
      "res/tmp_se_01.ogg",
      "res/tmp_se_02.ogg",
      "res/tmp_se_03.ogg"
    ].each do |fn|
      @sounds.push(Gosu::Sample.new(fn))
      @sis.push(nil)
    end
    @cnt = 0
    @close_req = 0
    @se_all_stop = false
  end

  def update
    if @se_all_stop  # SE all stop
      stop_all_se
      @se_all_stop = false
    end

    if @close_req > 0  # window close
      @close_req -= 1
      if @close_req == 0
        if se_playing?
          # playing
          @close_req = 30
          puts "SE playing (in update)"
        else
          # not playing
          dispose_se_resource
          GC.start
          close  # close window
        end
      end
      return
    end

    tm = 45
    if @cnt % tm == 0
      n = (@cnt / tm) % @sounds.length
      if @sis[n] == nil or !@sis[n].playing?
        @sis[n] = @sounds[n].play
      else
        # @sis[n].stop
      end
    end
    @cnt += 1
  end

  def draw
  end

  def button_down(id)
    if id == Gosu::KbEscape  # push ESC
      # @se_all_stop = true  # SE all stop
      @close_req = 30
    end
  end

  # check SE play
  def se_playing?
    return false unless @sis
    cnt = 0
    @sis.each do |si|
      next unless si
      cnt += 1 if si.playing?
    end
    return true if cnt > 0
    return false
  end

  # stop all SE
  def stop_all_se
    return unless @sis
    @sis.length.times do |i|
      next unless @sis[i]
      @sis[i].stop
    end
    puts "SE stop all"
  end

  # サウンド関連リソースを全て破棄、するはずなんだけど…
  def dispose_se_resource
    if @sis
      @sis.length.times { |i| @sis[i] = nil }
      @sfs = nil
    end

    if @sounds
      @sounds.length.times { |i| @sounds[i] = nil }
      @sounds = nil
    end
  end
end

wdw = MyWindow.new
wdw.show

while wdw.se_playing?
  puts "SE playing"
  sleep(1)
end
puts "SE not playing"

wdw.dispose_se_resource
wdw = nil
GC.start
exit
