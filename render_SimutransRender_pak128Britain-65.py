bl_info = {
    "name": "Render Simutrans Views Pak128.Britain-refresh",
    "author": "Zeno, the Hood and James E. Petts",
    "version": (1, 5),
    "blender": (2, 6, 5),
    "api": 35853,
    "location": "Render >  Render8viewsBrit",
    "description": "Renders direction views for Simutrans",
    "warning": "",
    "wiki_url": "",
    "tracker_url": "",
    "category": "Render"}

"""
This script has two functions:

1)  Render 4 or 8 fictional views for simutrans game
    What it does is placing the camera and sun in each proper position to make
    each of the requested renders, that means the camera and sun (light) move
    around the objects in the scene, and take the proper renders.
    Ther renders are saved to disk with direction suffixes, such as _W (for west
    view), _NE (for north-east view), and so on.
2)  Enable mask mode for simutrans post processing
    This enables mask mode for the used materials in the scene. That means, the
    script searchs for every material which name starts with "sp_" (special) and
    when found applies the mask to it. The masks changes are:
    a)  Replaces sp_Dark_Wi*, sp_Cold_Wh* and sp_Red_Lig* with the mask color
        (1,0,0.5 magenta), and sets shadeless on for them.
    b)  Sets shadeless on for sp_* materials.

RECOMMENDED:
    * I recommend NOT SAVING the model after using the "Make Masks" function.
    It's much more easy to save your blend file before, then when you need to
    render the masks use the "Make Masks" function, do the renders, and then
    switch back to your blend file back.
    * Be careful when naming your materials. Everything that starts with "sp_"
    will be considered a Simutrans special color!!!!

Be sure to take a look at our Simutrans International Forum at:
http://forum.simutrans.com

You're also welcome to our IRC Chat Room, at #simutrans channel in quakenet network.


History:

v1.0
----
Basic 4/8 view rendering
Masking function for materials named sp_*
Compatibility with Blender 2.56 beta

v1.1
----
Compatibility with Blender 2.57
Several changes to the Masking funcitonality. Read description above.

v1.2
----
Correct alignments for Pak128.Britain without copying and pasting to templates.

v1.3
----
Correct direction names for Pak128.Britain (were 90 degrees off with the Pak128 version)

v1.4
----
Add choice of camera location to align bases or to align vehicles.

v1.5
----
Correct alignment of NW graphic in the "normal" view to work with aircraft

"""


import bpy
from math import radians
from bpy.props import *

class SCENE_PT_simurender(bpy.types.Panel):
    bl_space_type = "PROPERTIES"
    bl_region_type = "WINDOW"
    bl_context = "render"
    bl_label = "Rendering views for Simutrans"
    
    def draw_header(self, context):
        layout = self.layout
        
    def draw(self, context):
        layout = self.layout
        scene = context.scene
        
        row = layout.column()
        row.prop(scene, "image_name", text="Image name")
        
        row = layout.column()
        row.prop(scene, "op_list", text="Views to render")
            
        row = layout.column()
        row.operator("scene.simurender_render_views", text="Render Views")
        row = layout.column()
        row.operator("scene.simurender_make_mask", text="Make Masks")
        
class SCENE_OT_simurender_make_mask(bpy.types.Operator):
    bl_idname = "scene.simurender_make_mask"
    bl_label = "Make Mask"
    bl_options = {'REGISTER'}
    bl_description = "Swap all special colors to mask colors"
    
    @classmethod
    def poll(cls, context):
        return context.active_object != None
    
    def execute(self, context):
        for mat in bpy.data.materials:
            if mat.name[0:3] == "sp_":
                print("Making mask of " + mat.name)
                # If is window color, replace with magenta mask
                print(mat.name[3:7])
                if mat.name[3:10] == "Dark_Wi" or mat.name[3:10] == "Cold_Wh" or mat.name[3:10] == "Red_Lig":
                    mat.diffuse_color = [1.0, 0.0, 0.5]

                # Enable shadeless for primary/secondary colors
                mat.use_shadeless = True
              
        return("FINISHED")

