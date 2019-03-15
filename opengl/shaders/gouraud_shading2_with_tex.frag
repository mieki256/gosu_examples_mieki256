#version 120

// gouraud_shading2_with_tex.frag

uniform sampler2D texture;

void main (void)
{
  vec4 color = texture2DProj(texture, gl_TexCoord[0]);
  gl_FragColor = color * gl_Color;
}
