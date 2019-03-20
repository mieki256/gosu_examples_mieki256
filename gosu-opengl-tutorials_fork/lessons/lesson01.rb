#! /usr/bin/env ruby
# Last updated: <2019/03/20 09:38:09 +0900>
#
# Lesson 1

require_relative 'boot'

class Window < Gosu::Window
  def initialize
    super(800, 600, false)
    self.caption = "Lesson #1 - Texture Loading"
    texture = Gosu::Image.new("res/tj/lesson01/earth.png", :tileable => true)
    @tex_info = texture.gl_tex_info
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

      unless $glbind
        # opengl
        glTranslate(0, 0, -2)
      else
        # opengl-bindings
        glTranslatef(0.0, 0.0, -2.0)
      end

      glEnable(GL_TEXTURE_2D)
      glBindTexture(GL_TEXTURE_2D, @tex_info.tex_name)

      w, h, z = 0.5, 0.5, 0.0
      glBegin(GL_QUADS)
      glTexCoord2d(@tex_info.left, @tex_info.top)
      glVertex3d(0, 0, z)

      glTexCoord2d(@tex_info.right, @tex_info.top)
      glVertex3d(w, 0, z)

      glTexCoord2d(@tex_info.right, @tex_info.bottom)
      glVertex3d(w, -h, z)

      glTexCoord2d(@tex_info.left, @tex_info.bottom)
      glVertex3d(0, -h, z)
      glEnd
    end
  end

  def button_down(id)
    close if id == Gosu::KbEscape
  end
end

Window.new.show
