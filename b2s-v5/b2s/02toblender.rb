require 'sketchup'
require 'fileutils'

def extract_to_root(selection)
  extracted_entities = []

  selection.each_with_index do |entity, index|
    next if entity.hidden? # 跳过隐藏的实体
    next if entity.parent == Sketchup.active_model # 检查父层是否为模型本身

    new_entity = nil
    if entity.is_a?(Sketchup::ComponentInstance) || entity.is_a?(Sketchup::Group)
      new_entity = Sketchup.active_model.entities.add_instance(entity.definition, entity.transformation)
    elsif entity.is_a?(Sketchup::Face)
      new_entity = Sketchup.active_model.entities.add_face(entity.vertices.map(&:position))
    else
      next # 跳过其他类型的实体
    end

    new_entity.name = "#{entity.name}_#{index + 1}" unless entity.name.empty?
    extracted_entities << new_entity
  end

  extracted_entities
end

def to_blender(e_path)
  puts "Execute to Blender functionality."
  
  # 检查指定路径是否有效
  unless File.directory?(e_path)
    puts "Error: The directory #{e_path} does not exist."
    UI.messagebox("无效目录：#{e_path}")
    return
  end
  
  model = Sketchup.active_model
  selection = model.selection
  return unless selection.any?

  hidden_entities = []
  model.entities.each do |entity|
    if !selection.include?(entity) && entity.visible?
      entity.hidden = true
      hidden_entities << entity
    end
  end

  selection_entities = extract_to_root(selection)

  model.selection.clear
  selection_entities.each { |entity| model.selection.add(entity) }

  export_path = File.join(e_path, 'toblender.glb')

  begin
    # 导出 GLB
    show_summary = true
    status = model.export(export_path, show_summary)

    if status
      puts "Export completed successfully."
      UI.messagebox("成功导出到：#{export_path}")
    else
      puts "Export failed."
      UI.messagebox("导出失败，请检查模型设置和路径。")
    end
  rescue => e
    puts "An error occurred during export: #{e.message}"
    UI.messagebox("导出时发生错误：#{e.message}")
  ensure
    # 恢复隐藏状态和删除提取的实体
    hidden_entities.each { |entity| entity.hidden = false }
    selection_entities.each(&:erase!)
  end
end

# 调用 to_blender 方法，依赖于@blendsu_folder
to_blender(@blendsu_folder)
