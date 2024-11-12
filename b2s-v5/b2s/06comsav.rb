def save_selected_components
  model = Sketchup.active_model
  selection = model.selection

  return if selection.empty?

  # 检查选择的对象是否全部为组件
  unless selection.all? { |entity| entity.is_a?(Sketchup::ComponentInstance) }
    UI.messagebox("选择的对象必须全部为组件")
    return
  end

  # 让用户选择保存路径
  folder = UI.select_directory(title: "选择保存路径")
  return if folder.nil? || folder.empty?

  component_names = Hash.new(0) # 用于跟踪组件名称和计数

  selection.each do |entity|
    if entity.is_a?(Sketchup::ComponentInstance)
      base_name = entity.definition.name
      component_names[base_name] += 1
      
      # 创建一个唯一的文件名
      unique_name = "#{base_name}_#{component_names[base_name]}"
      filepath = File.join(folder, "#{unique_name}.skp")

      # 获取实例的变换信息，检查缩放比例
      transformation = entity.transformation
      scale_x = transformation.xscale
      scale_y = transformation.yscale
      scale_z = transformation.zscale

      # 如果任何缩放不同于 1.0，提示用户进行处理
      if scale_x != 1.0 || scale_y != 1.0 || scale_z != 1.0
                        
          new_definition = model.definitions.add(unique_name)

          # 保持当前的变换，同时确保适当的位置信息
          new_instance = new_definition.entities.add_instance(entity.definition, Geom::Transformation.new)

          # 应用当前的变换，并把它移到原点
          new_instance.transform!(transformation)

          # 移动新实例到原点
          translation_to_origin = Geom::Transformation.translation(Geom::Vector3d.new(-transformation.origin.x, -transformation.origin.y, -transformation.origin.z))
          new_instance.transform!(translation_to_origin)

          # 另存为新的定义
          new_definition.save_as(filepath)

          # 删除临时定义以避免重复
          model.definitions.remove(new_definition)
        
      else
        # 如果比例保持1:1:1，则直接保存定义
        new_definition = model.definitions.add(unique_name)
        new_instance = new_definition.entities.add_instance(entity.definition, Geom::Transformation.new)

        
        # 另存为新的定义
        new_definition.save_as(filepath)

        # 删除临时定义以避免重复
        model.definitions.remove(new_definition)
      end
    end
  end

  UI.messagebox("组件已保存到 #{folder}")
end
