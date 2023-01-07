/*
Author: James Vella
Website: http://www.jamesvella.net/
Name-US: JV_VrayRoughnessToFBX
Version: 1.1.0
Software: 3D Studio Max 2021.3
Engine: V-Ray 5.00.04
Language: Maxscript
Description-US: Convert Vray Roughness materials to Standard for export to FBX
*/

macroscript VrayToFBX
	category:"Vella" 
	internalcategory:"Automate"
	tooltip:"Automate VrayToFBX"
	buttonText:"Vray To FBX"
	Icon:#("SchematicView",2)

(
	-- start an undo block
	undo on

	-- Function to replace VrayMtl with StandardMtl and setup PBR settings for FBX/Blender
	fn convert_to_stdmtl i =
	(
		-- Standard Settings for PBR export
		newMat = Standardmaterial ()
		newMat.name = i.name
		newMat.diffuse = i.diffuse
		newMat.bumpMapAmount = 100
		newMat.specularLevel = 25
		
		-- Replace VrayColor with Standard Diffuse Color
		if (classof i.texmap_diffuse == VrayColor) then
		(
			newMat.diffuse = i.texmap_diffuse.color
		)
		else
		-- Replace Diffuse texture with node in Diffuse slot
		(
			if i.texmap_diffuse != undefined then
			newMat.diffusemap = i.texmap_diffuse
		)
		
		-- Remove Diffuse Falloff node (Optional) 	<--------------
		while (classof i.texmap_diffuse == falloff) do
		(
			newMat.diffusemap = i.texmap_diffuse.map1
			i.texmap_diffuse = i.texmap_diffuse.map1  -- update the value of i.texmap_diffuse
			if (classof i.texmap_diffuse != falloff) then break
		)
		
		-- Remove Diffuse Color Correction node (Optional) 	<--------------
		while (classof i.texmap_diffuse == Color_Correction) do
		(
			newMat.diffusemap = i.texmap_diffuse.map
			i.texmap_diffuse = i.texmap_diffuse.map  -- update the value of i.texmap_diffuse
			if (classof i.texmap_diffuse != Color_Correction) then break
		)
		
		-- Replace Roughness texture
		if i.texmap_reflectionGlossiness != undefined then
		(
			newMat.glossinessMap = i.texmap_reflectionGlossiness
		)
		
		-- Replace Metal texture
		if i.texmap_metalness == undefined then
		(
			newMat.reflectionMapEnable = on
			newMat.reflectionMapAmount = 0
		)
		else
		(
			newMat.reflectionMapEnable = on
			newMat.reflectionMap = i.texmap_metalness
			i.texmap_metalness.coordinates.mappingtype = 0 
		)
		
		-- Convert Metal numeric value to Reflection value
		if i.reflection_metalness != 0 then
		(
			newMat.reflectionMapEnable = on
			newMat.reflectionMapAmount = (i.reflection_metalness * 100)
		)
		
		-- Replace Opacity
		if i.texmap_opacity != undefined then
		(
			newMat.opacityMap = i.texmap_opacity
		)
		
		-- Replace Glass
		if i.Refraction != color 0 0 0 then
		(
			newMat.opacity = 50
		)
		
		-- Replace Normal texture
		if i.texmap_bump != undefined then
		(
			if (classof i.texmap_bump == VRayNormalMap) then
			(
				newMat.bumpMap = i.texmap_bump.normal_map
			)
			else 
			(
				newMat.bumpMap = i.texmap_bump
			)
		)
		
		-- Convert DirectX Normal texture to OpenGL (Optional) 	<--------------
		try
		(
			if i.texmap_bump != undefined then
			(
				i.texmap_bump.normal_map.filename = substituteString i.texmap_bump.normal_map.filename "DirectX" "OpenGL"
			)
		)
		catch()
		
		-- Convert VrayMtl to StandardMtl
		i = newMat
	)
		
	-- Add VrayMtl Classes below for conversion

	-- Convert VRay2SidedMtl to VrayMtl
	vrayMtlList = getClassInstances VRay2SidedMtl
	for i in vrayMtlList do
		(
			-- Replace VRay2SidedMtl with Front material
			newMat = i.frontMtl 
			p = newMat
			replaceinstances i p
		)

	-- Convert VrayMtl to Standard material (This should always be last after converting other VrayMtl classes to VrayMtl)
	vrayMtlList = getClassInstances VRayMtl
	for i in vrayMtlList do
		(
			p = convert_to_stdmtl i
			if (i.name == p.name) and (i.name != undefined) do
			(
				replaceinstances i p
			)
		)
		
	-- end the undo block
	undo off

	-- refresh asset tracker
	ATSOps.Refresh()
)
