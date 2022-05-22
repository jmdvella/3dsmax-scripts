# VrayToFBX
Convert Vray Materials to FBX Standard (Legacy) Materials for exporting to FBX, Automatically creates a PBR material for Blender on import of the FBX.

Install and use: 
Drag the VrayToFBX.ms file into the 3dsmax viewport > Customize > Customize User Interface > Toolbars > Category > Vella > Automate VrayToFBX.

Script language:
Maxscript.

Function of the script:
Take Vray Roughness materials and convert them to Standard (Legacy) materials for exporting to FBX. These settings allow direct import into Blender and set up a PBR material with correct default settings.

Converts:
Diffuse texture, Diffuse Color, VrayColor in Diffuse
Roughness texture
Metal texture
Opacity texture
Normal texture
Normal DirectX to OpenGL (3dsmax uses DirectX & Blender uses OpenGL, its done via naming convention - Optional)
Sets the correct Specular level for Blender
Sets Reflection to White
Sets Dielectric or Metallic material for Blender (depending on if Metal texture is used)
Sets Gamma settings for sRGB and Linear images
Can convert VrayMtl, Vray2SidedMtl, Multi-Material. You can edit the functions in the script to add more material types if you use them

FBX Export Settings:
Enable Embed Media to include textures in the FBX file for automatic mapping in Blender.
