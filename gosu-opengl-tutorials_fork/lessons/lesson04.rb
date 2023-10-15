#! /usr/bin/env ruby
# Last updated: <2023/10/15 09:48:20 +0900>
#
# Lesson 4 - Rotation animation

require_relative 'boot'

class Window < Gosu::Window

  attr_accessor :rotation_angle

  def initialize
    super(800, 600, false)
    self.caption = "Lesson #4 - Rotation animation"
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

      glTranslatef(-2, 0, -10)

      # rotate object around vector set by traveling to x,y,z from current unit,
      # angle is in degrees
      glRotatef(@rotation_angle, 0, 1, 0)

      glBegin(GL_TRIANGLES)

      glColor3f(1, 0, 0) #  see nehe03
      glVertex3f(0, 1, 0)

      glColor3f(0, 1, 0)
      glVertex3f(1, -1, 0)

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
