# b2s.rb

# Plugin Name: b2s
# Author: 墨水
# Version: 1.0.5
# Description: 插件可以实现与blender的模型互相传输，视频说明在https://www.bilibili.com/video/BV1NPmPYCE79
# Copyright: © 2024 免费插件不得售卖

require 'sketchup.rb'
require 'extensions.rb'

# 创建编码块以定义扩展
module MyPlugin
  # 插件名称
  PLUGIN_NAME = "b2s(blender与su互导插件)"
  # 插件版本
  VERSION = "1.0.5"
  
  # 创建新的扩展类
  extension = SketchupExtension.new(PLUGIN_NAME, 'b2s')

  # 设置扩展的属性
  extension.description = "插件完全免费,可以实现与blender的模型互相传输,视频说明在https://www.bilibili.com/video/BV1NPmPYCE79"
  extension.version = VERSION
  extension.creator = "墨水er"
  
  # 将扩展注册到扩展管理器
  Sketchup.register_extension(extension, true)
end

# 定义配置文件路径
CONFIG_FILE = File.join(Dir.pwd, 'b2s_config.txt') unless defined?(CONFIG_FILE)
puts "配置文件路径: #{CONFIG_FILE}"  # 调试输出
# 将 default_path 设定为 nil，而不是空字符串以避免误判
@blendsu_folder = File.join(Dir.pwd)

# 加载存储路径
def load_directory
  if File.exist?(CONFIG_FILE)
    folder_path = File.read(CONFIG_FILE).strip 
    puts "加载路径: '#{folder_path}'"
    unless folder_path.empty?
      @blendsu_folder = folder_path 
      puts "设置的新路径: '#{@blendsu_folder}'"
    else
      puts "配置文件内容为空，路径未更新"
    end
  else
    puts "配置文件不存在"
  end
end


# 保存选择的目录
def save_directory(folder)
  return if folder.nil? || folder.empty?

  begin
    File.write(CONFIG_FILE, folder, mode: 'w', encoding: 'UTF-8')
    puts "成功保存路径: '#{folder}'"
  rescue Errno::EACCES => e
    puts "权限问题: #{e.message}"
  rescue IOError => e
    puts "写入错误: #{e.message}"
  rescue => e
    puts "保存路径时出错: #{e.message}"
  end
end

# 选择目录的方法
def select_directory
  chosen_folder = UI.select_directory 
  if chosen_folder && !chosen_folder.empty?
    @blendsu_folder = chosen_folder
    save_directory(@blendsu_folder)
  else
    UI.messagebox("未选择有效路径!")
  end
end

# 初始化插件
def initialize_plugin
  load_directory  # 调用加载目录方法
  if @blendsu_folder.nil? || @blendsu_folder.empty?
    UI.messagebox("当前路径无效，请选择有效的存储路径")
  else
    puts "当前路径: '#{@blendsu_folder}'"
  end
end

# 加载其他 .rb 文件
require_relative 'b2s/01fromblender.rb'
require_relative 'b2s/02toblender.rb'
require_relative 'b2s/03split.rb'
require_relative 'b2s/04selsave.rb'
require_relative 'b2s/05fromrhino.rb'
require_relative 'b2s/06comsav.rb'


# 添加菜单项或工具条
if defined?(Sketchup)
  unless file_loaded?(__FILE__)
    # 在这里执行初始化
    initialize_plugin
    file_loaded(__FILE__)
    # 在工具条或者菜单中添加功能
    menu = UI.menu("Plugins").add_submenu("b2s")

     # 添加选择路径菜单项
    menu.add_item("选择存储路径") {
      select_directory()  # 调用选择路径方法
    }

    menu.add_item("从blender导入") {
      # 替换为你的实际功能
      from_blender(@blendsu_folder)
    }
    menu.add_item("导出到blender") {
      # 替换为你的实际功能
      to_blender(@blendsu_folderh)
    }
    menu.add_item("解散嵌套组") {
      # 替换为你的实际功能
      explode_to_deepest_level()
    }
    menu.add_item("原位另存skp") {
      # 替换为你的实际功能
      selsave(@blendsu_folder)
    }
    menu.add_item("从rhino导入") {
      # 替换为你的实际功能
      from_rhino(@blendsu_folder)
    }
    menu.add_item("组件批量另存") {
      # 替换为你的实际功能
      save_selected_components()
    }

    toolbar = UI::Toolbar.new "b2s"

    # 添加 设置路径 按钮
    cmd0 = UI::Command.new("设置文件路径") {
      select_directory()  # 调用选择路径方法
    }
    cmd0.tooltip = "设置文件路径"
    cmd0.status_bar_text = "请先选择一个文件交换的路径,尽量放在c盘以外的盘,选择一个文件夹"
    cmd0.small_icon = "b2s/file.png"
    cmd0.large_icon = "b2s/file.png"
    toolbar.add_item cmd0

    # 添加 From Blender 按钮
    cmd1 = UI::Command.new("从blender导入") {
      from_blender(@blendsu_folder)  # 调用函数
    }
    cmd1.tooltip = "从blender导入"
    cmd1.status_bar_text = "导入blender中发送的对象,确保你已经在blender中点击了发送按钮"
    cmd1.small_icon = "b2s/fromblender.png"
    cmd1.large_icon = "b2s/fromblender.png"
    toolbar.add_item cmd1

    # 添加 To Blender 按钮
    cmd2 = UI::Command.new("导出所选到blender") {
      to_blender(@blendsu_folder)  # 调用函数
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
      selsave(@blendsu_folder)  # 调用函数
    }
    cmd4.tooltip = "原位另存skp"
    cmd4.status_bar_text = "注意:选择的对象必须是组或者组件；在场景位置导出选定的对象,在blender中配合sketchup_importer插件使用,可以保证导入的skp文件在场景原来的位置"
    cmd4.small_icon = "b2s/selsave.png"
    cmd4.large_icon = "b2s/selsave.png"
    toolbar.add_item cmd4

    # 添加 fromrhino 按钮
    cmd5 = UI::Command.new("从rhino导入") {
      from_rhino(@blendsu_folder)  # 调用函数
    }
    cmd5.tooltip = "从rhino导入"
    cmd5.status_bar_text = "导入rhino中发送的对象,确保你已经在rhino中点击了发送按钮"
    cmd5.small_icon = "b2s/fromrhino.png"
    cmd5.large_icon = "b2s/fromrhino.png"
    toolbar.add_item cmd5

    # 添加 comsav 按钮
    cmd6 = UI::Command.new("组件批量另存") {
      save_selected_components()  # 调用函数
    }
    cmd6.tooltip = "组件批量另存"
    cmd6.status_bar_text = "注意选择的对象要全部为组件,可以一次性将选择的组件全部另存出去"
    cmd6.small_icon = "b2s/comsav.png"
    cmd6.large_icon = "b2s/comsav.png"
    toolbar.add_item cmd6

    # 显示工具栏
    toolbar.show
    file_loaded(__FILE__)  # 标记文件已加载
  end
end
