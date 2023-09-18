/*
Author: James Vella
Website: http://www.jamesvella.net/
Name-US: JV_VrayRoughnessToFBX
Version: 2.0
Software: 3D Studio Max 2021.3
Engine: V-Ray 5.20.23
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
	
	with animate off 
	(
		-- Array to collect missing textures
		local missingTex = #()

		-- Function to replace VrayMtl with StandardMtl and setup PBR settings for FBX/Blender
		fn ConvertToStdMtl i =
		(
			-- Standard Settings for PBR export
			newMat = Standardmaterial ()
			newMat.name = i.name
			newMat.diffuse = i.diffuse
			newMat.bumpMapAmount = 100
			newMat.specularLevel = 25
			
			-- Diffuse
			if i.texmap_diffuse != undefined then
			(
				-- look for bitmap in sub-nodes such as falloff/color-correct etc.
				for found_bitmap in (getClassInstances Bitmaptexture target:i.texmap_diffuse) do 
				(
					newMat.diffuseMap = found_bitmap
				)
			)
			else
			(
				-- Add missing texture to missingTex array
				append missingTex (newMat.name as string + " - Missing: Diffuse Texture")
			)
			
			-- Roughness
			if i.texmap_reflectionGlossiness != undefined then
			(
				-- look for bitmap in sub-nodes such as falloff/color-correct etc.
				for found_bitmap in (getClassInstances Bitmaptexture target:i.texmap_reflectionGlossiness) do 
				(
					newMat.glossinessMap = found_bitmap
				)
			)
			else
			(
				-- Add missing texture to missingTex array
				append missingTex (newMat.name as string + " - Missing: Roughness Texture")
			)
			
			-- Replace Metal texture
			if i.texmap_metalness != undefined then
			(
				-- look for bitmap in sub-nodes such as falloff/color-correct etc.
				for found_bitmap in (getClassInstances Bitmaptexture target:i.texmap_metalness) do 
				(
					newMat.reflectionMap = found_bitmap
				)
				
				-- Enable Metal in Standard Material
				newMat.reflectionMapEnable = on
			)
			else
			(
				-- Disable Metal in Standard Material
				newMat.reflectionMapEnable = on
				newMat.reflectionMapAmount = 0
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
				try
				(
					-- look for bitmap in sub-nodes such as falloff/color-correct etc.
					for found_bitmap in (getClassInstances Bitmaptexture target:i.texmap_metalness) do 
					(
						newMat.opacityMap = i.texmap_opacity
					)
				)
				catch()
			)
			
			-- Replace Glass
			if (i.Refraction != color 0 0 0 and i.texmap_opacity == undefined) then
			(
				newMat.opacity = 50
			)
			
			-- Convert DirectX Normal texture to OpenGL (Optional) 	<--------------
			if i.texmap_bump != undefined then
			(
				try
				(
					i.texmap_bump.normal_map.filename = substituteString i.texmap_bump.normal_map.filename "DirectX" "OpenGL"
				)
				catch()
			)
			
			-- Replace Normal texture
			if (i.texmap_bump != undefined and classof i.texmap_bump == VRayNormalMap) then
			(
				-- look for bitmap in sub-nodes such as falloff/color-correct etc.
				for found_bitmap in (getClassInstances Bitmaptexture target:i.texmap_bump.normal_map) do 
				(
					newMat.bumpMap = i.texmap_bump.normal_map
				)
			)
			else 
			(
				try
				(
					-- Copy the texture from the bump node if no Normal texture found
					newMat.bumpMap = i.texmap_bump
				)
				catch()
			)
			
			-- Self Illumination
			if i.texmap_self_illumination != undefined then
			(
				try
				(
					-- look for bitmap in sub-nodes such as falloff/color-correct etc.
					for found_bitmap in (getClassInstances Bitmaptexture target:i.texmap_self_illumination) do 
					(
						newMat.selfillumMap = i.texmap_self_illumination
					)
					
					-- Illumination settings
					newMat.useSelfIllumColor = on
					newMat.selfIllumColor = color 255 255 255
				)
				catch()
			)
			
			if i.selfIllumination != color 0 0 0 then
			(
				newMat.useSelfIllumColor = on
				newMat.selfIllumColor = i.selfIllumination
			)
			
			-- Convert VrayMtl to StandardMtl
			i = newMat
		)
			
		-- Delete all Subdivision modifiers
		for obj in objects do
		(
			-- Check if the object has any modifiers
			if obj.modifiers.count > 0 do
			(
				-- Loop through the modifiers of the object
				for mod in obj.modifiers do
				(
					-- Check if the modifier is OpenSubdiv, TurboSmooth, or MeshSmooth
					if (mod.name == "OpenSubdiv" or mod.name == "TurboSmooth" or mod.name == "MeshSmooth") do
					(
						-- Delete the modifier
						deleteModifier obj mod
					)
				)
			)
		)

		-- Convert VRay2SidedMtl to VrayMtl
		for i in getClassInstances VRay2SidedMtl target:rootnode do
		(
			-- Replace VRay2SidedMtl with Front material
			p = i.frontMtl 
			replaceinstances i p
		)
			
		-- Convert VRayLightMtl to VrayMtl
		for i in getClassInstances VRayLightMtl target:rootnode do
		(
			-- Copy Light color to Self Illumination in VrayMtl
			p = VRayMtl()
			p.name = i.name
			p.selfIllumination = i.color
			
			-- Copy Light Color texture
			if i.texmap != undefined then
			(
				p.texmap_self_illumination = i.texmap
			)
			replaceinstances i p
		)

		-- Convert VrayMtl to Standard material (This should always be last after converting other VrayMtl classes to VrayMtl)
		for i in getClassInstances VRayMtl target:rootnode do
		(
			p = ConvertToStdMtl i
			if (i.name == p.name) and (i.name != undefined) do
			(
				replaceinstances i p
			)
		)
		
		-- Print missing textures in the MAXScript listner and prompt user about missing files
		if missingTex.count != 0 then
		(
			for i in missingTex do
			(
				print i
			)
-- 			messageBox ("Some of your materials are missing textures. Check the MAXScript Listener for details.")
		)
		-- free the array from memory, aka garbage collect it
		free missingTex
	)
	
	-- end the undo block
	undo off
		
	-- refresh asset tracker
	ATSOps.Refresh()
)
