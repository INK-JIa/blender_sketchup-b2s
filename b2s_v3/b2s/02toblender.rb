def to_blender
  require 'sketchup'
  require 'fileutils'

  def extract_to_root(selection)
    extracted_entities = []

    selection.each_with_index do |entity, index|
      next if entity.hidden? # 跳过隐藏的实体

      # 如果实体在根层级，则跳过克隆
      next if entity.parent == Sketchup.active_model # 检查父层是否为模型本身

      # 克隆选定的实体并将其放入根层级
      new_entity = nil
      if entity.is_a?(Sketchup::ComponentInstance) || entity.is_a?(Sketchup::Group)
        new_entity = Sketchup.active_model.entities.add_instance(entity.definition, entity.transformation)
      elsif entity.is_a?(Sketchup::Face)
        new_entity = Sketchup.active_model.entities.add_face(entity.vertices.map(&:position))
      else
        next # 跳过其他类型的实体
      end

      # 重命名新实体以确保唯一性
      new_entity.name = "#{entity.name}_#{index + 1}" unless entity.name.empty?

      extracted_entities << new_entity
    end

    extracted_entities
  end

  def send_to
    puts "Execute to Blender functionality."
    model = Sketchup.active_model
    selection = model.selection

    return unless selection.any?

    # 隐藏未选择的对象
    hidden_entities = []
    model.entities.each do |entity|
      if !selection.include?(entity) && entity.visible?
        entity.hidden = true
        hidden_entities << entity
      end
    end

    # 将选定对象提取到根层级
    selection_entities = extract_to_root(selection)

    # 更新选择集为新提取的实体
    model.selection.clear # 清除当前选择
    selection_entities.each { |entity| model.selection.add(entity) }

    # 定义导出路径
    export_path = File.join(ENV['HOME'], 'Documents', 'blendsu', 'toblender.glb')

    # 确保导出路径存在
    FileUtils.mkdir_p(File.dirname(export_path))

    # 导出 GLB
    show_summary = true
    status = model.export(export_path, show_summary)

    # 恢复隐藏状态
    hidden_entities.each { |entity| entity.hidden = false }

    # 删除提取的实体
    selection_entities.each(&:erase!)

    puts "Export completed with status: #{status}"
  end

  # 调用 send_to 方法运行导出功能
  send_to
end

# 最后，调用 to_blender 方法
to_blender