class SCENE_OT_simurender_render_views(bpy.types.Operator):
    bl_idname = "scene.simurender_render_views"
    bl_label = "Render Simutrans Views Pak128.Britain"
    bl_options = {'REGISTER'}
    bl_description = "Render direction views for Simutrans"

    @classmethod
    def poll(cls, context):
        return context.active_object != None
    
    def execute(self, context):
        if "Camera" in bpy.data.objects:
            cam = bpy.data.objects["Camera"]
        else:
            cam = ""
            
        if "Sphere" in bpy.data.objects:
            sun = bpy.data.objects["Sphere"]
        else:
            sun = ""
        
        if cam=="":
            self.report('WARNING', "Camera not found!")
        else:
            if sun=="":
                self.report('WARNING', "Sun not found!")
            else:
                scn = bpy.context.scene
                cam.rotation_mode = "XYZ"
                name = scn.image_name
                
                # Generate the South Image
                cam.rotation_euler = [radians(60), 0, radians(45)]
                if scn.op_list == "2":
                  cam.location = [6.6, -7.9, 11.6]
                else:
                  cam.location = [10, -10, 11.6]

                sun.rotation_euler = [radians(90),0, radians(90)]
                #sun.location = [-70.711, -70.711, 60]
                scn.render.filepath = "//" + name + "_S.png"
                print("Rendering South Image")
                bpy.ops.render.render(animation=False, write_still=True, layer="", scene="")
                
                if scn.op_list != "0":
                    # Generate the South-West Image
                    cam.rotation_euler = [radians(60), 0, radians(90)]
                    if scn.op_list == "2":
                     cam.location = [7.5, 0.6, 10]
                    else:
                     cam.location = [14.14, 0, 11.6] 

                    sun.rotation_euler = [radians(90), 0, radians(135)]
                    #sun.location = [0, -100, 60]
                    scn.render.filepath = "//" + name + "_SW.png"
                    print("Rendering South-West Image")
                    bpy.ops.render.render(animation=False, write_still=True, layer="", scene="")
                    
                # Generate the West Image
                cam.rotation_euler = [radians(60), 0.0, radians(135)]
                if scn.op_list == "2":
                  cam.location = [6.72, 8.2, 11.6]
                else:
                  cam.location = [10, 10, 11.6]

                sun.rotation_euler =[radians(90),0.0,radians(180)]
                #sun.location = [70.711, -70.711, 60]
                scn.render.filepath = "//" + name + "_W.png"
                print("Rendering West Image")
                bpy.ops.render.render(animation=False, write_still=True, layer="", scene="")
                
                if scn.op_list != "0":
                    # Generate the North-West Image
                    cam.rotation_euler = [radians(60), 0.0, radians(180)]
                    if scn.op_list == "2":
                      cam.location = [0, 14.14, 11.6]
                    else:
                      cam.location = [0, 14.14, 11.6] 

                    sun.rotation_euler = [radians(90),0.0,radians(225)]
                    #sun.location = [100, 0, 60]
                    scn.render.filepath = "//" + name + "_NW.png"
                    print("Rendering North-West Image")
                    bpy.ops.render.render(animation=False, write_still=True, layer="", scene="")
                    
                # Generate the North Image
                cam.rotation_euler = [radians(60), 0.0, radians(225)]
                if scn.op_list == "2":
                  cam.location = [-7, 8.5, 11.6]
                else:
                  cam.location = [-10, 10, 11.6]

                sun.rotation_euler = [radians(90),0.0,radians(270)]
                #sun.location = [70.711, 70.711, 60]
                scn.render.filepath = "//" + name + "_N.png"
                print("Rendering North Image")
                bpy.ops.render.render(animation=False, write_still=True, layer="", scene="")
                
                if scn.op_list != "0":
                    # Generate the North-East Image
                    cam.rotation_euler = [radians(60), 0.0, radians(270)]
                    if scn.op_list == "2":
                    	 cam.location = [-10.3, -0.75, 11.6]
                    else:
                      cam.location = [-14.14, 0, 11.6]

                    sun.rotation_euler = [radians(90),0.0, radians(315)]
                    #sun.location = [0, 100, 60]
                    scn.render.filepath = "//" + name + "_NE.png"
                    print("Rendering North-East Image")
                    bpy.ops.render.render(animation=False, write_still=True, layer="", scene="")
                    
                # Generate the East Image
                cam.rotation_euler = [radians(60), 0.0, radians(315)]
                if scn.op_list == "2":
                    cam.location = [-32.6, -33.6, 32.5]
                else:
                    cam.location = [-10, -10, 11.6]

                sun.rotation_euler = [radians(90),0.0,radians(0)]
                #sun.location = [-70.711, 70.711, 60]
                scn.render.filepath = "//" + name + "_E.png"
                print("Rendering East Image")
                bpy.ops.render.render(animation=False, write_still=True, layer="", scene="")
                
                if scn.op_list != "0":
                    # Generate the South-East Image
                    cam.rotation_euler = [radians(60), 0.0, radians(360)]
                    if scn.op_list == "2":
                      cam.location = [0, -11, 11.6]
                    else:
                      cam.location = [0, -14.14, 11.6]

                    sun.rotation_euler = [radians(90),0.0,radians(45)]
                    #sun.location = [-100, 0, 60]
                    scn.render.filepath = "//" + name + "_SE.png"
                    print("Rendering South-East Image")
                    bpy.ops.render.render(animation=False, write_still=True, layer="", scene="")

        return{'FINISHED'}
                    

def register():
    bpy.utils.register_module(__name__)
    
    bpy.types.Scene.image_name = StringProperty(
                                name='Image name',
                                description='Base file name for rendered images.')
    opts = []
    opts.append((str(2), "Render 8 Views vehicle alignment", str(2)))
    opts.append((str(1), "Render 8 Views normal alignment", str(1)))
    opts.append((str(0), "Render 4 Views normal alignment", str(0)))
    bpy.types.Scene.op_list = EnumProperty(
        items=opts, 
        name="Number of views", 
        default='1', 
        description='Number of direction views to be rotated and rendered')
    
def unregister():
    bpy.utils.unregister_module(__name__)
    
    del bpy.types.Scene.image_name
    
if __name__ == "__main__":
    register()
