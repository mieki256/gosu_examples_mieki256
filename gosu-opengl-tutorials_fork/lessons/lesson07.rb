#! /usr/bin/env ruby
# Last updated: <2023/10/15 10:09:41 +0900>
#
# Lesson 7 - Texture Filters, Lighting and Keyboard Control

require_relative 'boot'

class Texture

  attr_accessor :info, :width, :height

  def initialize(window)
    @image = Gosu::Image.new("res/nehe/lesson07/crate.png", :tileable => true)
    @width = @image.width
    @height = @image.height
    @info = @image.gl_tex_info
  end
end

class Window < Gosu::Window
  attr_accessor :current_filter

  def initialize
    super(800, 600, false)
    self.caption = "Lesson #7 - Texture Filters, Lighting and Keyboard Control"
    initialize_light
    initialize_textures
    @x_angle  = @y_angle = 0
    @x_change  = @y_change = 0.2
    @z_depth  = -5
    @light_on = false
  end

  def initialize_light
    # ambient light - lights all objects on the scene equally, format is RGBA
    @ambient_light = [0.5, 0.5, 0.5, 1.0]

    # diffuse light is created by the light source
    # and reflects off the surface of an object, format is also RGBA
    @diffuse_light = [1.0, 1.0, 1.0, 1.0]

    # position of the light source from the current point
    @light_postion = [0.0, 0.0, 2.0, 1.0]
  end

  def initialize_textures
    glGetError

    # note that window needs to keep texture variables
    # and not just tex_name which is a fixnum in order to
    # reference texture and prevent it collected by the GC
    @nearest = Texture.new(self)

    glBindTexture(GL_TEXTURE_2D, @nearest.info.tex_name)

    # Nearest filter is the worst on quality
    glTexParameteri(GL_TEXTURE_2D,GL_TEXTURE_MAG_FILTER,GL_NEAREST)

    # but fastest and lowest need for processing power
    glTexParameteri(GL_TEXTURE_2D,GL_TEXTURE_MIN_FILTER,GL_NEAREST)

    @linear = Texture.new(self)
    glBindTexture(GL_TEXTURE_2D, @linear.info.tex_name);

    # Linear filter, good quality - high demands see nehe06
    glTexParameteri(GL_TEXTURE_2D,GL_TEXTURE_MAG_FILTER,GL_LINEAR)
    glTexParameteri(GL_TEXTURE_2D,GL_TEXTURE_MIN_FILTER,GL_LINEAR)

    @minimap = Texture.new(self)
    glBindTexture(GL_TEXTURE_2D, @minimap.info.tex_name);

    #use texture data to get data for buildimg a mipmap
    unless $glbind
      # opengl
      texture = glGetTexImage(GL_TEXTURE_2D, 0, GL_RGB, GL_FLOAT)
      glTexParameteri(GL_TEXTURE_2D,GL_TEXTURE_MAG_FILTER,GL_LINEAR)

      # Mipmapping. OpenGL tried to build different sized high quality texture.
      # When you draw it OpenGL will select the best
      # looking texture from ones it built and draw that instead
      # of resizing the original image which can cause detail loss
      glTexParameteri(GL_TEXTURE_2D,GL_TEXTURE_MIN_FILTER,GL_LINEAR_MIPMAP_NEAREST)

      # building mipmaps
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
    @z_depth -= 0.2 if button_down? Gosu::Button::KB_PAGE_UP
    @z_depth += 0.2 if button_down? Gosu::Button::KB_PAGE_DOWN
    @x_change -= 0.01 if button_down? Gosu::Button::KB_UP
    @x_change += 0.01 if button_down? Gosu::Button::KB_DOWN
    @y_change -= 0.01 if button_down? Gosu::Button::KB_LEFT
    @y_change += 0.01 if button_down? Gosu::Button::KB_RIGHT
    @x_angle += @x_change
    @y_angle += @y_change
  end

  def change_filter!
    index = @filters.index(current_filter)
    index > (@filters.size - 1) ? index = 0 : index += 1
    @current_filter = @filters[index]
  end

  def current_filter
    @current_filter ||= @filters.first
  end

  def draw
    gl do
      glClearColor(0,0,0,0.5)
      glClearDepth(1)
      glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT)
      glEnable(GL_DEPTH_TEST) # see nehe06
      glDepthFunc(GL_LEQUAL) # see nehe06

      glMatrixMode(GL_PROJECTION) #see lesson01
      glLoadIdentity # see lesson01
      gluPerspective(45.0, width / height, 0.1, 100.0)

      #Perspective correction calculation for most correct/highest quality value
      glHint(GL_PERSPECTIVE_CORRECTION_HINT, GL_NICEST)

      glMatrixMode(GL_MODELVIEW)
      glLoadIdentity

      glEnable(GL_TEXTURE_2D) #see lesson01
      glShadeModel(GL_SMOOTH) # selects smooth shading

      unless $glbind
        # opengl
        # sets light
        glLightfv(GL_LIGHT1, GL_AMBIENT, @ambient_light)
        glLightfv(GL_LIGHT1, GL_DIFFUSE, @diffuse_light)
        glLightfv(GL_LIGHT1, GL_POSITION, @light_postion)
      else
        # opengl-bindings
        glLightfv(GL_LIGHT1, GL_AMBIENT, @ambient_light.pack("f*"))
        glLightfv(GL_LIGHT1, GL_DIFFUSE, @diffuse_light.pack("f*"))
        glLightfv(GL_LIGHT1, GL_POSITION, @light_postion.pack("f*"))
      end

      # enables prepared light source
      glEnable(GL_LIGHT1)

      # enables / disables lighting of the scene based on light switch
      @light_on ? glEnable(GL_LIGHTING) : glDisable(GL_LIGHTING)

      unless $glbind
        glTranslate(0, 0, @z_depth)
      else
        glTranslatef(0.0, 0.0, @z_depth)
      end

      glBindTexture(GL_TEXTURE_2D, current_filter)
      glRotatef(@x_angle, 1, 0, 0) # see nehe04
      glRotatef(@y_angle, 0, 1, 0) # see nehe04

      glBegin(GL_QUADS)

      # normal pointing to viewer.
      # Normal is a line from the middle of the polygon at 90 degree angle.
      # It is needed to tell opengl which
      # direction the polygon is facing.

      glNormal3f(0, 0, 1)
      glTexCoord2f(0, 0); glVertex3f(-1, -1,  1)
      glTexCoord2f(1, 0); glVertex3f( 1, -1,  1)
      glTexCoord2f(1, 1); glVertex3f( 1,  1,  1)
      glTexCoord2f(0, 1); glVertex3f(-1,  1,  1)

      glNormal3f(0, 0, -1) # normal point away from viewer
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
    when Gosu::Button::KB_ESCAPE
      close
    when Gosu::Button::KB_L
      # L key : switch light on or off
      @light_on = !@light_on
    when Gosu::Button::KB_F
      # F key : change filter
      change_filter!
    end
  end
end

window = Window.new
window.show
