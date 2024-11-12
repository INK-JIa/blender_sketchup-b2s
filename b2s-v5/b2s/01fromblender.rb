def from_blender(i_path)
    puts "Execute From Blender functionality."
    model = Sketchup.active_model
    options = { :units => "model",
                :merge_coplanar_faces => true,
                :show_summary => true }
  
    import_path = File.join(i_path, 'fromblender.glb')
  
    # 检查文件是否存在
    unless File.exist?(import_path)
      puts "Error: The file #{import_path} does not exist."
      UI.messagebox("无法找到文件：#{import_path}")
      return false
    end
  
    begin
      status = model.import(import_path, options)
      if status
        puts "Import successful."
        UI.messagebox("成功导入模型：#{import_path}")
      else
        puts "Import failed."
        UI.messagebox("导入失败，请检查文件格式或设置。")
      end
    rescue => e
      puts "An error occurred: #{e.message}"
      UI.messagebox("发生错误：#{e.message}")
    end
  
    return true
  end
  