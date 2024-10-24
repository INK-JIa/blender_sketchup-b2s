# b2s.rb

# Plugin Name: b2s
# Author: 墨水
# Version: 1.0.3
# Description: 插件可以实现与blender的模型互相传输，视频说明在https://www.bilibili.com/video/BV1NPmPYCE79
# Copyright: © 2024 免费插件不得售卖

require 'sketchup.rb'
require 'extensions.rb'

# 创建编码块以定义扩展
module MyPlugin
  # 插件名称
  PLUGIN_NAME = "b2s(blender与su互导插件)"
  # 插件版本
  VERSION = "1.0.3"
  
  # 创建新的扩展类
  extension = SketchupExtension.new(PLUGIN_NAME, 'b2s')

  # 设置扩展的属性
  extension.description = "插件完全免费,可以实现与blender的模型互相传输,视频说明在https://www.bilibili.com/video/BV1NPmPYCE79"
  extension.version = VERSION
  extension.creator = "墨水er"
  
  # 将扩展注册到扩展管理器
  Sketchup.register_extension(extension, true)
end

# 加载其他 .rb 文件
require_relative 'b2s/01fromblender.rb'
require_relative 'b2s/02toblender.rb'
require_relative 'b2s/03split.rb'
require_relative 'b2s/04selsave.rb'
require_relative 'b2s/05fromrhino.rb'

# 添加菜单项或工具条
if defined?(Sketchup)
  unless file_loaded?(__FILE__)
    # 在工具条或者菜单中添加功能
    menu = UI.menu("Plugins").add_submenu("b2s")

    menu.add_item("从blender导入") {
      # 替换为你的实际功能
      from_blender()
    }
    menu.add_item("导出到blender") {
      # 替换为你的实际功能
      to_blender()
    }
    menu.add_item("解散嵌套组") {
      # 替换为你的实际功能
      explode_to_deepest_level()
    }
    menu.add_item("原位另存skp") {
      # 替换为你的实际功能
      selsave()
    }
    menu.add_item("从rhino导入") {
      # 替换为你的实际功能
      from_rhino()
    }

    toolbar = UI::Toolbar.new "b2s"

    # 添加 From Blender 按钮
    cmd1 = UI::Command.new("从blender导入") {
      from_blender()  # 调用函数
    }
    cmd1.tooltip = "从blender导入"
    cmd1.status_bar_text = "导入blender中发送的对象,确保你已经在blender中点击了发送按钮"
    cmd1.small_icon = "b2s/fromblender.png"
    cmd1.large_icon = "b2s/fromblender.png"
    toolbar.add_item cmd1

    # 添加 To Blender 按钮
    cmd2 = UI::Command.new("导出所选到blender") {
      to_blender()  # 调用函数
    }
    cmd2.tooltip = "导出所选到blender"
    cmd2.status_bar_text = "注意:选择的对象必须是组或者组件；如果场景物体非常多,这个会很慢,建议大场景内的对象复制到新文件,或使用原位另存skp！"
    cmd2.small_icon = "b2s/toblender.png"
    cmd2.large_icon = "b2s/toblender.png"
    toolbar.add_item cmd2

    # 添加 Explode to Deepest Level 按钮
    cmd3 = UI::Command.new("解散嵌套组") {
      explode_to_deepest_level()  # 调用函数
    }
    cmd3.tooltip = "解散嵌套组"
    cmd3.status_bar_text = "无论有多少个嵌套组,每个物体只保留最后一个组"
    cmd3.small_icon = "b2s/split.png"
    cmd3.large_icon = "b2s/split.png"
    toolbar.add_item cmd3

    # 添加 selsave 按钮
    cmd4 = UI::Command.new("原位另存skp") {
      selsave()  # 调用函数
    }
    cmd4.tooltip = "原位另存skp"
    cmd4.status_bar_text = "注意:选择的对象必须是组或者组件；在场景位置导出选定的对象,在blender中配合sketchup_importer插件使用,可以保证导入的skp文件在场景原来的位置"
    cmd4.small_icon = "b2s/selsave.png"
    cmd4.large_icon = "b2s/selsave.png"
    toolbar.add_item cmd4

    # 添加 fromrhino 按钮
    cmd5 = UI::Command.new("从rhino导入") {
      from_rhino()  # 调用函数
    }
    cmd5.tooltip = "从rhino导入"
    cmd5.status_bar_text = "导入rhino中发送的对象,确保你已经在rhino中点击了发送按钮"
    cmd5.small_icon = "b2s/fromrhino.png"
    cmd5.large_icon = "b2s/fromrhino.png"
    toolbar.add_item cmd5

    # 显示工具栏
    toolbar.show
    file_loaded(__FILE__)  # 标记文件已加载
  end
end
