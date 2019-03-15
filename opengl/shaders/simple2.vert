#version 120
void main(void)
{
  vec4 position = gl_ModelViewMatrix * gl_Vertex;
  vec3 normal = normalize(gl_NormalMatrix * gl_Normal);
  vec3 light = normalize((gl_LightSource[0].position * position.w - gl_LightSource[0].position.w * position).xyz);
  float diffuse = max(dot(light, normal), 0.0);

  gl_FrontColor = gl_LightSource[0].diffuse * gl_FrontMaterial.diffuse * diffuse;
  gl_Position = ftransform();
}
