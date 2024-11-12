bl_info = {
    "name": "b2s(blender和su互导插件)",
    "blender": (4, 2, 0),
    "category": "Import-Export",
}

import bpy
from bpy.props import StringProperty, PointerProperty
from bpy_extras.io_utils import ExportHelper
import os

class SketchUpSettings(bpy.types.PropertyGroup):
    export_path: StringProperty(
        name="Export Path",
        default="//",
        subtype='DIR_PATH'
    )

# 按照集合导出fbx
class ExportFBXOperator(bpy.types.Operator, ExportHelper):
    bl_idname = "export.fbx_by_collection"
    bl_label = "按照集合导出FBX"
    
    # 让用户在文件对话框中选择文件名和路径
    filename_ext = ".fbx"

    def execute(self, context):
        selected_objects = context.selected_objects

        # 创建一个字典，按集合分类对象
        collections_dict = {}
        for obj in selected_objects:
            if obj.users_collection:
                collection_name = obj.users_collection[0].name
                if collection_name not in collections_dict:
                    collections_dict[collection_name] = []
                collections_dict[collection_name].append(obj)

        # 导出每个集合的对象为 FBX
        for col_name, objs in collections_dict.items():
            # 清空选中的对象以便导出特定集合
            bpy.ops.object.select_all(action='DESELECT')
            for obj in objs:
                obj.select_set(True)  # 选择当前集合中的对象

            # 设置导出文件的完整路径
            export_path = f"{self.filepath.rstrip('.fbx')}_{col_name}.fbx"
            bpy.ops.export_scene.fbx(filepath=export_path, use_selection=True)

        return {'FINISHED'}

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
    
class ImportSKP(bpy.types.Operator):
    bl_idname = "import_scene.skp_button"
    bl_label = "导入 SKP 文件"

    def execute(self, context):
        # 从 Blender 首选项中获取路径
        export_path = context.preferences.addons[__name__].preferences.export_path
        
        # 使用 os.path.join 来构建文件路径，避免手动添加反斜杠
        file_path = os.path.join(export_path, "fromsu.skp")


        # 打印以验证结果
        print(f"最终路径: {file_path}")  # 输出格式应为 C:\Users\ink\Documents\blendsu\formsu.skp

        # 检查路径存在性并执行导入操作
        if not os.path.exists(file_path):
            self.report({'WARNING'}, "文件不存在!")
            return {'CANCELLED'}

        bpy.ops.import_scene.skp(filepath=file_path)
        self.report({'INFO'}, f"成功导入自 {file_path}")
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
    bl_label = "b2s互导工具"
    bl_idname = "PANEL_PT_sketchup"
    bl_space_type = 'VIEW_3D'  
    bl_region_type = 'UI'       
    bl_category = 'b2s_tool'    

    def draw(self, context):
        layout = self.layout
        layout.operator("export.send_to_sketchup")
        layout.operator("export.fbx_by_collection")
        layout.operator("import_scene.skp_button") 
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

    bpy.utils.register_class(ImportSKP)
    bpy.utils.register_class(ExportFBXOperator)
    bpy.utils.register_class(ExportToSketchUp)
    bpy.utils.register_class(ImportFromSketchUp)
    bpy.utils.register_class(SketchUpPanel)
    bpy.utils.register_class(SketchUpSettingsPanel)

def unregister():
    bpy.utils.unregister_class(SketchUpSettingsPanel)
    bpy.utils.unregister_class(SketchUpPanel)
    bpy.utils.unregister_class(ImportFromSketchUp)
    bpy.utils.unregister_class(ExportToSketchUp)
    bpy.utils.unregister_class(ExportFBXOperator)
    bpy.utils.unregister_class(ImportSKP)
    del bpy.types.Preferences.sketchup_settings
    bpy.utils.unregister_class(SketchUpSettings)

if __name__ == "__main__":
    register()