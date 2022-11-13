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
- You can edit the functions in the script to add more material types if you use them
#### Supports:
  - Diffuse, Diffuse Color & VrayColor in Diffuse
  - Roughness 
  - Metal 
  - Opacity 
  - Normal 
  - Normal DirectX -> OpenGL (Optional: swap textures by naming convention, example: Leather_Normal_DirectX.png -> Leather_Normal_OpenG.png)
  - Set Specular level for Blender 0.5
  - Set Reflection to White
  - Set Dielectric or Metallic material for Blender/Cinema4D (if Metal texture is used)
  - Set Gamma settings for sRGB and Linear images
  - Can convert VrayMtl, Vray2SidedMtl, Multi-Material. 

<br />

### JV_RoughToGloss.ms
- "Script name" in 3dsmax -> JV_RoughToGloss.ms
- Convert V-Ray Roughness Materials to V-Ray Glossiness Materials
- Swaps Roughness materials with Glossiness by file naming suffix, example: Leather_Roughness.png -> Leather_Glossiness.png
- Metal materials: Move Diffuse texture -> Reflection node, Diffuse color:black, Fresnel reflections:off 
- Legacy tool - Convert V-Ray Roughness materials to V-Ray Glossiness -> Convert to CoronaLegacyMtl



