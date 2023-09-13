/*
Author: James Vella
Website: http://www.jamesvella.net/
Name-US: JV_VrayToGLB
Version: 3.0
Software: 3D Studio Max 2024.1
Engine: V-Ray 6.10.08
Language: Maxscript
Description-US: Convert Vray Roughness materials to GLTF material
*/

macroscript VrayToGLB
	category:"Vella" 
	internalcategory:"Automate"
	tooltip:"Automate VrayToGLB"
	buttonText:"Vray To GLB"
	Icon:#("Containers",6)
(
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
		
		-- Function to replace bitmaps by searching through the directory where other textures are
		fn ReplaceBitmap i old_pattern replace_pattern = 
		(
			-- Get the directory path & filename of the bitmap
			local bitmap_dir = getFilenamePath i
			local bitmap_name = getFilenameFile i
			
			-- find bitmap name with old name such as _Roughness
			local regex_pattern = "(?i)_?" + old_pattern + ".*"
			-- replace bitmap name with new name such as _Metallic
			local regex_replace_pattern = "(?i)_?" + replace_pattern + ".*"
			
			-- Regex to remove old name (eg. Photo_Opacity = Photo)
			local regex = dotnetObject "System.Text.RegularExpressions.Regex" regex_pattern
			local modified_bitmap_name = regex.Replace bitmap_name ""

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
					return (bitmap_dir + found_bitmap + (getFilenameType i))
				)
			)
		)
		
		-- Array to collect missing textures
		local missingTex = #()
		
		-- Function to convert VrayMtl to glTF material
		fn ConvertToGltf i =
		(
			-- Basic settings for Arnold Surface shader
			local newMat = glTFMaterial()	
			newMat.name = i.name
			
			-- Diffuse
			if i.texmap_diffuse != undefined then
			(
				-- look for bitmap in sub-nodes such as falloff/color-correct etc.
				for found_bitmap in (getClassInstances Bitmaptexture target:i.texmap_diffuse) do 
				(
					newMat.baseColorMap = i.texmap_diffuse
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
					newMat.roughnessMap = i.texmap_reflectionGlossiness
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
					newMat.metalnessMap = i.texmap_metalness
				)
			)
			else
			(
				try
				(
					-- look for bitmap in sub-nodes such as falloff/color-correct etc.
					for found_bitmap in (getClassInstances Bitmaptexture target:i.texmap_reflectionGlossiness) do 
					(
						-- Copy roughness texture
						newMat.metalnessMap = copy found_bitmap
					)
					-- Material name
					newMat.metalnessMap.name = "metal"
					-- ReplaceBitmap function > bitmap filename > replace from > replace with 
					newMat.metalnessMap.filename = ReplaceBitmap (newMat.metalnessMap.filename) "Rough" "Metal"
				)
				catch
				(
					-- Add missing texture to missingTex array
					append missingTex (newMat.name as string + " - Missing: Metal Texture")
					
					-- Remove texture if not found
					newMat.metalnessMap = undefined
				)
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
						newMat.ambientOcclusionMap = copy found_bitmap
					)
					-- Material name
					newMat.ambientOcclusionMap.name = "ao"
					-- Replace with matching new name - (?i). is regex pattern for ignorecase
					newMat.ambientOcclusionMap.filename = ReplaceBitmap (newMat.ambientOcclusionMap.filename) "Rough" "AO|Ambient|Occlusion"
					
					-- If bitmap filename contains the words "Channel2" then change the UV channel to 2
					if (MatchPattern (newMat.ambientOcclusionMap.filename) pattern:"*Channel2*" ignoreCase:true) then
					(
						newMat.ambientOcclusionMap.coords.mapChannel = 2
					)
					
				)
			)
			catch
			(	
				-- If Occlusion texture not found then remove the filename and flag as missing
				newMat.ambientOcclusionMap.filename = ""
				
				-- Add missing texture to missingTex array
				if newMat.ambientOcclusionMap.filename == "" then
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
					newMat.normalMap = i.texmap_bump.normal_map
				)
				else
				(
					-- add the current texture from the bump node 
					newMat.normalMap = i.texmap_bump
					-- Add missing texture to missingTex array
					append missingTex (newMat.name as string + " - Missing: Normal Texture")
				)
			)
			else
			(
				try
				(
					-- look for bitmap in sub-nodes such as falloff/color-correct etc.
					for found_bitmap in (getClassInstances Bitmaptexture target:i.texmap_reflectionGlossiness) do 
					(
						-- Copy roughness texture
						newMat.normalMap = copy found_bitmap
					)
					-- Material name
					newMat.normalMap.name = "normal"
					-- ReplaceBitmap function > bitmap filename > replace from > replace with 
					newMat.normalMap.filename = ReplaceBitmap (newMat.normalMap.filename) "Rough" "Normal_OpenGL"
					-- if Cannot find Normal_OpenGL use anything with Normal in the filename
					newMat.normalMap.filename = ReplaceBitmap (newMat.normalMap.filename) "Rough" "Normal"
				)
				catch
				(
					-- Add missing texture to missingTex array
					append missingTex (newMat.name as string + " - Missing: Normal Texture")
					-- Remove texture if not found
					newMat.normalMap = undefined
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
			
			-- Emission 
			if i.texmap_self_illumination != undefined then
			(
				-- look for bitmap in sub-nodes such as falloff/color-correct etc.
				for found_bitmap in (getClassInstances Bitmaptexture target:i.texmap_self_illumination) do 
				(
					newMat.emissionMap = i.texmap_self_illumination
				)
			)
			
			-- Opacity
			if i.texmap_opacity != undefined then
			(
				newMat.AlphaMap = i.texmap_opacity
				
				-- Opacity settings
				newMat.alphaMode = 2	-- Mask mode
				newMat.alphaCutoff = 0.1
			)
			else
			(
				try
				(
					-- look for bitmap in sub-nodes such as falloff/color-correct etc.
					for found_bitmap in (getClassInstances Bitmaptexture target:i.texmap_reflectionGlossiness) do 
					(
						-- Copy roughness texture
						newMat.AlphaMap = copy found_bitmap
					)
					-- Material name
					newMat.AlphaMap.name = "opacity"
					-- ReplaceBitmap function > bitmap filename > replace from > replace with 
					newMat.AlphaMap.filename = ReplaceBitmap (newMat.AlphaMap.filename) "Rough" "Alpha|Opacity"

					-- Opacity settings 
					newMat.alphaMode = 2	-- Mask mode
					newMat.alphaCutoff = 0.1
					
					if (MatchPattern (i.name) pattern:"*Glass*" ignoreCase:true) or
					(MatchPattern (i.name) pattern:"*Water*" ignoreCase:true) or
					(MatchPattern (i.name) pattern:"*Liquid*" ignoreCase:true) do
					(
						newMat.alphaMode = 3	-- Blend mode
					)
				)
				catch
				(
					-- Remove texture if not found
					newMat.AlphaMap = undefined
				)
			)
			
			-- NOTE THIS SECTION ONLY APPLIES TO MY WORKFLOW - For example if you have a material name like 3DC_LRLD_Candle  
			-- this will work (2 prefixes).If not then if you want to use this section you need to change the rgx_pattern.
			-- What this section does is create new textures for materials such as Glass/Liquid/Water that have no textures input.
			/*
			-- Glass/Liquid, replace when there is no diffuse texture 
			if ((MatchPattern (i.name) pattern:"*Glass*" ignoreCase:true) or
			(MatchPattern (i.name) pattern:"*Water*" ignoreCase:true) or
			(MatchPattern (i.name) pattern:"*Liquid*" ignoreCase:true)) and (i.texmap_diffuse == undefined) do
			(
				try
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
						newMat.baseColorMap = Bitmaptexture fileName:""
						newMat.baseColorMap.filename = bitmap_dir + bitmap_name_based_on_mtl + "_NotFound" + bitmap_ext

						-- ReplaceBitmap function > bitmap filename > replace from > replace with 
						newMat.baseColorMap.filename = ReplaceBitmap (newMat.baseColorMap.filename) "NotFound" "Base|Color|Diffuse"
						
						newMat.baseColorMap.name = "basecolor"
					)
					-- create a variable to copy to roughness
					local created_diffuse = newMat.baseColorMap
					
					-- Create Roughness, copy from diffuse
					if i.texmap_reflectionGlossiness == undefined then
					(
						-- Copy diffuse texture
						newMat.roughnessMap = copy created_diffuse

						-- Apply Gamma 1.0 to the bitmap
						newMat.roughnessMap.bitmap = openBitmap newMat.roughnessMap.filename gamma:1.0
						
						-- ReplaceBitmap function > bitmap filename > replace from > replace with 
						newMat.roughnessMap.filename = ReplaceBitmap (newMat.roughnessMap.filename) "Base|Color|Diffuse" "Rough"
						
						-- Material name
						newMat.roughnessMap.name = "roughness"
					)
					-- create a variable to copy to other textures
					local created_roughness = newMat.roughnessMap
					
					-- Create Metal, copy from roughness (gamma is set correctly on roughness)
					if i.texmap_metalness == undefined then
					(
						-- Copy roughness texture
						newMat.metalnessMap = copy created_roughness
						
						-- ReplaceBitmap function > bitmap filename > replace from > replace with 
						newMat.metalnessMap.filename = ReplaceBitmap (newMat.metalnessMap.filename) "Rough" "Metal"
						
						-- Material name
						newMat.metalnessMap.name = "metal"
					)
					
					-- Create Normal, copy from roughness (gamma is set correctly on roughness)
					if i.texmap_bump == undefined then
					(
						-- Copy roughness texture
						newMat.normalMap = copy created_roughness
						
						-- ReplaceBitmap function > bitmap filename > replace from > replace with 
						newMat.normalMap.filename = ReplaceBitmap (newMat.normalMap.filename) "Rough" "Normal_OpenGL"
						-- if Cannot find Normal_OpenGL use anything with Normal in the filename
						newMat.normalMap.filename = ReplaceBitmap (newMat.normalMap.filename) "Rough" "Normal"
						-- Material name
						newMat.normalMap.name = "normal"
					)
					
					-- Create Opacity, copy from roughness (gamma is set correctly on roughness)
					if i.texmap_opacity == undefined then
					(
						-- Copy roughness texture
						newMat.AlphaMap = copy created_roughness
						-- ReplaceBitmap function > bitmap filename > replace from > replace with 
						newMat.AlphaMap.filename = ReplaceBitmap (newMat.AlphaMap.filename) "Rough" "Opacity|Alpha"
						-- Material name
						newMat.AlphaMap.name = "opacity"
						
						-- Opacity settings
						newMat.alphaMode = 3
					)
					
					-- Create Occlusion, copy from roughness (gamma is set correctly on roughness)
					try
					(
						-- Copy roughness texture
						newMat.ambientOcclusionMap = copy created_roughness
						-- ReplaceBitmap function > bitmap filename > replace from > replace with 
						newMat.ambientOcclusionMap.filename = ReplaceBitmap (newMat.ambientOcclusionMap.filename) "Rough" "AO|Ambient|Occlusion"
						-- Material name
						newMat.ambientOcclusionMap.name = "ao"
					)
					catch()
				)
				catch()
			)
			*/
			
			-- Convert textures
			i = newMat
		)
		
		-- Delete all Subdvision modifiers
		for obj in objects do
		(
			-- Check if any of the modifiers are OpenSubdiv, TurboSmooth, or MeshSmooth
			for mod in obj.modifiers do
			(
				if (mod.name == "OpenSubdiv" or mod.name == "TurboSmooth" or mod.name == "MeshSmooth") do
				(
					deleteModifier obj mod
				)
			)
		)
		
		-- Replace the Multi/Sub-Object material with the sub-material with the highest bitmap count
		local multiSubList = getClassInstances MultiMaterial target:rootnode
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
		local multiSubList = getClassInstances multiSubMaterial target:rootnode
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
		local vrayMtlList = getClassInstances VRay2SidedMtl target:rootnode
		for i in vrayMtlList do
		(
			-- Replace VRay2SidedMtl with Front material
			p = i.frontMtl 
			replaceinstances i p
		)
		
		-- Replace Vray material with GLTF material
		local vrayMatList = getClassInstances VRayMtl target:rootnode
		for i in vrayMatList do
		(
			p = ConvertToGltf i
			replaceInstances i p 
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

	undo off

	-- Refresh asset tracker
	ATSOps.Refresh()
)
