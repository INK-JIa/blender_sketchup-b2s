def from_blender
 puts "Execute From Blender functionality."
 model = Sketchup.active_model
 options = { :units => "model",
            :merge_coplanar_faces => true,
            :show_summary => true }
 status = model.import("blendsu/fromblender.glb", options)
end