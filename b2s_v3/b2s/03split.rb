def explode_to_deepest_level
  puts "Execute Explode to Deepest Level functionality."
  model = Sketchup.active_model
  selection = model.selection
  
  # 开始处理仅对选中的组或组件进行
  selection.to_a.each do |entity|
    next unless entity.is_a?(Sketchup::Group) || entity.is_a?(Sketchup::ComponentInstance)
    
    # 遍历并解构该实体直到达到最深层
    process_entity(entity)
  end
end

def process_entity(entity)
  # 检查是否有子实体为组或者组件
  if has_group_or_component?(entity)
    # 炸开当前实体
    exploded_entities = entity.explode
    
    exploded_entities.each do |e|
      # 如果炸开的结果中仍然有组或组件，递归继续炸开
      process_entity(e) if e.is_a?(Sketchup::Group) || e.is_a?(Sketchup::ComponentInstance)
    end
  end
end

def has_group_or_component?(entity)
  return false unless entity.respond_to?(:definition)
  
  # 检查是否包含进一步的组或组件
  entity.definition.entities.any? do |e|
    e.is_a?(Sketchup::Group) || e.is_a?(Sketchup::ComponentInstance)
  end
end
