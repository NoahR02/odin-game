package window

import gl "vendor:OpenGL"
import "vendor:glfw"
import "core:strings"
import "core:fmt"

Window :: struct {

  width:  int,
  height: int,
  title:  string,

  window_handle: glfw.WindowHandle,

}

create :: proc(width, height: int, title: string, gl_major_version: i32 = 4, gl_minor_version: i32 = 5) -> (window: Window, err: bool = false) {

  if !bool(glfw.Init()) {
    fmt.println("GLFW has failed to load.")
    err = true
    return
  }

  glfw.WindowHint(glfw.CONTEXT_VERSION_MAJOR, gl_major_version)
  glfw.WindowHint(glfw.CONTEXT_VERSION_MINOR, gl_minor_version)
  glfw.WindowHint(glfw.OPENGL_PROFILE, glfw.OPENGL_CORE_PROFILE)

  glfw_c_string_title := strings.clone_to_cstring(title)
  defer delete(glfw_c_string_title)

  window.window_handle = glfw.CreateWindow(i32(width), i32(height), glfw_c_string_title, nil, nil)
  window.width = width
  window.height = height
  window.title = strings.clone(title)

  using window

  if window_handle == nil {
    fmt.println("GLFW has failed to load the window.")
    err = true
    return
  }

  glfw.MakeContextCurrent(window_handle)
  gl.load_up_to(int(gl_major_version), int(gl_minor_version), glfw.gl_set_proc_address)
  glfw.SwapInterval(0)
  
  return window, err

}

destroy :: proc(using window: Window) {
  defer glfw.Terminate()
  defer glfw.DestroyWindow(window_handle)
  defer delete(title)
}

destroy_window_but_keep_glfw_alive :: proc(using window: ^Window) {
  defer glfw.DestroyWindow(window_handle)
}

poll_events :: proc() {
  glfw.PollEvents()
}

swap_buffers :: proc(using window: Window) {
  glfw.SwapBuffers(window_handle)
}

should_close :: proc(using window: Window) -> b32 {
  return glfw.WindowShouldClose(window_handle)
}

switch_to_rendering_on_this_window :: proc(using window: Window) {
  glfw.MakeContextCurrent(window_handle)
}