def from_rhino(r_path)
    puts "Execute From Rhino functionality."
  
    # 检查路径有效性
    unless File.directory?(r_path)
      UI.messagebox("无效的Rhino文件夹路径：#{r_path}")
      return
    end
  
    model = Sketchup.active_model
    options = {
      :units => "model",
      :merge_coplanar_faces => true,
      :show_summary => true
    }
  
    rhino_file = File.join(r_path, 'fromrhino.glb')
  
    # 检查Rhino文件是否存在
    unless File.exist?(rhino_file)
      UI.messagebox("未找到Rhino文件：#{rhino_file}")
      return
    end
  
    begin
      # 导入Rhino文件
      status = model.import(rhino_file, options)
  
      if status
        puts "成功导入文件：#{rhino_file}"
        UI.messagebox("成功导入文件：#{rhino_file}")
      else
        puts "导入文件失败：#{rhino_file}"
        UI.messagebox("导入文件失败，请检查文件格式和内容。")
      end
      
    rescue => e
      UI.messagebox("导入时发生错误：#{e.message}")
    end
  end
  