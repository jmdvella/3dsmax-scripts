# James Vella 3dsmax Scripts
My collection of 3dsmax scripts. Currently written for 3D Studio Max 2021.3 in Maxscript

<br />

# How to use
- Download the .ms file
- Drag/Drop the .ms file into the 3dsmax viewport
- 3dsmax Main Menu -> Customize -> Customize User Interface -> Toolbars -> Category -> Vella > "Script name"

<br />

# Script descriptions

### JV_CameraClipping.ms
- Toggle for Physical Camera clipping 0, 100, 200, 300, off

<br />

### JV_CameraVerticalTilt.ms
- Toggle Camera Vertical Tilt on/off

<br />

### JV_CoronaToPhysical.ms
- Convert Corona Physical to Autodesk Physical materials
#### Notes:
- Applies conversion scene wide, not on selected objects.
#### Supports:
##### Materials
- Corona Physical
##### Textures
- Base Color
- Roughness or Glossiness
- Anisotropy Amount / Rotation (hopefully, might need further testing as I have my doubts)
- IOR
- Metal
- Refraction (could be incorrect, still trying to work out how this works in Autodesk Physical)
- Thin Shell
- Opacity
- Emission / Self-Illumination
- Normal / Bump
- Normal_Bump, when 'add gamma' is used and texture is loaded as 2.2, automatically applies gamma 1.0 to Physical Normal_Bump texture
- Displacement
- Clearcoat Amount / Roughness / Bump / IOR
- Numerical values such as Base Color Amount, Roughness Amount, IOR value etc.
- Color swatches such as Base Color, Self-Illumination etc.
- Corona Bitmap to Standard Bitmap conversion
- All bitmap settings copied from Corona Bitmap (excluding the Output Curves)
- Keeps all nodes in the hierarchy eg. Diffuse > Falloff > Basecolor.png or Composite nodes etc. Doesnt really matter how deep the hierarchy goes it just searches for the Bitmaps/CoronaBitmaps

<br />

### JV_CoronaToPhysicalBitmapsOnly.ms
- Convert Corona Physical to Autodesk Physical materials
#### Notes:
- This one differs from JV_CoronaToPhysical.ms as it strips the whole hierarchy to find the bitmap. So removes all falloff/mix/coronamix etc nodes and just puts the bitmap into the associated Physical material slot.
- Applies conversion scene wide, not on selected objects.
- Use one script or the other since the macro is the same, running the script will replace the other one. 

<br />

### JV_CreateVraySun.ms
- Toggle Camera Vertical Tilt on/off

<br />

### JV_ModifiersExample.ms
- Example of how to create a modifier so that it doesnt give you fail warnings (like applying a loft to an editable polygon).

<br />

### JV_ObjToFBX.ms
- Exports selected objects to FBX
- Export folder is Documents\3dsmax (your version)\export

<br />

### JV_PhysicalToCorona.ms
- Convert Autodesk Physical to Corona Physical materials
#### Notes:
- Applies conversion scene wide, not on selected objects
- Gamma 2.2 for Diffuse, Gamma 1.0 for all other textures
- If Metal texture used then Corona Physical Material switches Metalness to 'Metal'
- Note about Glossiness: Due to the nature of Autodesk Physical Material using both Roughness & Glossiness instead of just Roughness or Glossiness in Physical Corona Materials it will switch to either Roughness or Glossiness based on your Reflection selection. Since this has an effect on Sheen and Clearcoat your textures and values will be inverted to suit whichever workflow you have selected in the Autodesk Physical Material
- Converts to Bitmap not CoronaBitmap - if you want to convert to CoronaBitmap you can use the Official Corona Converter after running this script.
#### Supports:
##### Materials
- Autodesk Physical
##### Textures
- Diffuse 
- Glossiness and Roughness
- Opacity
- Metal
- Normal / Bump
- Displacement
- IOR
- Anisotropy Amount / Rotation (remove due to how different 3dsmax version handles anisotropy).
- Emission / Self Illumination
- Clearcoat Amount / Roughness / Bump / IOR (but not Absorption as this behaves differently in Corona)
- Numerical values such as Base Color Amount, Roughness Amount, IOR value etc.
- Color swatches such as Base Color, Self-Illumination etc.

<br />

### JV_Rotate180X.ms
- Rotate object 180 degrees on the X axis

<br />

### JV_Rotate180Z.ms
- Rotate object 180 degrees on the Z axis

<br />

### JV_RoughToGloss.ms
- Convert V-Ray Roughness Materials to V-Ray Glossiness Materials
- Change Roughness texture with Glossiness by filename suffix example: Leather_Roughness.png -> Leather_Glossiness.png
- Metal materials: Move Diffuse texture -> Reflection node, Diffuse color: black, Fresnel reflections: off 
- Legacy tool - Convert V-Ray Roughness materials to V-Ray Glossiness -> Convert to CoronaLegacyMtl
#### Scripting Note: 
Change your own Roughness texture naming convention: line 28

