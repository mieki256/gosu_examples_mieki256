#! /usr/bin/env ruby
# -*- mode: ruby; coding: utf-8 -*-
# Last updated: <2019/03/15 02:52:53 +0900>
#
# Ruby + gosu + opengl の動作確認
# gosu-examples の opengl_integration.rb を弄ってOpenGL絡みの部分だけを列挙
#
# OpenGL 2.0風。
# GLSLでシェーダを書いて、四角形を回転させるテスト
# phongシェーディング + テクスチャマッピング
#
# 床井研究室 - 第１回 シェーダプログラムの読み込み
# http://marina.sys.wakayama-u.ac.jp/~tokoi/?date=20051006
#
# 床井研究室 - 第２回 Gouraud シェーディングと Phong シェーディング
# http://marina.sys.wakayama-u.ac.jp/~tokoi/?date=20051007
#
# 床井研究室 - 第３回 テクスチャの参照
# http://marina.sys.wakayama-u.ac.jp/~tokoi/?date=20051008
#
# 算譜記録帳: OpenGLでの頂点データの扱いの変化
# http://mklearning.blogspot.com/2014/08/opengl.html
#
# OpenGLプログラミング - Wikibooks
# https://ja.wikibooks.org/wiki/OpenGLプログラミング
#
# gosu-examples
# https://github.com/gosu/gosu-examples

require 'gosu'
require 'gl'

TEX_FILE = "res/UVCheckerMap01-1024.png"

WIDTH, HEIGHT = 640, 480

LIGHT_POS = [0.0, 0.0, 5.0, 1.0]   # 光源の位置
LIGHT_AMB = [0.1, 0.1, 0.1, 1.0]   # 環境光
LIGHT_DIF = [1.0, 1.0, 1.0, 1.0]   # 拡散光
LIGHT_SPE = [1.0, 1.0, 1.0, 1.0]   # 鏡面光

class GlObj

  # 初期化
  def initialize(pos_x = 0.0, pos_y = 0.0, pos_z = -3.0)
    @pos = { :x => pos_x, :y => pos_y, :z => pos_z }
    @rot_x = 10.0
    @rot_y = 0.0

    # テクスチャ画像読み込み
    @img = Gosu::Image.new(TEX_FILE, :tileable => true)

    # OpenGL用のテクスチャ情報を取得
    @texinfo = @img.gl_tex_info

    # 巨大テクスチャを与えるとgosu側が gl_tex_info を取得できない時がある
    abort "Error : #{TEX_FILE} is not load. Can't get gl_tex_info" unless @texinfo

    # プラグラマブルシェーダを設定
    init_shader

    # 四角形の頂点データ
    @attrs = [
      # x, y, z, nx, ny, nz, u, v
      -1.0, -1.0, 0.0, 0.0, 0.0, 1.0, 0.0, 0.5,
      1.0, -1.0, 0.0, 0.0, 0.0, 1.0, 0.5, 0.5,
      1.0, 1.0, 0.0, 0.0, 0.0, 1.0, 0.5, 0.0,
      -1.0, 1.0, 0.0, 0.0, 0.0, 1.0, 0.0, 0.0,
    ]

    @buffers = glGenBuffers(1)  # VBOを用意。バッファを生成

    # バッファにデータを設定
    glBindBuffer(GL_ARRAY_BUFFER, @buffers[0])  # バッファ種類を設定
    data = @attrs.pack("f*")  # Rubyの場合、データはpackして渡す
    glBufferData(GL_ARRAY_BUFFER, data.size, data, GL_STATIC_DRAW)
  end

  # 更新処理
  def update
    @rot_y = (@rot_y + 1.0) % 360.0
  end

  # 描画処理
  def draw(z)
    # Gosu.gl(z値)でOpenGLの描画を行う
    # 描画後にGosu側の描画ができるようにしてくれるらしい
    Gosu.gl(z) { exec_gl }
  end

  private

  include Gl

  # プログラマブルシェーダの初期化
  def init_shader

    # ----------------------------------------
    # 頂点シェーダ(Vertex Shader)のソース
    vert_shader_src =<<EOS
