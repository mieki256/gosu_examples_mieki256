#! /usr/bin/env ruby
# Last updated: <2023/10/15 09:48:13 +0900>
#
# Lesson 3 - Adding colors

require_relative 'boot'

class Window < Gosu::Window
  def initialize
    super(800, 600, false)
    self.caption = "Lesson #3 - Adding colors"
  end

  def update
  end

  def draw
    gl do
      glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT)
      glMatrixMode(GL_PROJECTION)
      glLoadIdentity
      gluPerspective(45.0, width / height, 0.1, 100.0)
      glMatrixMode(GL_MODELVIEW)
      glLoadIdentity

      glTranslatef(-2, 0, -10)

      glBegin(GL_TRIANGLES)
      glColor3f(1, 0, 0) # sets color to be used using RBG
      glVertex3f( 0,1, 0)
      glColor3f(0, 1, 0)
      glVertex3f( 1, -1, 0)
      glColor3f(0, 0, 1)
      glVertex3f(-1, -1, 0)
      glEnd
    end
  end

  def button_down(id)
    close if id == Gosu::KB_ESCAPE
  end
end

Window.new.show
