package engine_gui

import imgui  "shared:odin-imgui"
import imgl   "shared:odin-imgui/impl/opengl"
import imglfw "shared:odin-imgui/impl/glfw"
import ws "../window"

Engine_Gui :: struct {
  state: imgl.OpenGL_State,
}

create :: proc(window: ws.Window) -> (engine_gui: Engine_Gui) {
  imgui.create_context()
  imgui.style_colors_dark()
  imglfw.setup_state(window.window_handle, true)
  imgl.setup_state(&engine_gui.state)

  return
}

destroy :: proc() {

}

update :: proc() {
  imglfw.update_dt()
  imglfw.update_display_size()
}

update_mouse :: proc() {
  imglfw.update_mouse()
}

render :: proc(using engine_gui: Engine_Gui) {
  imgui.render()
  imgl.imgui_render(imgui.get_draw_data(), state)
}