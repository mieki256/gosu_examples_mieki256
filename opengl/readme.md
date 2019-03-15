<!-- -*- encoding: utf-8 -*- -->

必要なパッケージ
----------------

Ruby + gosu で OpenGL を動かすためには、opengl をインストールしないといけない。

    gem install gosu
    gem install opengl


opengl.rb は修正が必要
----------------------

[larskanis/opengl: The official repository of the ruby-opengl wrapper](https://github.com/larskanis/opengl)

[invalid operation for glEnd - Issue #18 - larskanis/opengl](https://github.com/larskanis/opengl/issues/18)


 opengl.rb は一部バグっている。修正が必要。

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



