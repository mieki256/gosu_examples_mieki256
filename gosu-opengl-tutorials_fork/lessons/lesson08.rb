#! /usr/bin/env ruby
# Last updated: <2019/03/20 08:18:26 +0900>
#
# Lesson 8 - Texture blending, transparency
# push L,F,B key

require_relative 'boot'

class Texture

  attr_accessor :info, :width, :height

  def initialize(window)
    @image = Gosu::Image.new("res/nehe/lesson08/Glass.bmp", :tileable => true)
    @width = @image.width
    @height = @image.height
    @info = @image.gl_tex_info
  end
end

class Window < Gosu::Window
  attr_accessor :current_filter

  def initialize
    super(800, 600, false)
    self.caption = "Lesson #8 - Texture blending, transparency"
    initialize_light
    initialize_textures
    @x_angle  = @y_angle = 0
    @x_change  = @y_change = 0.2
    @z_depth  = -5
    @light_on = false
    @blending
  end

  def initialize_light
    @ambient_light = [0.5, 0.5, 0.5, 1]
    @diffuse_light = [1, 1, 1, 1]
    @light_postion = [0, 0, 2, 1]
  end

  def initialize_textures
    glGetError
    @nearest = Texture.new(self)
    glBindTexture(GL_TEXTURE_2D, @nearest.info.tex_name)
    glTexParameteri(GL_TEXTURE_2D,GL_TEXTURE_MAG_FILTER,GL_NEAREST)
    glTexParameteri(GL_TEXTURE_2D,GL_TEXTURE_MIN_FILTER,GL_NEAREST)

    @linear = Texture.new(self)
    glBindTexture(GL_TEXTURE_2D, @linear.info.tex_name)
    glTexParameteri(GL_TEXTURE_2D,GL_TEXTURE_MAG_FILTER,GL_LINEAR)
    glTexParameteri(GL_TEXTURE_2D,GL_TEXTURE_MIN_FILTER,GL_LINEAR)

    @minimap = Texture.new(self)
    glBindTexture(GL_TEXTURE_2D, @minimap.info.tex_name)

    unless $glbind
      # opengl
      texture = glGetTexImage(GL_TEXTURE_2D, 0, GL_RGB, GL_FLOAT)
      glTexParameteri(GL_TEXTURE_2D,GL_TEXTURE_MAG_FILTER,GL_LINEAR)
      glTexParameteri(GL_TEXTURE_2D,GL_TEXTURE_MIN_FILTER,GL_LINEAR_MIPMAP_NEAREST)
      gluBuild2DMipmaps(GL_TEXTURE_2D, 3, 128, 128, GL_RGB, GL_FLOAT, texture)
    else
      # opengl-bindings
      w, h = @minimap.width, @minimap.height
      float_size = [0.0].pack("f").size
      texture = ' ' * (float_size * 4 * w * h)
      glGetTexImage(GL_TEXTURE_2D, 0, GL_RGB, GL_FLOAT, texture)
      glTexParameteri(GL_TEXTURE_2D,GL_TEXTURE_MAG_FILTER,GL_LINEAR)
      glTexParameteri(GL_TEXTURE_2D,GL_TEXTURE_MIN_FILTER,GL_LINEAR_MIPMAP_NEAREST)
      gluBuild2DMipmaps(GL_TEXTURE_2D, 3, w, h, GL_RGB, GL_FLOAT, texture)
    end

    @filters = [@nearest.info.tex_name,
                @linear.info.tex_name,
                @minimap.info.tex_name]
  end

  def update
    @z_depth -= 0.2 if button_down? Gosu::Button::KbPageUp
    @z_depth += 0.2 if button_down? Gosu::Button::KbPageDown
    @x_change -= 0.01 if button_down? Gosu::Button::KbUp
    @x_change += 0.01 if button_down? Gosu::Button::KbDown
    @y_change -= 0.01 if button_down? Gosu::Button::KbLeft
    @y_change += 0.01 if button_down? Gosu::Button::KbRight
    @x_angle += @x_change
    @y_angle += @y_change
  end

  def change_filter!
    index = @filters.index(current_filter)
    index > 1 ? index = 0 : index += 1
    @current_filter = @filters[index]
  end

  def current_filter
    @current_filter ||= @filters.first
  end

  def draw
    gl do
      glClearColor(0.0, 0.0, 0.0, 0.5)
      glClearDepth(1)
      glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT)
      glEnable(GL_DEPTH_TEST)
      glDepthFunc(GL_LEQUAL)

      glMatrixMode(GL_PROJECTION)
      glLoadIdentity
      gluPerspective(45.0, width / height, 0.1, 100.0)
      glHint(GL_PERSPECTIVE_CORRECTION_HINT, GL_NICEST)
      glMatrixMode(GL_MODELVIEW)
      glLoadIdentity

      # full brightness, 50% opacity
      glColor4f(1.0,1.0,1.0,0.5)

      # blending function for translucency based on alpha source
      glBlendFunc(GL_SRC_ALPHA,GL_ONE)

      glEnable(GL_TEXTURE_2D)
      glShadeModel(GL_SMOOTH)

      unless $glbind
        # opengl
        glLightfv(GL_LIGHT1, GL_AMBIENT, @ambient_light)
        glLightfv(GL_LIGHT1, GL_DIFFUSE, @diffuse_light)
        glLightfv(GL_LIGHT1, GL_POSITION, @light_postion)
      else
        # opengl-bindings
        glLightfv(GL_LIGHT1, GL_AMBIENT, @ambient_light.pack("f*"))
        glLightfv(GL_LIGHT1, GL_DIFFUSE, @diffuse_light.pack("f*"))
        glLightfv(GL_LIGHT1, GL_POSITION, @light_postion.pack("f*"))
      end

      glEnable(GL_LIGHT1)
      @light_on ? glEnable(GL_LIGHTING) : glDisable(GL_LIGHTING)

      if @blending
        glEnable(GL_BLEND)        # enable blending
        glDisable(GL_DEPTH_TEST)  # disable depth
      else
        glDisable(GL_BLEND)
        glEnable(GL_DEPTH_TEST)
      end

      unless $glbind
        glTranslate(0, 0, @z_depth)
      else
        glTranslatef(0.0, 0.0, @z_depth)
      end

      glBindTexture(GL_TEXTURE_2D, current_filter)
      glRotatef(@x_angle, 1, 0, 0)
      glRotatef(@y_angle, 0, 1, 0)

      glBegin(GL_QUADS)
      glNormal3f(0, 0, 1)
      glTexCoord2f(0, 0); glVertex3f(-1, -1,  1)
      glTexCoord2f(1, 0); glVertex3f( 1, -1,  1)
      glTexCoord2f(1, 1); glVertex3f( 1,  1,  1)
      glTexCoord2f(0, 1); glVertex3f(-1,  1,  1)

      glNormal3f(0, 0, -1)
      glTexCoord2f(1, 0); glVertex3f(-1, -1, -1)
      glTexCoord2f(1, 1); glVertex3f(-1,  1, -1)
      glTexCoord2f(0, 1); glVertex3f( 1,  1, -1)
      glTexCoord2f(0, 0); glVertex3f( 1, -1, -1)

      glNormal3f(0, 1, 0)
      glTexCoord2f(0, 1); glVertex3f(-1,  1, -1)
      glTexCoord2f(0, 0); glVertex3f(-1,  1,  1)
      glTexCoord2f(1, 0); glVertex3f( 1,  1,  1)
      glTexCoord2f(1, 1); glVertex3f( 1,  1, -1)

      glNormal3f(0, -1, 0)
      glTexCoord2f(1, 1); glVertex3f(-1, -1, -1)
      glTexCoord2f(0, 1); glVertex3f( 1, -1, -1)
      glTexCoord2f(0, 0); glVertex3f( 1, -1,  1)
      glTexCoord2f(1, 0); glVertex3f(-1, -1,  1)

      glNormal3f(1, 0, 0)
      glTexCoord2f(1, 0); glVertex3f( 1, -1, -1)
      glTexCoord2f(1, 1); glVertex3f( 1,  1, -1)
      glTexCoord2f(0, 1); glVertex3f( 1,  1,  1)
      glTexCoord2f(0, 0); glVertex3f( 1, -1,  1)

      glNormal3f(-1, 0, 0)
      glTexCoord2f(0, 0); glVertex3f(-1, -1, -1)
      glTexCoord2f(1, 0); glVertex3f(-1, -1,  1)
      glTexCoord2f(1, 1); glVertex3f(-1,  1,  1)
      glTexCoord2f(0, 1); glVertex3f(-1,  1, -1)
      glEnd
    end
  end

  def button_down(id)
    case id
    when Gosu::Button::KbEscape
      close
    when Gosu::Button::KbL
      @light_on = !@light_on
    when Gosu::Button::KbF
      change_filter!
    when Gosu::Button::KbB
      @blending = !@blending
    end
  end
end

window = Window.new
window.show
