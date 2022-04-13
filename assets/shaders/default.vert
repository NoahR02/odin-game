#version 330 core

layout(location = 0) in vec3 xyz;
layout(location = 1) in vec3 normal;

uniform mat4 u_model;
uniform mat4 u_view;
uniform mat4 u_projection;

out vec3 out_normal;
out vec3 out_frag;

void main() {
  out_normal = mat3(transpose(inverse(u_model))) * normal;
  out_frag = vec3(u_model * vec4(xyz, 1.0));
  gl_Position = u_projection * u_view * u_model * vec4(xyz, 1.0);
}