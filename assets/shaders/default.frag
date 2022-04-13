#version 330 core

layout(location = 0) out vec4 color;


// Phong Lighting.
struct Material {
  vec3 ambient;
  vec3 diffuse;
  vec3 specular;

  float shininess;
};

struct Light {
  vec3 ambient;
  vec3 diffuse;
  vec3 specular;

  vec3 position;
};

in vec3 out_normal;
in vec3 out_frag;

uniform vec3 view_position;
uniform Material material;
uniform Light light;

void main() {
  
  // Ambient
  vec3 ambient = light.ambient * material.ambient;

  // Diffuse
  vec3 normal = normalize(out_normal);
  vec3 light_direction = normalize(light.position - out_frag);
  vec3 diffuse = light.diffuse * (max(dot(normal, light_direction), 0.0) * material.diffuse);

  // Specular
  vec3 view_direction = normalize(view_position - out_frag);
  vec3 reflection_direction = reflect(-light_direction, normal);
  vec3 specular = light.specular * (pow(max(dot(view_direction, reflection_direction), 0.0), material.shininess) * material.specular);

  vec3 lighting = ambient + diffuse + specular;
  color = vec4(lighting, 1.0);
}