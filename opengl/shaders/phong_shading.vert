#version 120

// phong_shading.vert

varying vec4 position;
varying vec3 normal;

void main(void)
{
  position = gl_ModelViewMatrix * gl_Vertex;
  normal = normalize(gl_NormalMatrix * gl_Normal);
  gl_Position = ftransform();
}
