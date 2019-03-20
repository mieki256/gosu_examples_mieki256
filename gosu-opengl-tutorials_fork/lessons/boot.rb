#! /usr/bin/ev ruby

require 'gosu'

$glbind = false

begin
  # gem install opengl glu glut

  require 'gl'
  require "glu"
  require "glut"

  include Gl
  include Glu
  include Glut

  puts "load opengl"
  $glbind = false
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
  $glbind = true
end
