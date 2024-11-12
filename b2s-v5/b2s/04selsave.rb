def selsave(s_path)
  model = Sketchup.active_model
  selection = model.selection

  if selection.empty?
    UI.messagebox("O.o 没选物体呢")
    return
  end

  # 定义组件名称
  component_name = "fromsu"

  # 检查路径有效性
  unless File.directory?(s_path)
    UI.messagebox("无效的保存路径：#{s_path}")
    return
  end

  # 创建新的组件定义
  definition = model.definitions.add(component_name)

  # 添加选定对象到组件定义
  selection.each do |entity|
    next if entity.hidden?  # 跳过隐藏的实体
    transformation = Geom::Transformation.new(entity.transformation.to_a)
    definition.entities.add_instance(entity.definition, transformation)
  end

  # 在原点位置添加一个代表原点的点（使用短线段）
  origin_start = Geom::Point3d.new(0, 0, 0)
  origin_end = Geom::Point3d.new(0.01, 0, 0)  # 短线段的端点
  
  # 添加一条小线段作为原点标记
  definition.entities.add_line(origin_start, origin_end)

  # 使用另存为方法
  sav_path = File.join(s_path, "#{component_name}.skp")
  
  begin
    definition.save_as(sav_path)
    UI.messagebox("组件 '#{component_name}' 原位另存在: #{sav_path}")
  rescue => e
    UI.messagebox("保存组件时发生错误: #{e.message}")
  ensure
    # 删除当前模型中的定义（可选）
    model.definitions.remove(definition) if model.definitions[component_name]
  end
end
