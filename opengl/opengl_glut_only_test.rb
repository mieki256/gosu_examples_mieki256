#! /usr/bin/env ruby
# -*- mode: ruby; coding: utf-8 -*-
# Last updated: <2019/03/17 04:09:59 +0900>
#
# opengl + glut test only.
#
# == opengl
#
# gem install opengl
# gem install glu
# gem install glut
#
# * Windows 10 x64 + ruby 2.2.6p396 mingw32
#
# == opengl-bindings
#
# gem install opengl-bindings
#
# * Windows 10 x64 + Ruby 2.5.3 p105 mingw32
# * Ubuntu 18.04 + Ruby 2.5.1 p57
#
# == 参考ページ
#
# RubyでOpenGL - verus diary
# http://d.hatena.ne.jp/verus/20080225/1203880010
#
# ruby-openglでお手軽3Dプログラミング | Gemの紹介 | DoRuby
# https://doruby.jp/users/akio0911_on_rails/entries/ruby-opengl_3D_
#
# MF / Ruby で OpenGL
# http://medfreak.info/?p=399

begin
  # gem install opengl
  # gem install glu
  # gem install glut

  require 'gl'
  require "glu"
  require "glut"

  include Gl
  include Glu
  include Glut

  puts "load opengl"
  glbind = false
rescue LoadError
  # gem install opengl-bindings

  require 'opengl'
  require "glu"
  require "glut"

  OpenGL.load_lib
  GLU.load_lib
  GLUT.load_lib

  include OpenGL
  include GLU
  include GLUT

  puts "load opengl-bindings"
  glbind = true
end

# draw
display = proc {
  glClear(GL_COLOR_BUFFER_BIT)   # カラーバッファをクリア
  glColor3f(0.0 , 1.0 , 0.0)     # 色を指定

  # ティーポットを表示
  # glutSolidTeapot(0.5)
  glutWireTeapot(0.5)

  glutSwapBuffers()              # ダブルバッファ切替
}

# ウインドウが変形したり最初に生成された際に呼ばれる処理
reshape = proc { |w, h|
  glViewport(0, 0, w, h)       # ビューポート指定
  glMatrixMode(GL_PROJECTION)  # 演算ターゲットを射影行列に
  glLoadIdentity()             # 変換行列を単位行列に
  gluPerspective(30.0, w.to_f/h, 1.0, 100.0)  # 透視投影を指定

  glMatrixMode(GL_MODELVIEW)   # 演算ターゲットをモデルビュー行列に
  glLoadIdentity()             # 変換行列を単位行列に

  gluLookAt(
  3.0, 2.0, 1.0,  # カメラ位置
  0.0, 0.0, 0.0,  # 注視点の位置
  0.0, 1.0, 0.0   # どっちが上かを指定
  )
}

# 一定時間ごとに呼ばれる処理
timer = proc {
  glRotatef(2.0, 0.0, 1.0, 0.0)  # Y軸を回転 (ang, x, y, z)
  glutPostRedisplay()            # 再描画を要求

  # 16ms毎に呼び直す
  unless glbind
    glutTimerFunc(16, timer, 0)
  else
    glutTimerFunc(16, GLUT.create_callback(:GLUTTimerFunc, timer), 0)
  end
}

keyboard = proc { |key, x, y|
  case key
  when 27 # Press ESC to exit.
    exit
  end
}

if __FILE__ == $0
  # GLUTの初期化
  unless glbind
    glutInit()
  else
    glutInit([1].pack('I'), [""].pack('p'))
  end

  # ウインドウモードを設定
  glutInitDisplayMode( GLUT_DOUBLE | GLUT_RGBA | GLUT_DEPTH )

  # ウインドウサイズを指定
  glutInitWindowSize(512, 512)

  # ウインドウを生成
  glutCreateWindow("OpenGL:Teapot")

  unless glbind
    glutDisplayFunc(display)     # ディスプレイコールバックの登録
    glutReshapeFunc(reshape)     # リシェイプコールバックの登録
    glutKeyboardFunc(keyboard)   # キー入力コールバックの登録
    glutTimerFunc(16, timer, 0)  # 一定時間ごとに呼ばれる処理を登録
  else
    # glutDisplayFunc(GLUT.create_callback(:GLUTDisplayFunc, method(:display).to_proc))

    glutDisplayFunc(GLUT.create_callback(:GLUTDisplayFunc, display))
    glutReshapeFunc(GLUT.create_callback(:GLUTReshapeFunc, reshape))
    glutKeyboardFunc(GLUT.create_callback(:GLUTKeyboardFunc, keyboard))
    glutTimerFunc(16, GLUT.create_callback(:GLUTTimerFunc, timer), 0)
  end


  # 画面クリア時の色を指定
  glClearColor(0.2, 0.2, 0.2, 0.0)

  # メインループ
  glutMainLoop()
end

