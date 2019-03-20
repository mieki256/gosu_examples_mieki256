#! /usr/bin/env ruby
# Last updated: <2019/03/20 03:56:03 +0900>
#
# Lesson 6 - Texture Mapping

require_relative 'boot'

class Texture

  attr_accessor :info

  def initialize(window)
    @image = Gosu::Image.new("res/nehe/lesson06/ruby.png", :tileable => true)
    @info = @image.gl_tex_info
  end
end
class Window < Gosu::Window

  def initialize
    super(800, 600, false)
    self.caption = "Lesson #6 - Texture Mapping"
    @texture = Texture.new(self)
    @x_angle = @y_angle = @z_angle = 0
  end

  def update
    spd = 4.0
    @x_angle = (@x_angle + 0.3 * spd) % 360.0
    @y_angle = (@y_angle + 0.2 * spd) % 360.0
    @z_angle = (@z_angle + 0.4 * spd) % 360.0
  end

  def draw
    gl do
      glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT)

      glEnable(GL_DEPTH_TEST) # enables depth testing

      # Our depth function. Everything that is less or equal the actual value gets drawn.
      # Depth buffet value is 1/z
      glDepthFunc(GL_LEQUAL)

      glMatrixMode(GL_PROJECTION) #see lesson01
      glLoadIdentity # see lesson01

      gluPerspective(45.0, width / height, 0.1, 100.0)

      #Perspective correction calculation for most correct/highest quality value
      glHint(GL_PERSPECTIVE_CORRECTION_HINT, GL_NICEST)

      glMatrixMode(GL_MODELVIEW)
      glLoadIdentity

      unless $glbind
        # opengl
        glTranslate(0, 0, -10)
      else
        # opengl-bindings
        glTranslatef(0.0, 0.0, -10.0)
      end

      glEnable(GL_TEXTURE_2D)
      glBindTexture(GL_TEXTURE_2D, @texture.info.tex_name)

      #linear filter when image is larger than actual texture
      glTexParameteri(GL_TEXTURE_2D,GL_TEXTURE_MIN_FILTER,GL_LINEAR)

      #linear filter when image is smaller than actual texture
      glTexParameteri(GL_TEXTURE_2D,GL_TEXTURE_MAG_FILTER,GL_LINEAR)

      glRotatef(@x_angle, 1, 0, 0) # see nehe04
      glRotatef(@y_angle, 0, 1, 0) # see nehe04
      glRotatef(@z_angle, 0, 0, 1) # see nehe04

      glBegin(GL_QUADS)
      glTexCoord2f(0, 0); glVertex3f(-1, -1,  1)
      glTexCoord2f(1, 0); glVertex3f( 1, -1,  1)
      glTexCoord2f(1, 1); glVertex3f( 1,  1,  1)
      glTexCoord2f(0, 1); glVertex3f(-1,  1,  1)
      glTexCoord2f(1, 0); glVertex3f(-1, -1, -1)
      glTexCoord2f(1, 1); glVertex3f(-1,  1, -1)
      glTexCoord2f(0, 1); glVertex3f( 1,  1, -1)
      glTexCoord2f(0, 0); glVertex3f( 1, -1, -1)

      glTexCoord2f(0, 1); glVertex3f(-1,  1, -1)
      glTexCoord2f(0, 0); glVertex3f(-1,  1,  1)
      glTexCoord2f(1, 0); glVertex3f( 1,  1,  1)
      glTexCoord2f(1, 1); glVertex3f( 1,  1, -1)

      glTexCoord2f(1, 1); glVertex3f(-1, -1, -1)
      glTexCoord2f(0, 1); glVertex3f( 1, -1, -1)
      glTexCoord2f(0, 0); glVertex3f( 1, -1,  1)
      glTexCoord2f(1, 0); glVertex3f(-1, -1,  1)

      glTexCoord2f(1, 0); glVertex3f( 1, -1, -1)
      glTexCoord2f(1, 1); glVertex3f( 1,  1, -1)
      glTexCoord2f(0, 1); glVertex3f( 1,  1,  1)
      glTexCoord2f(0, 0); glVertex3f( 1, -1,  1)

      glTexCoord2f(0, 0); glVertex3f(-1, -1, -1)
      glTexCoord2f(1, 0); glVertex3f(-1, -1,  1)
      glTexCoord2f(1, 1); glVertex3f(-1,  1,  1)
      glTexCoord2f(0, 1); glVertex3f(-1,  1, -1)
      glEnd
    end
  end

  def button_down(id)
    close if id == Gosu::KbEscape
  end
end

window = Window.new
window.show
