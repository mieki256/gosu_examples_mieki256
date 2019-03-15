#! /usr/bin/env ruby
# -*- mode: ruby; coding: utf-8 -*-
# Last updated: <2019/03/15 19:43:24 +0900>
#
# opengl + glut test only.
#
# - Windows 10 x64 + ruby 2.2.6p396 mingw32
#
# gem install gosu
# gem install opengl
# gem install glu
# gem install glut
#
# Ubuntu 18.04 + Ruby 2.5.1 p57 : glut install failure.
#
# 参考ページ
# RubyでOpenGL - verus diary
# http://d.hatena.ne.jp/verus/20080225/1203880010
#
# ruby-openglでお手軽3Dプログラミング | Gemの紹介 | DoRuby
# https://doruby.jp/users/akio0911_on_rails/entries/ruby-opengl_3D_
#
# MF / Ruby で OpenGL
# http://medfreak.info/?p=399

require "opengl"
require "glut"
require "glu"

# 表示処理
display = proc {
  GL.Clear(GL::COLOR_BUFFER_BIT)  # カラーバッファをクリア
  GL.Color3f(0.0 , 1.0 , 0.0)  # 色を指定
  GLUT.WireTeapot(0.5)  # ティーポットを表示
  GLUT.SwapBuffers()  # 画面を入れ替え(ダブルバッファ)
}

# ウインドウが変形したり最初に生成された際に呼ばれる処理
reshape = proc { |w, h|
  GL.Viewport(0, 0, w, h)  # ビューポートを設定

  GL.MatrixMode(GL::GL_PROJECTION)  # 演算ターゲットを射影行列に
  GL.LoadIdentity()  # 変換行列を単位行列に
  GLU.Perspective(30.0, w.to_f/h, 1.0, 100.0)  # 透視投影を指定

  GL.MatrixMode(GL::GL_MODELVIEW)  # 演算ターゲットをモデルビュー行列に
  GL.LoadIdentity()  # 変換行列を単位行列に

  GLU.LookAt(3.0, 2.0, 1.0, # カメラ位置
             0.0, 0.0, 0.0, # 注視点の位置
             0.0, 1.0, 0.0 # どっちが上かを指定
             );
}

# 一定時間ごとに呼ばれる処理
timer = proc {
  GL.Rotate(2.0, 0.0, 1.0, 0.0)  # Y軸を回転 (ang, x, y, z)
  GLUT.PostRedisplay()  # 再描画を要求
  GLUT.TimerFunc(16, timer, 0)  # 16ms毎に呼び直す
}

GLUT.Init()  # GLUTの初期化
GLUT.InitWindowSize(512, 512)  # ウインドウサイズを指定
GLUT.CreateWindow("OpenGL:Teapot") # ウインドウを生成

GLUT.DisplayFunc(display) # ディスプレイコールバックの登録
GLUT.ReshapeFunc(reshape)  # リシェイプコールバックの登録
GLUT.TimerFunc(10, timer, 0)  # 一定時間ごとに呼ばれる処理を登録

GL.ClearColor(0.2,0.2,0.2,0.0)  # 画面クリア時の色を指定

GLUT.MainLoop()  # メインループ
