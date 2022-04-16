package odin_game

import "core:fmt"
import gl "vendor:OpenGL"
import "core:math/linalg/glsl"
import "vendor:glfw"

import "engine/perp_camera"
import "engine"
import ws "engine/window"

import "core:mem"

import imgui  "third-party/odin-imgui"
import imgl   "third-party/odin-imgui/impl/opengl"
import imglfw "third-party/odin-imgui/impl/glfw"
import "core:strings"

GL_MAJOR_VERSION :: 4
GL_MINOR_VERSION :: 5

_main :: proc() {

  glfw.WindowHint(glfw.SAMPLES, 4)
  window, window_err := ws.create(1600, 900, "odin-game")
  defer ws.destroy(window)
  if window_err do return

  // ----------

  program, ok := gl.load_shaders("assets/shaders/default.vert", "assets/shaders/default.frag");
  if !ok {
    fmt.println("Failed to load shaders.")
  }
  defer gl.DeleteProgram(program)

  // Cube 1
  vao: u32
  vbo: u32
  gl.GenVertexArrays(1, &vao)
  gl.GenBuffers(1, &vbo)
  defer gl.DeleteVertexArrays(1, &vao)
  defer gl.DeleteBuffers(1, &vbo)

  gl.BindVertexArray(vao)
  gl.BindBuffer(gl.ARRAY_BUFFER, vbo)

  gl.BufferData(gl.ARRAY_BUFFER, len(engine.vertices) * size_of(f32), raw_data(engine.vertices[:]), gl.DYNAMIC_DRAW)

  gl.EnableVertexAttribArray(0)
  gl.VertexAttribPointer(0, 3, gl.FLOAT, false, size_of(f32) * 6, 0)

  gl.EnableVertexAttribArray(1)
  gl.VertexAttribPointer(1, 3, gl.FLOAT, false, size_of(f32) * 6, size_of(f32) * 3)
  //

  // Light Cube

  light_program, light_ok := gl.load_shaders("assets/shaders/default.vert", "assets/shaders/light.frag");
  if !light_ok {
    fmt.println("Failed to load shaders.")
  }
  defer gl.DeleteProgram(light_program)


  light_vao: u32
  light_vbo: u32
  gl.GenVertexArrays(1, &light_vao)
  gl.GenBuffers(1, &light_vbo)
  defer gl.DeleteVertexArrays(1, &light_vao)
  defer gl.DeleteBuffers(1, &light_vbo)

  gl.BindVertexArray(light_vao)
  gl.BindBuffer(gl.ARRAY_BUFFER, light_vbo)

  gl.BufferData(gl.ARRAY_BUFFER, len(engine.vertices) * size_of(f32), raw_data(engine.vertices[:]), gl.DYNAMIC_DRAW)

  gl.EnableVertexAttribArray(0)
  gl.VertexAttribPointer(0, 3, gl.FLOAT, false, size_of(f32) * 6, 0)

  light_position := glsl.vec3{5, 2, 1}
  light_model := glsl.mat4Translate(light_position)
  light_model = light_model * glsl.mat4Scale({0.5, 0.5, 0.5})

  camera: perp_camera.Camera
  perp_camera.create(&camera, {1600, 900}, {0, 0, 10})
  defer perp_camera.destroy(&camera)

  // ----------

  gl.Enable(gl.MULTISAMPLE)  

  delta_time: f64
  frame_time: f64

  for !ws.should_close(window) {
    current := glfw.GetTime()
    delta_time = current - frame_time
    frame_time = current

    // Process all incoming events like keyboard press, window resize, and etc.
    ws.poll_events()
    perp_camera.handle_input(&camera, window.window_handle, delta_time)

    // Clear the screen.
    gl.ClearColor(42.0/255, 75.0/255, 92.0/255, 1.0)
    gl.Enable(gl.DEPTH_TEST)
    gl.Clear(gl.COLOR_BUFFER_BIT | gl.DEPTH_BUFFER_BIT)

    glfw.SetInputMode(window.window_handle, glfw.CURSOR, glfw.CURSOR_DISABLED)

    // Draw Scene
    gl.BindVertexArray(vao)
    gl.UseProgram(program)
        
    // Light
    gl.Uniform3f(gl.GetUniformLocation(program, "light.ambient"),  0.2, 0.2, 0.2)
    gl.Uniform3f(gl.GetUniformLocation(program, "light.diffuse"),  0.5, 0.5, 0.5)
    gl.Uniform3f(gl.GetUniformLocation(program, "light.specular"), 1.0, 1.0, 1.0)
    gl.Uniform3f(gl.GetUniformLocation(program, "light.position"), light_position.x, light_position.y, light_position.z)

    // Material
    gl.Uniform3f(gl.GetUniformLocation(program, "material.ambient"),  1.0, 0.5, 0.31)
    gl.Uniform3f(gl.GetUniformLocation(program, "material.diffuse"),  1.0, 0.5, 0.31)
    gl.Uniform3f(gl.GetUniformLocation(program, "material.specular"), 0.5, 0.5, 0.5)
    gl.Uniform1f(gl.GetUniformLocation(program, "material.shininess"), 32.0)

    // View Position
    gl.Uniform3f(gl.GetUniformLocation(program, "view_position"), camera.position.x, camera.position.y, camera.position.z)

    
    gl.UniformMatrix4fv(gl.GetUniformLocation(program, "u_projection"), 1, gl.FALSE, &camera.projection[0][0])
    gl.UniformMatrix4fv(gl.GetUniformLocation(program, "u_view"), 1, gl.FALSE, &camera.view[0][0])
    identity := glsl.identity(glsl.mat4)
    gl.UniformMatrix4fv(gl.GetUniformLocation(program, "u_model"), 1, gl.FALSE, &identity[0][0])

    gl.DrawArrays(gl.TRIANGLES, 0, 36)

    gl.UseProgram(light_program)
    gl.BindVertexArray(light_vao)
    gl.UniformMatrix4fv(gl.GetUniformLocation(light_program, "u_projection"), 1, gl.FALSE, &camera.projection[0][0])
    gl.UniformMatrix4fv(gl.GetUniformLocation(light_program, "u_view"), 1, gl.FALSE, &camera.view[0][0])
    gl.UniformMatrix4fv(gl.GetUniformLocation(light_program, "u_model"), 1, gl.FALSE, &light_model[0][0])
    gl.DrawArrays(gl.TRIANGLES, 0, 36)
    // End Scene

    
    ws.swap_buffers(window)
  }

}

main :: proc() {

  track: mem.Tracking_Allocator
  mem.tracking_allocator_init(&track, context.allocator)
  context.allocator = mem.tracking_allocator(&track)
  _main()
 
  for _, v in track.allocation_map {
    fmt.eprintf("%v Leaked %v bytes.", v.location, v.size)
  }
 
  for v in track.bad_free_array {
    fmt.eprintf("%v Bad free.", v.location)
  }
 
}