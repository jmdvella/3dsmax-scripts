# James Vella 3dsmax Scripts
My collection of 3dsmax scripts. Currently written for 3D Studio Max 2021.3 in Maxscript

<br />

# How to use
- Download the .ms file
- Drag/Drop the .ms file into the 3dsmax viewport
- 3dsmax Main Menu -> Customize -> Customize User Interface -> Toolbars -> Category -> Vella > "Script name"

<br />

# Script descriptions
### JV_VrayRoughnessToFBX.ms
- "Script name" in 3dsmax -> Automate VrayToFBX
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

### JV_RoughToGloss.ms
- "Script name" in 3dsmax -> JV_RoughToGloss.ms
- Convert V-Ray Roughness Materials to V-Ray Glossiness Materials
- Change Roughness texture with Glossiness by filename suffix example: Leather_Roughness.png -> Leather_Glossiness.png
- Metal materials: Move Diffuse texture -> Reflection node, Diffuse color: black, Fresnel reflections: off 
- Legacy tool - Convert V-Ray Roughness materials to V-Ray Glossiness -> Convert to CoronaLegacyMtl
#### Scripting Note: 
Change your own Roughness texture naming convention: line 28

