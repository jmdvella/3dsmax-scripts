# James Vella 3dsmax Scripts
My collection of 3dsmax scripts. Currently written for 3D Studio Max 2021.3 in Maxscript

<br />

# How to use
- Download the .ms file
- Drag/Drop the .ms file into the 3dsmax viewport
- 3dsmax Main Menu -> Customize -> Customize User Interface -> Toolbars -> Category -> Vella > "Locate the name of the script"

<br />

# Script descriptions
JV_VrayRoughnessToFBX.ms
- Convert V-Ray Roughness Materials to FBX Standard (Legacy) Materials for exporting to FBX
- Importing the FBX to Blender automatically creates a PBR materials.
- Importing the FBX to Cinema4D, use these scripts for your render engine: https://github.com/jmdvella/cinema4d-scripts
- Export FBX settings: Enable "Embed Media" to include textures in the FBX file
- You can edit the functions in the script to add more material types if you use them
- Currently supports:
  - Diffuse texture, Diffuse Color, VrayColor in Diffuse
  - Roughness texture
  - Metal texture
  - Opacity texture
  - Normal texture
  - Normal DirectX to OpenGL (3dsmax uses DirectX & Blender uses OpenGL, its done via naming convention - Optional)
  - Sets the correct Specular level for Blender
  - Sets Reflection to White
  - Sets Dielectric or Metallic material for Blender/Cinema4D (depending on if Metal texture is used)
  - Sets Gamma settings for sRGB and Linear images
  - Can convert VrayMtl, Vray2SidedMtl, Multi-Material. 