#version 120
varying vec4 position;
varying vec3 normal;

void main(void)
{
  position = gl_ModelViewMatrix * gl_Vertex;
  normal = normalize(gl_NormalMatrix * gl_Normal);
  gl_TexCoord[0] = gl_TextureMatrix[0] * gl_MultiTexCoord0;
  gl_Position = ftransform();
}
EOS

    # ----------------------------------------
    # フラグメントシェーダ(Fragment Shader)のソース
    frag_shader_src =<<EOS
#version 120

uniform sampler2D texture;

varying vec4 position;
varying vec3 normal;

void main (void)
{
  vec4 color = texture2DProj(texture, gl_TexCoord[0]);
  vec3 light = normalize((gl_LightSource[0].position * position.w - gl_LightSource[0].position.w * position).xyz);
  vec3 fnormal = normalize(normal);
  float diffuse = max(dot(light, fnormal), 0.0);

  vec3 view = -normalize(position.xyz);
  vec3 halfway = normalize(light + view);
  float specular = pow(max(dot(fnormal, halfway), 0.0), gl_FrontMaterial.shininess);
  gl_FragColor = color * (gl_LightSource[0].diffuse * diffuse + gl_LightSource[0].ambient)
                + gl_FrontLightProduct[0].specular * specular;
}
EOS

    # 頂点シェーダを設定
    vert_shader = glCreateShader(GL_VERTEX_SHADER)  # 1. シェーダオブジェクト作成
    glShaderSource(vert_shader, vert_shader_src)    # 2. シェーダのソースを渡す
    glCompileShader(vert_shader)                    # 3. シェーダをコンパイル

    # 4. 正しくコンパイルできたか確認
    compiled = glGetShaderiv(vert_shader, GL_COMPILE_STATUS)
    abort "Error : Compile error in vertex shader" if compiled == GL_FALSE

    # フラグメントシェーダを設定
    frag_shader = glCreateShader(GL_FRAGMENT_SHADER)  # 1.
    glShaderSource(frag_shader, frag_shader_src)      # 2.
    glCompileShader(frag_shader)                      # 3.
    compiled = glGetShaderiv(frag_shader, GL_COMPILE_STATUS)  # 4.
    abort "Error : Compile error in fragment shader" if compiled == GL_FALSE

    @shader = glCreateProgram             # 5. プログラムオブジェクト作成
    glAttachShader(@shader, vert_shader)  # 6. シェーダオブジェクトを登録
    glAttachShader(@shader, frag_shader)
    glLinkProgram(@shader)                # 7. シェーダプログラムをリンク

    # 8. 正しくリンクできたか確認
    linked = glGetProgramiv(@shader, GL_LINK_STATUS)
    abort "Error : Linke error" if linked == GL_FALSE

    glUseProgram(@shader)                 # 9. シェーダプログラムを適用

    glDeleteShader(vert_shader)           # 10. 設定が終わったので後始末
    glDeleteShader(frag_shader)
  end

  # OpenGL関係の処理
  def exec_gl
    glClearColor(0.3, 0.3, 1.0, 0.0)    # 画面クリア色を r,g,b,a で指定
    glClearDepth(1.0)                   # デプスバッファをクリア
    glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT)  # 画面クリア

    glDepthFunc(GL_LESS)       # 奥行き比較関数の種類を指定

    glEnable(GL_DEPTH_TEST)    # デプスバッファを使う

    glEnable(GL_BLEND)         # アルファブレンドを有効化
    glBlendFunc(GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA)

    glDisable(GL_CULL_FACE)    # 片面表示を無効化

    glEnable(GL_LIGHTING)      # 光源の有効化
    glEnable(GL_LIGHT0)        # 0番目のライトを有効化
    glLightfv(GL_LIGHT0, GL_POSITION, LIGHT_POS)  # 光源の位置
    glLightfv(GL_LIGHT0, GL_AMBIENT, LIGHT_AMB)   # 環境光
    glLightfv(GL_LIGHT0, GL_DIFFUSE, LIGHT_DIF)   # 拡散光
    glLightfv(GL_LIGHT0, GL_SPECULAR, LIGHT_SPE)  # 鏡面光

    glMatrixMode(GL_PROJECTION)  # 透視投影の設定
    glLoadIdentity               # 変換行列の初期化
    glFrustum(-0.10, 0.10, -0.075, 0.075, 0.1, 100)  # 視野範囲を設定

    glMatrixMode(GL_MODELVIEW)  # モデルビュー変換の指定
    glLoadIdentity              # 変換行列の初期化
    glTranslate(@pos[:x], @pos[:y], @pos[:z])  # 平行移動
    glRotate(@rot_x, 1.0, 0.0, 0.0)            # 回転
    glRotate(@rot_y, 0.0, 1.0, 0.0)            # 回転

    # 材質を設定
    diffuse = [0.5, 0.5, 0.5, 1.0]
    specular = [0.3, 0.3, 0.3, 1.0]
    shininess = 100.0
    glMaterialfv(GL_FRONT_AND_BACK, GL_AMBIENT_AND_DIFFUSE, diffuse)
    glMaterialfv(GL_FRONT_AND_BACK, GL_SPECULAR, specular)
    glMaterialf(GL_FRONT_AND_BACK, GL_SHININESS, shininess)

    # 四角形を描画
    # ----------------------------------------

    glUseProgram(@shader)    # 利用するシェーダを指定

    glEnableClientState(GL_VERTEX_ARRAY)         # 頂点配列を有効化
    glEnableClientState(GL_NORMAL_ARRAY)         # 法線配列を有効化
    glEnableClientState(GL_TEXTURE_COORD_ARRAY)  # 法線配列を有効化

    glBindBuffer(GL_ARRAY_BUFFER, @buffers[0])  # 使用バッファを指定

    # float型(C言語)のバイト数を求める。…他にいい方法があるのでは？
    nf = [0.0].pack("f*").size
    stride = 8 * nf

    # 頂点配列を指定
    glVertexPointer(
                    3,         # 1頂点に値をいくつ使うか。x,y,zなら3
                    GL_FLOAT,  # 値の型
                    stride,    # stride. データの間隔
                    0          # バッファオフセット
                    )

    # 法線配列を指定。法線は必ずx,y,zを渡すのでサイズ指定は不要
    glNormalPointer(
                    GL_FLOAT,  # 値の型
                    stride,    # stride. データの間隔
                    3 * nf     # バッファオフセット
                    )

    # uv配列を指定
    glTexCoordPointer(
                      2,         # 1頂点に値をいくつ使うか。u,vなら2
                      GL_FLOAT,  # 値の型
                      stride,    # stride. データの間隔
                      6 * nf     # バッファオフセット
                      )

    glEnable(GL_TEXTURE_2D)                          # テクスチャ有効化
    glBindTexture(GL_TEXTURE_2D, @texinfo.tex_name)  # テクスチャ割り当て

    # テクスチャの補間を指定
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR)
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR)

    # 描画
    glDrawArrays(
                 GL_QUADS,  # プリミティブ種類
                 0,         # 開始インデックス
                 4          # 頂点数
                 )

    glDisable(GL_TEXTURE_2D)                      # テクスチャ無効化

    glDisableClientState(GL_VERTEX_ARRAY)         # 頂点配列を無効化
    glDisableClientState(GL_NORMAL_ARRAY)         # 法線配列を無効化
    glDisableClientState(GL_TEXTURE_COORD_ARRAY)  # 法線配列を無効化
  end
end

# メインクラス
class MyWindow < Gosu::Window

  # 初期化
  def initialize
    super WIDTH, HEIGHT
    self.caption = "Ruby + Gosu + OpenGL, programmable shader (Phong) + VBO"
    @gl_obj = GlObj.new(0.0, 0.0, -2.5)
  end

  # 更新
  def update
    @gl_obj.update
  end

  # 描画
  def draw
    z = 0
    @gl_obj.draw(z)
  end

  def button_down(id)
    # ESCが押されたら終了
    close if id == Gosu::KbEscape
  end
end

MyWindow.new.show
