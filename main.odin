package odin_game_engine

import "core:fmt"
import gl "vendor:OpenGL"
import "core:math/linalg/glsl"
import "vendor:glfw"

import "engine/perp_camera"
import "engine"


import imgui  "shared:odin-imgui"
import imgl   "shared:odin-imgui/impl/opengl"
import imglfw "shared:odin-imgui/impl/glfw"
import "core:strings"

GL_MAJOR_VERSION :: 4
GL_MINOR_VERSION :: 5

main :: proc() {
  
  if !bool(glfw.Init()) {
    fmt.eprintln("GLFW has failed to load.")
    return
  }

  glfw.WindowHint(glfw.SAMPLES, 4)
  window_handle := glfw.CreateWindow(1600, 900, "odin-game-engine", nil, nil)
  defer glfw.Terminate()
  defer glfw.DestroyWindow(window_handle)

  if window_handle == nil {
    fmt.eprintln("GLFW has failed to load the window.")
    return
  }

  glfw.MakeContextCurrent(window_handle)
  // Load OpenGL function pointers with the specficed OpenGL major and minor version.
  gl.load_up_to(GL_MAJOR_VERSION, GL_MINOR_VERSION, glfw.gl_set_proc_address)

  imgui_state := init_imgui(window_handle)

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
  for !glfw.WindowShouldClose(window_handle) {
    current := glfw.GetTime()
    delta_time = current - frame_time
    frame_time = current

    // Process all incoming events like keyboard press, window resize, and etc.
    glfw.PollEvents()
    perp_camera.handle_input(&camera, window_handle, delta_time)

    // Clear the screen.
    gl.ClearColor(42.0/255, 75.0/255, 92.0/255, 1.0)
    gl.Enable(gl.DEPTH_TEST)
    gl.Clear(gl.COLOR_BUFFER_BIT | gl.DEPTH_BUFFER_BIT)

    glfw.SetInputMode(window_handle, glfw.CURSOR, glfw.CURSOR_DISABLED)

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


    // Update glfw specfic info.
    imglfw.update_display_size()
    //imglfw.update_mouse()
    imglfw.update_dt()

    imgui.new_frame()

      {
        imgui.push_style_var(imgui.Style_Var.FramePadding, imgui.Vec2{12.0, 12.0})
        if imgui.begin_main_menu_bar() {
          defer imgui.end_main_menu_bar()
          imgui.pop_style_var(1)

          imgui.push_style_var(imgui.Style_Var.ItemSpacing, imgui.Vec2{20.0, 2.0})
            imgui.text_colored({20, 50, 0, 255}, "odin-game-engine")
          imgui.pop_style_var(1)

          if imgui.begin_menu("File") {
            defer imgui.end_menu()
            imgui.button("Open")
            imgui.button("Edit")
            imgui.button("Save")
          }

          if imgui.begin_menu("Help") {
            defer imgui.end_menu()
            imgui.button("Website")
          }

        }

      }
      

    imgui.end_frame()

    imgui.render()
    imgl.imgui_render(imgui.get_draw_data(), imgui_state)

    glfw.SwapBuffers(window_handle)
  }

}

init_imgui :: proc(window: glfw.WindowHandle) -> (state: imgl.OpenGL_State) {
  imgui.create_context()
  imgui.style_colors_dark()
  imglfw.setup_state(window, true)
  imgl.setup_state(&state)

  return
}
