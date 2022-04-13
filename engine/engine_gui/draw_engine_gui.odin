package engine_gui

import imgui  "shared:odin-imgui"
import imgl   "shared:odin-imgui/impl/opengl"
import imglfw "shared:odin-imgui/impl/glfw"

draw_engine_gui :: proc(engine_gui: Engine_Gui) {
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
}