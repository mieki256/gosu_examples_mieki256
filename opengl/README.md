<!-- -*- encoding: utf-8 -*- -->

動作に必要なパッケージ
----------------------

Ruby + gosu で OpenGL を動かすためには、opengl をインストールしないといけない。

    gem install gosu
    gem install opengl
    gem install glu
    gem install glut

- [larskanis/opengl](https://github.com/larskanis/opengl)

opengl-bindings を使う選択肢もある。

    gem install opengl-bindings

- [vaiorabbit/ruby-opengl](https://github.com/vaiorabbit/ruby-opengl)

ただし、opengl を使った場合とは一部書き方が異なる。
また、Windows上で glut や glfw を使う場合は、freeglut.dll と glfw3.dll が必要になる。

- [GLFW - Download](https://www.glfw.org/download.html)
- [freeglut Windows Development Libraries](https://www.transmissionzero.co.uk/software/freeglut-devel/)


opengl.rb は修正が必要
----------------------

- [larskanis/opengl: The official repository of the ruby-opengl wrapper](https://github.com/larskanis/opengl)
- [invalid operation for glEnd - Issue #18 - larskanis/opengl](https://github.com/larskanis/opengl/issues/18)


 opengl.rb は Windows上で動作させると一部でバグる。修正が必要。

opengl.rb を開く。

    [Ruby install folder]\lib\ruby\gems\2.?.0\gems\opengl-*-x86-mingw32\lib\opengl.rb


implementation.send の前や後ろに、begin/rescue を挿入。

    define_singleton_method(mn) do |*args,&block|
      begin
        implementation.send(mn, *args, &block)
      rescue
      end
    end
    define_method(mn) do |*args,&block|
      begin
       implementation.send(mn, *args, &block)
      rescue
      end
    end

Screenshot
----------

- 01_gosu_opengl_11.rb
![01_gosu_opengl_11.rb](./screenshot\01_gosu_opengl_11.png)

- 16_gosu_opengl_test1.rb
![16_gosu_opengl_test1.rb](./screenshot/16_gosu_opengl_test1_ss.png)

- 17_gosu_opengl_test2.rb
![17_gosu_opengl_test2.rb](./screenshot/17_gosu_opengl_test2_ss.png)

- opengl_glut_only_test.rb
![opengl_glut_only_test.rb](./screenshot/opengl_glut_only_test_ss.png)

