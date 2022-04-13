package perp_camera
import "core:math/linalg/glsl"
import "core:fmt"
import "vendor:glfw"

y: glsl.vec3 : {0.0, 1.0, 0.0}

Camera :: struct {

  size: glsl.vec2,
  position: glsl.vec3,
  direction: glsl.vec3,

  fov: f32,
  near_clip: f32,
  far_clip: f32,

  pointing_at: glsl.vec3,

  view: glsl.mat4,
  projection: glsl.mat4,

  speed: f32,
  euler: glsl.vec3,

  up: glsl.vec3,
  right: glsl.vec3,

  internal_last_x: f64,
  internal_last_y: f64,
  internal_first: bool,

}

create :: proc(camera: ^Camera, size: glsl.vec2, position: glsl.vec3 = {}, fov: f32 = 45.0, near_clip: f32 = 0.1, far_clip: f32 = 100.0, pointing_at: glsl.vec3 = {0.0, 0.0, 0.0}) {

  camera.size = size
  camera.position = position
  camera.fov = fov
  camera.near_clip = near_clip
  camera.far_clip = far_clip
  camera.pointing_at = {0.0, 0.0, -1.0}
  camera.speed = 15.0

  camera.euler.x = -90.0

  camera.internal_last_x = f64(size.x / 2.0)
  camera.internal_last_y = f64(size.y / 2.0)
  camera.internal_first = true

  recalculate(camera)

}

recalculate :: proc(camera: ^Camera) {
  
  euler: glsl.vec2 = {glsl.radians(camera.euler.x), glsl.radians(camera.euler.y)}

  direction: glsl.vec3 = {
    glsl.cos(euler.x) * glsl.cos(euler.y),
    glsl.sin(euler.y),
    glsl.sin(euler.x) * glsl.cos(euler.y),
  }
  camera.pointing_at = glsl.normalize(direction)

  camera.right = glsl.normalize(glsl.cross(camera.pointing_at, y))
  camera.up = glsl.normalize(glsl.cross(camera.right, camera.pointing_at))

  camera.projection = glsl.mat4Perspective(camera.fov, camera.size.x / camera.size.y, camera.near_clip, camera.far_clip)
  camera.view = glsl.mat4LookAt(camera.position, camera.position + camera.pointing_at, camera.up)
}

handle_input :: proc(camera: ^Camera, window: glfw.WindowHandle, delta_time: f64) {

  speed := camera.speed * f32(delta_time)

  if glfw.GetKey(window, glfw.KEY_ESCAPE) == glfw.PRESS {
    glfw.SetWindowShouldClose(window, true)
  }

  if glfw.GetKey(window, glfw.KEY_W) == glfw.PRESS {
    camera.position += speed * camera.pointing_at
  }

  if glfw.GetKey(window, glfw.KEY_A) == glfw.PRESS {
    camera.position -= glsl.normalize(glsl.cross(camera.pointing_at, camera.up)) * speed
  }

  if glfw.GetKey(window, glfw.KEY_S) == glfw.PRESS {
    camera.position -= speed * camera.pointing_at
  }
  
  if glfw.GetKey(window, glfw.KEY_D) == glfw.PRESS {
    camera.position += glsl.normalize(glsl.cross(camera.pointing_at, camera.up)) * speed
  }

  x, y := glfw.GetCursorPos(window)

  if camera.internal_first {
    camera.internal_last_x = x
    camera.internal_last_y = y
    camera.internal_first = false
  }

  offset: glsl.vec2 = {f32(x - camera.internal_last_x), f32(camera.internal_last_y - y)}
  camera.internal_last_x = x
  camera.internal_last_y = y

  offset *= 0.1
  camera.euler.x += offset.x
  camera.euler.y += offset.y

  if camera.euler.y > 89.0 {
    camera.euler.y = 89.0
  } else if camera.euler.y < -89.0 {
    camera.euler.y = -89.0
  }

  recalculate(camera)

}

destroy :: proc(camera: ^Camera) {
  
}