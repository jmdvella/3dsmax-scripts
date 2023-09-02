/*
Author: James Vella
Website: http://www.jamesvella.net/
Name-US: JV_VrayToGLB
Version: 1.3
Software: 3D Studio Max 2024.1
Engine: V-Ray 6.10.08
Language: Maxscript
Description-US: Convert Vray Roughness materials to GLTF material

-- TODO: 
-- Fix Glass when not in multi-sub. Will need a new regex to locate based on material name
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
		fn count_Bitmaps_From_Material mat =
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
		
		-- Function to replace bitmaps
		fn replace_Bitmap i replace_string = 
		(
			-- Get the directory path & filename of the bitmap
			local bitmap_dir = getFilenamePath i
			local bitmap_name = getFilenameFile i
			
			-- Regex to remove suffix after last underscore (eg. Photo_Opacity = Photo)
			local pattern_suffix = "(?i).*(?=_[^_]*$)"
			local regex_suffix = dotnetObject "System.Text.RegularExpressions.Regex" pattern_suffix
			local modified_bitmap_name = regex_suffix.Match bitmap_name

			-- Loop through files in the folder and add all filenames to the found_strings array
			local found_strings = #()
			for f in getFiles (bitmap_dir + "*.*") do
			(
				append found_strings (getFilenameFile f)
			)

			-- Get the matched value as the stripped bitmap name (eg. Photo instead of Photo_Opacity)
			if modified_bitmap_name.Success do
			(
				stripped_bitmap_name = modified_bitmap_name.Value
			)
			
			-- Loop through the found matching filenames and store in array matching_bitmap_names
			local matching_bitmap_names = #()
			for s in found_strings do
			(
				if regex_suffix.IsMatch s stripped_bitmap_name then
				(
					append matching_bitmap_names s
				)
			)
			
			-- Replace bitmap_name suffix with replace_string (eg. _AO, now Photo_AO when using fn replace_Bitmap)
			local regex_replace = dotnetObject "System.Text.RegularExpressions.Regex" replace_string
			local found_bitmap = ""
			for m in matching_bitmap_names do
			(
				if regex_replace.IsMatch(m) then
				(
					-- Change previous filename to new found filename
					found_bitmap = m
					-- Exit loop after finding first match
					exit
				)
			)

			-- Return changed filename
			 return (bitmap_dir + found_bitmap + (getFilenameType i))
		)
		
		-- Function to populate Glass/Liquid (empty) materials with another material in its Multi-Sub
		fn find_Replacement_Material multiSubMat =
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
		
		-- Function to convert VrayMtl to glTF material
		fn convert_to_gltf i =
		(
			-- Basic settings for Arnold Surface shader
			local newMat = glTFMaterial()	
			newMat.name = i.name
			
			-- Base Color
			if i.texmap_diffuse != undefined then
			(
				newMat.baseColorMap = i.texmap_diffuse
			)
			
			-- Remove Diffuse Falloff node and Color Correction node (Optional) 	<--------------
			try
			(
				while (classof i.texmap_diffuse == falloff or classof i.texmap_diffuse == Color_Correction) do
				(
					-- Falloff	
					newMat.baseColorMap = i.texmap_diffuse.map1
					-- Update the value of i.texmap_diffuse
					i.texmap_diffuse = i.texmap_diffuse.map1
					-- This will always select the node Front in Fresnel  
					if (classof i.texmap_diffuse != falloff) then break

					-- Color Correction
					newMat.baseColorMap = i.texmap_diffuse.map
					-- Update the value of i.texmap_diffuse
					i.texmap_diffuse = i.texmap_diffuse.map 
					-- This will always take the node inside the Basic Parameters in Color Correction node
					if (classof i.texmap_diffuse != Color_Correction) then break
				)
			)
			catch()
		
			
			-- Roughness
			if i.texmap_reflectionGlossiness != undefined then
			(
				newMat.roughnessMap = i.texmap_reflectionGlossiness
			)
			
			-- Metal
			if i.texmap_metalness != undefined then
			(
				newMat.metalnessMap = i.texmap_metalness
			)
			if i.texmap_metalness == undefined then
			(
				newMat.metalness = 0
			)
			
			-- Occlusion
			try
			(
				if i.texmap_reflectionGlossiness != undefined then
				(
					-- Copy roughness texture
					newMat.ambientOcclusionMap = copy i.texmap_reflectionGlossiness
					-- Replace with matching new name - (?i). is regex pattern for ignorecase
					newMat.ambientOcclusionMap.filename = replace_Bitmap (newMat.ambientOcclusionMap.filename) "(?i).*AO.*|.*Occlusion.*|.*Ambient.*"
					-- Material name
					newMat.ambientOcclusionMap.name = "ao"
				)
			)
			catch()

			-- Normal
			if i.texmap_bump != undefined then
			(
				-- Swap DirectX for OpenGL Normal textures
				try
				(
					i.texmap_bump.normal_map.filename = substituteString i.texmap_bump.normal_map.filename "DirectX" "OpenGL"
				)
				catch()
				
				if (classof i.texmap_bump == VRayNormalMap) then
				(
					newMat.normalMap = i.texmap_bump.normal_map
				)
			)
			
			-- Emission 
			if i.texmap_self_illumination != undefined then
			(
				newMat.emissionMap = i.texmap_self_illumination
			)
			
			-- Opacity
			if i.texmap_opacity != undefined then
			(
				newMat.AlphaMap = i.texmap_opacity
				
				-- Opacity settings
				newMat.alphaMode = 2
				newMat.alphaCutoff = 0.1
			)
			
			-- Glass/Liquid
			try
			(
				if (MatchPattern (i.name) pattern:"*Glass*" ignoreCase:true) or
				(MatchPattern (i.name) pattern:"*Water*" ignoreCase:true) or
				(MatchPattern (i.name) pattern:"*Liquid*" ignoreCase:true) do
				(
					if i.texmap_opacity == undefined then
					(
						-- Copy roughness texture
						newMat.AlphaMap = copy i.texmap_reflectionGlossiness
						-- Replace with matching new name - (?i). is regex pattern for ignorecase
						newMat.AlphaMap.filename = replace_Bitmap (newMat.AlphaMap.filename) "(?i).*Opacity.*|.*Alpha.*"
						-- Material name
						newMat.AlphaMap.name = "opacity"
					)
					
					if i.texmap_metalness == undefined then
					(
						-- Copy roughness texture
						newMat.metalnessMap = copy i.texmap_reflectionGlossiness
						-- Replace with matching new name - (?i). is regex pattern for ignorecase
						newMat.metalnessMap.filename = replace_Bitmap (newMat.metalnessMap.filename) "(?i).*Metal.*|.*Metallic.*|.*Metalness*."
						-- Material namex
						newMat.metalnessMap.name = "metal"
					)
					
					-- Opacity settings
					newMat.alphaMode = 3
					newMat.metalness = 1
				)
			)
			catch()
			
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
		
		-- Convert VRay2SidedMtl to VrayMtl
		local vrayMtlList = getClassInstances VRay2SidedMtl
		for i in vrayMtlList do
		(
			-- Replace VRay2SidedMtl with Front material
			p = i.frontMtl 
			replaceinstances i p
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
					local replacementMat = find_Replacement_Material i
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

		-- Replace Vray material with GLTF material
		local vrayMatList = getClassInstances VRayMtl target:rootnode
		for i in vrayMatList do
		(
			p = convert_to_gltf i
			replaceInstances i p 
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
				m_count = count_Bitmaps_From_Material subMat
				
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
	)

	undo off

	-- Refresh asset tracker
	ATSOps.Refresh()
)