<br />

### JV_ShowShadedInViewport.ms
- Show Shaded Mtl In Viewport for selected objects (Vray only)
- Targets the Diffuse texture at the bottom of a hierarchy (for example can sort through color correct / falloff/ mix / composite etc. to find the diffuse texture.
- If using Opacity then defaults to the Material instead so you can see the opacity in viewport.
- Supports Bitmap & VrayBitmap.
- Sets the current viewport to Shaded & Standard

<br />

### JV_ShowShadedInViewportCorona.ms
- Show Shaded Mtl In Viewport for selected objects (Corona only)
- Targets the Diffuse texture at the bottom of a hierarchy (for example can sort through color correct / falloff/ mix / composite etc. to find the diffuse texture.
- If using Opacity then defaults to the Material instead so you can see the opacity in viewport.
- Supports Corona Legacy Mtl, Corona Physical Mtl, Corona Bitmap and Bitmap.

<br />

### JV_SubdivToggle.ms
- Toggle Subdivision Modifier on/off based on render iterations
- So if viewport iters = 0, render iters = 2, toggles the viewport to 2 and then back off

<br />

### JV_VrayRoughnessToFBX.ms
- Convert V-Ray Roughness Materials to FBX Standard (Legacy) Materials for exporting to FBX
- Importing the FBX to Blender automatically creates a PBR materials (except for glass)
- Importing the FBX to Cinema4D, use these scripts for your render engine: https://github.com/jmdvella/cinema4d-scripts
- Export FBX settings: Enable "Embed Media" to include textures in the FBX file
#### Supports:
##### Materials
  - VrayMtl, Vray2SidedMtl, VrayLightMtl, Multi/Sub-Object
  - Gamma settings for sRGB and Linear images
  - Dielectric or Metal material for Blender/Cinema4D
  - Specular level for Blender 0.5
  - Reflection to White
##### Textures
  - Diffuse, Diffuse Color & VrayColor in Diffuse
  - Roughness 
  - Metal 
  - Opacity 
  - Normal & Bump
  - Self Illumination Color & Texture
#### Scripting Note: 
- Change/Add your own material settings in Function: fn convert_to_stdmtl i =    
- Change your own Normal texture naming convention by replacing the suffix "DirectX" and "OpenGL": i.texmap_bump.normal_map.filename = substituteString i.texmap_bump.normal_map.filename "DirectX" "OpenGL"
- Change/Add your own Vray Classes below comment: -- Add VrayMtl Classes below for conversion
- Removes Falloff & Color Correction nodes, if you want to keep this remove block: -- Remove Diffuse Falloff node and Color Correction node (Optional)

<br />

### JV_VrayToBlenderGLB.ms
- You can watch the [youtube video](https://youtu.be/3L2XOsLHqto) for detailed instructions.
- Convert V-Ray Roughness Materials to FBX Standard (Legacy) Materials for exporting to FBX 
- Automatically locates any file that has "Occlusion" and "Ambient" or "AO" in the same directory as the Roughness texture and places this in the specular channel.
- The specular is not the AO channel, however the blender python script will convert this to Occlusion for GLB export - this is due to FBX material support limitations.
- This script will delete all your subdivision modifiers, be aware and save your files before using it.
- This script also assumes you have set up your glass/liquid materials correctly for GLB (working correctly in Substance Painter for example). This means your AO, Opacity and Diffuse textures support opacity in realtime. 
- Install the [jv_convert_to_glb.py](https://github.com/jmdvella/blender-scripts/blob/main/jv_convert_to_glb.py) for blender and follow the install instructions [here](https://github.com/jmdvella/blender-scripts)
- Import the FBX to Blender and run the jv_convert_to_glb.py script

<br />

### JV_VrayToGLB.ms
- Convert V-Ray Roughness Materials to Autodesk glTF materials, ready for export directly from 3dsmax 2024.
- Automatically locates any file that has "Occlusion" and "Ambient" or "AO" in the same directory as the Diffuse texture.
- This script will delete all your subdivision modifiers, be aware and save your files before using it.
- This script also assumes you have set up your glass/liquid materials correctly for GLB (working correctly in Substance Painter for example). This means your AO, Opacity and Diffuse textures support opacity in realtime. 
- Warning: Unfortunately Autodesk will label all your textures/materials with the prefix adsk. This is currently unavoidable which is why I still use the JV_VrayToBlenderGLB.ms script instead. However if this doesnt bother you then its much faster this way. 
