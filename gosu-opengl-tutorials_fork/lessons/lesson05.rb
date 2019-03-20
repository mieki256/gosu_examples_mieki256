#! /usr/bin/env ruby
# Last updated: <2019/03/20 03:44:20 +0900>
#
# Lesson 5 - 3D Shapes

require_relative 'boot'

class Window < Gosu::Window

  attr_accessor :rotation_angle

  def initialize
    super(800, 600, false)
    self.caption = "Lesson #5 - 3D Shapes"
    @rotation_angle = 0
  end

  def update
    @rotation_angle += 2.0
  end

  def draw
    gl do
      glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT)
      glMatrixMode(GL_PROJECTION)
      glLoadIdentity
      gluPerspective(45.0, width / height, 0.1, 100.0)
      glMatrixMode(GL_MODELVIEW)
      glLoadIdentity

      glTranslatef(0, 0, -7)

      glRotatef(@rotation_angle, 0.0, 1.0, 0.0) # see nehe04

      glBegin(GL_TRIANGLES)
      glColor3f(1, 0, 0)
      glVertex3f( 0,  1, 0)
      glColor3f(0, 1, 0)
      glVertex3f(-1, -1, 1)
      glColor3f(0, 0, 1)
      glVertex3f(1, -1, 1)

      glColor3f(1, 0, 0)
      glVertex3f( 0,  1, 0)
      glColor3f(0, 1, 0)
      glVertex3f( 1, -1, 1)
      glColor3f(0, 0, 1)
      glVertex3f(1, -1, -1)

      glColor3f(1, 0, 0)
      glVertex3f( 0,  1, 0)
      glColor3f(0, 0, 1)
      glVertex3f(-1, -1, 1)
      glColor3f(0, 0, 1)
      glVertex3f(-1, -1, -1)

      glColor3f(1, 0, 0)
      glVertex3f( 0,  1, 0)
      glColor3f(0, 1, 0)
      glVertex3f(-1, -1, -1)
      glColor3f(0, 0, 1)
      glVertex3f(1, -1, -1)
      glEnd

      glColor3f(1, 0, 0)
      glBegin(GL_QUADS)
      glVertex3f(1, -1, 1)
      glVertex3f(1, -1, -1)
      glVertex3f(-1, -1, -1)
      glVertex3f(-1, -1, 1)
      glEnd
    end
  end

  def button_down(id)
    close if id == Gosu::KbEscape
  end
end

window = Window.new
window.show
