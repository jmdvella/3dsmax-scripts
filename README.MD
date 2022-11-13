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
  - VrayMtl, Vray2SidedMtl, Multi-Material
  - Gamma settings for sRGB and Linear images
  - Dielectric or Metal material for Blender/Cinema4D (if Metal texture used)
  - Specular level for Blender 0.5
  - Reflection to White
##### Textures
  - Diffuse, Diffuse Color & VrayColor in Diffuse
  - Roughness 
  - Metal 
  - Opacity 
  - Normal 
  - Change Normal DirectX texture with OpenGL by filename suffix example: Leather_Normal_DirectX.png -> Leather_Normal_OpenG.png
#### Scripting Note: 
Change/Add your own material settings in Function: fn convert_to_stdmtl i =    
Change your own Normal texture naming convention in JV_VrayRoughnessToFBX.ms: line 91

<br />

### JV_RoughToGloss.ms
- "Script name" in 3dsmax -> JV_RoughToGloss.ms
- Convert V-Ray Roughness Materials to V-Ray Glossiness Materials
- Change Roughness texture with Glossiness by filename suffix example: Leather_Roughness.png -> Leather_Glossiness.png
- Metal materials: Move Diffuse texture -> Reflection node, Diffuse color: black, Fresnel reflections: off 
- Legacy tool - Convert V-Ray Roughness materials to V-Ray Glossiness -> Convert to CoronaLegacyMtl
#### Scripting Note: 
Change your own Roughness texture naming convention in JV_RoughToGloss.ms: line 28

