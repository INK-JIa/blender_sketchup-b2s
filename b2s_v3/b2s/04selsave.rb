def selsave
  model = Sketchup.active_model
  selection = model.selection

  return UI.messagebox("O.o没选物体呢") if selection.empty?

  # 定义组件名称
  component_name = "fromsu"

  # 创建新的组件定义
  definition = model.definitions.add(component_name)

  # 添加选定对象到组件定义
  selection.each do |entity|
    transformation = Geom::Transformation.new(entity.transformation.to_a)
    definition.entities.add_instance(entity.definition, transformation)
  end

  # 在原点位置添加一个代表原点的点（使用短线段）
  origin_start = Geom::Point3d.new(0, 0, 0)
  origin_end = Geom::Point3d.new(0.01, 0, 0)  # 短线段的端点
  
  # 添加一条小线段作为原点标记
  definition.entities.add_line(origin_start, origin_end)

  # 保存该组件到指定的文件夹
  blendsu_folder = File.join(Dir.home, 'Documents', 'blendsu')
  Dir.mkdir(blendsu_folder) unless Dir.exist?(blendsu_folder)

  file_path = File.join(blendsu_folder, "#{component_name}.skp")

  begin
    # 使用另存为方法
    definition.save_as(file_path)
    UI.messagebox("组件 '#{component_name}' 原位另存在: #{file_path}")
  rescue => e
    UI.messagebox("Error saving component: #{e.message}")
  end

  # 删除当前模型中的定义（可选）
  model.definitions.remove(definition) if model.definitions[component_name]

end