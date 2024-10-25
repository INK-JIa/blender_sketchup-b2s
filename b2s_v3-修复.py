bl_info = {
    "name": "b2s(blender和su互导插件)",
    "blender": (4, 2, 0),
    "category": "Import-Export",
}

import bpy
from bpy.props import StringProperty, PointerProperty
import os

class SketchUpSettings(bpy.types.PropertyGroup):
    export_path: StringProperty(
        name="Export Path",
        default="//",
        subtype='DIR_PATH'
    )

class ExportToSketchUp(bpy.types.Operator):
    bl_idname = "export.send_to_sketchup"
    bl_label = "发送到 SketchUp"

    def execute(self, context):
        selected_objects = bpy.context.selected_objects
        if not selected_objects:
            self.report({'WARNING'}, "请先选择对象.")
            return {'CANCELLED'}

        export_path = context.preferences.addons[__name__].preferences.export_path
        file_path = os.path.join(export_path, "fromblender.glb")

        # 使用新的 GLTF 导出选项
        bpy.ops.export_scene.gltf(
            filepath=file_path,
            use_selection=True,
            export_format='GLB',
            export_apply=True  # 应用修改器
        )
        
        self.report({'INFO'}, f"导出至 {file_path}")
        return {'FINISHED'}

class ImportFromSketchUp(bpy.types.Operator):
    bl_idname = "import.import_su_to_blender"
    bl_label = "导入 SU 到 Blender"

    def execute(self, context):
        export_path = context.preferences.addons[__name__].preferences.export_path
        file_path = os.path.join(export_path, "toblender.glb")

        if not os.path.exists(file_path):
            self.report({'WARNING'}, "文件不存在!")
            return {'CANCELLED'}

        # 导入模型
        bpy.ops.import_scene.gltf(filepath=file_path)
        self.report({'INFO'}, f"导入自 {file_path}")

        # 获取所有导入的对象
        imported_objects = bpy.context.selected_objects
        
        # 记录空物体
        empty_objects = [obj for obj in imported_objects if obj.type == 'EMPTY']

        # 合并同一父级下的网格对象
        parent_meshes = {}
        for obj in imported_objects:
            if obj.type == 'MESH':
                if obj.parent not in parent_meshes:
                    parent_meshes[obj.parent] = []
                parent_meshes[obj.parent].append(obj)

        # 执行合并操作
        for parent, meshes in parent_meshes.items():
            if len(meshes) > 1:  # 仅当有多个网格体时合并
                bpy.ops.object.select_all(action='DESELECT')  # 先取消选择所有
                for mesh in meshes:
                    mesh.select_set(True)

                bpy.context.view_layer.objects.active = meshes[0]  # 设置第一个为活跃对象
                bpy.ops.object.join()  # 合并选中的网格对象
        
        # 选择记录的空物体及其子集
        bpy.ops.object.select_all(action='DESELECT')  # 先取消选择
        for empty in empty_objects:
            empty.select_set(True)  # 选择空物体
            for child in empty.children:
                child.select_set(True)  # 选择空物体下的所有子物体
        
        # 清除选择的合并后的对象的父级并保持变换
        newly_selected_objects = bpy.context.selected_objects
        for obj in newly_selected_objects:
            if obj.parent:
                bpy.ops.object.parent_clear(type='CLEAR_KEEP_TRANSFORM')

        # 删除记录的空物体
        for empty in empty_objects:
            if empty.name in bpy.data.objects:
                bpy.data.objects.remove(bpy.data.objects[empty.name], do_unlink=True)

        # 设置材质折射率（IOR）为1.5
        default_ior = 1.5
        for mat in bpy.data.materials:
            if mat.use_nodes:
                for node in mat.node_tree.nodes:
                    if node.type == 'BSDF_PRINCIPLED':
                        node.inputs['IOR'].default_value = default_ior

        return {'FINISHED'}

class SketchUpPanel(bpy.types.Panel):
    bl_label = "SketchUp 导入导出"
    bl_idname = "PANEL_PT_sketchup"
    bl_space_type = 'VIEW_3D'  
    bl_region_type = 'UI'       
    bl_category = 'SketchUp'    

    def draw(self, context):
        layout = self.layout
        layout.operator("export.send_to_sketchup")
        layout.operator("import.import_su_to_blender")

class SketchUpSettingsPanel(bpy.types.AddonPreferences):
    bl_idname = __name__

    export_path: StringProperty(
        name="Export Path",
        default="//",
        subtype='DIR_PATH'
    )

    def draw(self, context):
        layout = self.layout
        layout.prop(self, "export_path", text="Export Path")

def register():
    bpy.utils.register_class(SketchUpSettings)
    bpy.types.Preferences.sketchup_settings = PointerProperty(type=SketchUpSettings)

    bpy.utils.register_class(ExportToSketchUp)
    bpy.utils.register_class(ImportFromSketchUp)
    bpy.utils.register_class(SketchUpPanel)
    bpy.utils.register_class(SketchUpSettingsPanel)

def unregister():
    bpy.utils.unregister_class(SketchUpSettingsPanel)
    bpy.utils.unregister_class(SketchUpPanel)
    bpy.utils.unregister_class(ImportFromSketchUp)
    bpy.utils.unregister_class(ExportToSketchUp)
    del bpy.types.Preferences.sketchup_settings
    bpy.utils.unregister_class(SketchUpSettings)

if __name__ == "__main__":
    register()
