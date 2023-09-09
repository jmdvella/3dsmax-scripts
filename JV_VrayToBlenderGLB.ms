/*
Author: James Vella
Website: http://www.jamesvella.net/
Name-US: JV_VrayToBlenderGLB
Version: 2.0
Software: 3D Studio Max 2021.3
Engine: V-Ray 5.20.23
Language: Maxscript
Description-US: Convert Vray Roughness materials to Standard for FBX to GLB export
*/
macroscript VrayToGLB
	category:"Vella" 
	internalcategory:"Automate"
	tooltip:"Automate VrayToBlenderGLB"
	buttonText:"Vray To Blender GLB"
	Icon:#("Containers",6)
(
-- 	clearListener()
	
	undo on
	
	with animate off 
	(
		-- Function to count bitmaps within each material in a multi-sub
		fn CountBitmapsFromMaterial mat =
		(
			local found_map_count = 0
			for x in getClassInstances bitmaptexture do
			(
				for y in refs.dependents x where y == mat do
				(
					found_map_count += 1
				)
			)
			-- return count of found bitmaps
			found_map_count
		)
			
		-- Function to populate Glass/Liquid (empty) materials with another material in its Multi-Sub
		fn FindReplacementMaterial multiSubMat =
		(
			for n = 1 to multiSubMat.numsubs do
			(
				local subMat = multiSubMat[n]
				-- Randomly find another multi-sub material that does not have the name "Glass/Liquid...etc"
				if (
					not matchPattern subMat.name pattern:"*Glass*" ignoreCase:true and
					not matchPattern subMat.name pattern:"*Water*" ignoreCase:true and
					not matchPattern subMat.name pattern:"*Liquid*" ignoreCase:true
				) then
				(
					return copy subMat
				)
			)
			return undefined
		)
		
		-- Function to replace bitmaps
		fn ReplaceBitmap i old_pattern replace_pattern = 
		(
			-- Get the directory path & filename of the bitmap
			local bitmap_dir = getFilenamePath i
			local bitmap_name = getFilenameFile i
			
-- 			print ("Bitmap name: " + bitmap_name)
			
			-- find bitmap name with old name such as _Roughness
			local regex_pattern = "(?i)_?" + old_pattern + ".*"
			-- replace bitmap name with new name such as _Metallic
			local regex_replace_pattern = "(?i)_?" + replace_pattern + ".*"
			
			-- Regex to remove old name (eg. Photo_Opacity = Photo)
			local regex = dotnetObject "System.Text.RegularExpressions.Regex" regex_pattern
			local modified_bitmap_name = regex.Replace bitmap_name ""
			
-- 			print ("Modified name: " + modified_bitmap_name)
			
			-- Loop through files in the folder and add all filenames to the found_strings array
			local found_strings = #()
			for f in getFiles (bitmap_dir + "*.*") do
			(
				append found_strings (getFilenameFile f)
			)
			
			-- Loop through the found matching filenames and store in matching_bitmap_names array
			local matching_bitmap_names = #()
			for s in found_strings do
			(
				if regex.IsMatch s modified_bitmap_name then
				(
					append matching_bitmap_names s
				)
			)
			
			-- Replace bitmap_name with found replacement (eg. Photo = Photo_AO)
			local regex_replace = dotnetObject "System.Text.RegularExpressions.Regex" regex_replace_pattern
			local found_bitmap = ""
			for m in matching_bitmap_names do
			(
				if regex_replace.IsMatch(m) then
				(
					-- Change previous filename to new found filename
					found_bitmap = m
					-- Exit loop after finding first match
-- 					exit
					return (bitmap_dir + found_bitmap + (getFilenameType i))
				)
			)
			-- Return changed filename
-- 			 return (bitmap_dir + found_bitmap + (getFilenameType i))
		)
		
		-- Variable to collect missing textures
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
					newMat.diffusemap = found_bitmap
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
				append missingTex (newMat.name as string + " - Missing: Roughness Texture")
			)
			
			-- Metal
			if i.texmap_metalness != undefined then
			(
				-- look for bitmap in sub-nodes such as falloff/color-correct etc.
				for found_bitmap in (getClassInstances Bitmaptexture target:i.texmap_metalness) do 
				(
				newMat.reflectionMap = found_bitmap
				)
			)
			else
			(
				-- Add missing texture to missingTex array
				append missingTex (newMat.name as string + " - Missing: Metal Texture")
			)

			-- Occlusion
			try
			(
				if i.texmap_reflectionGlossiness != undefined then
				(
					
					-- look for bitmap in sub-nodes such as falloff/color-correct etc.
					for found_bitmap in (getClassInstances Bitmaptexture target:i.texmap_reflectionGlossiness) do 
					(
						-- Copy roughness texture
						newMat.specularMap = copy found_bitmap
					)
					-- Material name
					newMat.specularMap.name = "ao"
					-- ReplaceBitmap function > bitmap filename > replace from > replace with 
					newMat.specularMap.filename = ReplaceBitmap (newMat.specularMap.filename) "Rough" "AO|Ambient|Occlusion"
				)
			)
			catch
			(	
				-- If Occlusion texture not found then remove the filename and flag as missing
				newMat.specularMap.filename = ""
				
				-- Add missing texture to missingTex array
				if newMat.specularMap.filename == "" then
				(
					-- Add missing texture to missingTex array
					append missingTex (newMat.name as string + " - Missing: Occlusion Texture")
				)
			)

			-- Normal 
			if i.texmap_bump != undefined then
			(
				if (classof i.texmap_bump == VRayNormalMap) then
				(
					newMat.bumpMap = i.texmap_bump.normal_map
				)
				else 
				(
					-- add the current texture from the bump node 
					newMat.bumpMap = i.texmap_bump
					-- Add missing texture to missingTex array
					append missingTex (newMat.name as string + " - Missing: Normal Texture")
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
			
			-- Self Illumination
			if i.texmap_self_illumination != undefined then
			(
				-- look for bitmap in sub-nodes such as falloff/color-correct etc.
				for found_bitmap in (getClassInstances Bitmaptexture target:i.texmap_self_illumination) do 
				(
					-- Copy roughness texture
					newMat.selfillumMap = found_bitmap
				)
				
				newMat.selfIllumAmount = 100
			)

			-- Opacity
			if i.texmap_opacity != undefined then
			(
				newMat.opacityMap = i.texmap_opacity
			)
			
			-- NOTE THIS SECTION ONLY APPLIES TO MY WORKFLOW - For example if you have a material name like 3DC_LRLD_Candle  
			-- this will work (2 prefixes).If not then if you want to use this section you need to change the rgx_pattern.
			-- What this section does is create new textures for materials such as Glass/Liquid/Water that have no textures input.
			
			-- Glass/Liquid, not in a multi-sub and missing textures
			/*
			try
			(
				if (MatchPattern (i.name) pattern:"*Glass*" ignoreCase:true) or
				(MatchPattern (i.name) pattern:"*Water*" ignoreCase:true) or
				(MatchPattern (i.name) pattern:"*Liquid*" ignoreCase:true) do
				(
					-- current material name (Glass/liquid etc)
					local material_name = i.name
					
					-- regex pattern
					local rgx_pattern = "^(\\w{3}_\\w{4}_\\w+)_"
					-- specific regex that finds prefix_prefix_name 
					local regex = dotNetObject "System.Text.RegularExpressions.Regex" rgx_pattern
					-- Find the first match in the materialName
					local match = (regex.Match material_name)
					-- Check if a match was found
					if match.Success then
					(
						-- bitmap named on material eg. prefix_prefix_bitmapname_basecolor
						bitmap_name_based_on_mtl = (match.Groups.Item[1].Value)
					)
					
					-- Find a bitmap in the scene
					local find_a_bitmap = getClassInstances bitmapTex
					if find_a_bitmap.count > 0 do
					(
						local first_bitmap_filename = find_a_bitmap[1].filename
					)
					
					-- Create Diffuse, from first found texture in the scene					
					if i.texmap_diffuse == undefined then
					(
						-- Get file directory and extension from first_bitmap_filename
						local bitmap_dir = getFilenamePath first_bitmap_filename
						local bitmap_ext = getFilenameType first_bitmap_filename
						
						-- Change the filename to match the material name
						newMat.diffusemap = Bitmaptexture fileName:""
						newMat.diffusemap.filename = bitmap_dir + bitmap_name_based_on_mtl + "_NotFound" + bitmap_ext

						-- ReplaceBitmap function > bitmap filename > replace from > replace with 
						newMat.diffusemap.filename = ReplaceBitmap (newMat.diffusemap.filename) "NotFound" "Base|Color|Diffuse"
						
						newMat.diffusemap.name = "basecolor"
					)
					-- create a variable to copy to roughness
					local created_diffuse = newMat.diffusemap
					
					-- Create Roughness, copy from diffuse
					if i.texmap_reflectionGlossiness == undefined then
					(
						-- Copy diffuse texture
						newMat.glossinessMap = copy created_diffuse

						-- Apply Gamma 1.0 to the bitmap
						newMat.glossinessMap.bitmap = openBitmap newMat.glossinessMap.filename gamma:1.0
						
						-- ReplaceBitmap function > bitmap filename > replace from > replace with 
						newMat.glossinessMap.filename = ReplaceBitmap (newMat.glossinessMap.filename) "Base|Color|Diffuse" "Rough"
						
						-- Material name
						newMat.glossinessMap.name = "roughness"
					)
					-- create a variable to copy to other textures
					local created_roughness = newMat.glossinessMap
					
					-- Create Metal, copy from roughness (gamma is set correctly on roughness)
					if i.texmap_metalness == undefined then
					(
						-- Copy roughness texture
						newMat.reflectionMap = copy created_roughness
						
						-- ReplaceBitmap function > bitmap filename > replace from > replace with 
						newMat.reflectionMap.filename = ReplaceBitmap (newMat.reflectionMap.filename) "Rough" "Metal"
						
						-- Material name
						newMat.reflectionMap.name = "metal"
					)
					
					-- Create Normal, copy from roughness (gamma is set correctly on roughness)
					if i.texmap_bump == undefined then
					(
						-- Copy roughness texture
						newMat.bumpMap = copy created_roughness
						
						-- ReplaceBitmap function > bitmap filename > replace from > replace with 
						try
						(
							newMat.bumpMap.filename = ReplaceBitmap (newMat.bumpMap.filename) "Rough" "Normal_OpenGL"
						)
						catch()
						-- if Cannot find Normal_OpenGL use anything with Normal in the filename
						try
						(
							newMat.bumpMap.filename = ReplaceBitmap (newMat.bumpMap.filename) "Rough" "Normal"
						)
						catch()
						-- Material name
						newMat.bumpMap.name = "normal"
					)
					
					-- Create Opacity, copy from roughness (gamma is set correctly on roughness)
					if i.texmap_opacity == undefined then
					(
						-- Copy roughness texture
						newMat.opacityMap = copy created_roughness
						-- ReplaceBitmap function > bitmap filename > replace from > replace with 
						newMat.opacityMap.filename = ReplaceBitmap (newMat.opacityMap.filename) "Rough" "Opacity|Alpha"
						-- Material name
						newMat.opacityMap.name = "opacity"
					)
					
					-- Create Occlusion, copy from roughness (gamma is set correctly on roughness)
					if i.texmap_opacity == undefined then
					(
						-- Copy roughness texture
						newMat.specularMap = copy created_roughness
						-- ReplaceBitmap function > bitmap filename > replace from > replace with 
						newMat.specularMap.filename = ReplaceBitmap (newMat.specularMap.filename) "Rough" "AO|Ambient|Occlusion"
						-- Material name
						newMat.specularMap.name = "ao"
					)
				)
			)
			catch()
			*/
			
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
		
		-- Replace the Multi/Sub-Object material with the sub-material with the highest bitmap count
		multiSubList = getClassInstances MultiMaterial target:rootnode
		for mat in multiSubList do
		(
			-- Variable to track the maximum bitmap count
			max_count = 0  
			-- Variable to store the material with the maximum bitmap count
			max_material = undefined  
			
			-- Loop through sub-materials of the multi-sub material
			for subMatIndex = 1 to mat.numsubs do
			(
				subMat = mat[subMatIndex]
				m_count = CountBitmapsFromMaterial subMat
				
				-- Check if the current sub-material has a higher bitmap count than the previous maximum
				if m_count > max_count do
				(
					max_count = m_count
					max_material = subMat
				)
			)
			
			-- Replace the Multi/Sub-Object material with the sub-material
			if max_material != undefined do
			(
				replaceInstances mat max_material
				max_material.name = mat.name
			)
		)
		
		-- Search through Multi-Sub to find/replace empty Glass/Liquid materials with any other material in that Multi-Sub
		multiSubList = getClassInstances multiSubMaterial target:rootnode
		for i in multiSubList do
		(
			for n = 1 to i.numsubs do
			(
				local subMat = i[n]
				if (
					matchPattern subMat.name pattern:"*Glass*" ignoreCase:true or
					matchPattern subMat.name pattern:"*Water*" ignoreCase:true or
					matchPattern subMat.name pattern:"*Liquid*" ignoreCase:true
				) then
				(
					local replacementMat = FindReplacementMaterial i
					if replacementMat != undefined then
					(
						-- Set the name of the new material as per the original material name
						local newName = substituteString subMat.name "Glass" "Glass" 
						newName = substituteString newName "Water" "Water" 
						newName = substituteString newName "Liquid" "Liquid" 
						replacementMat.name = newName

						i[n] = replacementMat
					)
				)
			)
		)

		-- Convert VRay2SidedMtl to VrayMtl
		vrayMtlList = getClassInstances VRay2SidedMtl target:rootnode
		for i in vrayMtlList do
		(
			-- Replace VRay2SidedMtl with Front material
			p = i.frontMtl 
			replaceinstances i p
		)
			
		-- Convert VRayLightMtl to VrayMtl
		vrayMtlList = getClassInstances VRayLightMtl target:rootnode
		for i in vrayMtlList do
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
		vrayMtlList = getClassInstances VRayMtl target:rootnode
		for i in vrayMtlList do
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
			messageBox ("Some of your materials are missing textures. Check the MAXScript Listener for details.")
		)
		-- free the array from memory, aka garbage collect it
		free missingTex
	)
			
	-- end the undo block
	undo off
		
	-- refresh asset tracker
	ATSOps.Refresh()
)
