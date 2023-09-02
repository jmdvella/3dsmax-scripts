/*
Author: James Vella
Website: http://www.jamesvella.net/
Name-US: JV_VrayToBlenderGLB
Version: 1.0
Software: 3D Studio Max 2021.3
Engine: V-Ray 5.20.23
Language: Maxscript
Description-US: Convert Vray Roughness materials to Standard for FBX to GLB export
	
-- TODO: 
-- Fix Glass when not in multi-sub. Will need a new regex to locate based on material name
*/

macroscript VrayToGLB
	category:"Vella" 
	internalcategory:"Automate"
	tooltip:"Automate VrayToBlenderGLB"
	buttonText:"Vray To Blender GLB"
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
			
			-- Remove Diffuse Falloff node and Color Correction node (Optional) 	<--------------
			try
			(
				while (classof i.texmap_diffuse == falloff or classof i.texmap_diffuse == Color_Correction) do
				(
					newMat.diffusemap = i.texmap_diffuse.map1
					-- Update the value of i.texmap_diffuse
					i.texmap_diffuse = i.texmap_diffuse.map1
					-- This will always select the node Front in Fresnel  
					if (classof i.texmap_diffuse != falloff) then break

					newMat.diffusemap = i.texmap_diffuse.map
					-- Update the value of i.texmap_diffuse
					i.texmap_diffuse = i.texmap_diffuse.map 
					-- This will always take the node inside the Basic Parameters in Color Correction node
					if (classof i.texmap_diffuse != Color_Correction) then break
				)
			)
			catch()
			
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
			
			-- Occlusion
			try
			(
				if i.texmap_reflectionGlossiness != undefined then
				(
					-- Copy roughness texture
					newMat.specularMap = copy i.texmap_reflectionGlossiness
					-- Replace with matching new name - (?i). is regex pattern for ignorecase
					newMat.specularMap.filename = replace_Bitmap (newMat.specularMap.filename) "(?i).*AO.*|.*Occlusion.*|.*Ambient.*"
					-- Material name
					newMat.specularMap.name = "ao"
				)
			)
			catch()
			
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
			
			-- Self Illumination
			if i.selfIllumination != color 0 0 0 then
			(
				newMat.useSelfIllumColor = on
				newMat.selfIllumColor = i.selfIllumination
			)
			if i.texmap_self_illumination != undefined then
			(
				newMat.useSelfIllumColor = on
				newMat.selfIllumColor = color 255 255 255
				newMat.selfillumMap = i.texmap_self_illumination
			)
			
			-- Replace Opacity
			if i.texmap_opacity != undefined then
			(
				newMat.opacityMap = i.texmap_opacity
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
						newMat.opacityMap = copy i.texmap_reflectionGlossiness
						-- Replace with matching new name - (?i). is regex pattern for ignorecase
						newMat.opacityMap.filename = replace_Bitmap (newMat.opacityMap.filename) "(?i).*Opacity.*|.*Alpha.*"
						-- Material name
						newMat.opacityMap.name = "opacity"
					)
					
					if i.texmap_metalness == undefined then
					(
						-- Copy roughness texture
						newMat.reflectionMap = copy i.texmap_reflectionGlossiness
						-- Replace with matching new name - (?i). is regex pattern for ignorecase
						newMat.reflectionMap.filename = replace_Bitmap (newMat.reflectionMap.filename) "(?i).*Metal.*|.*Metallic.*|.*Metalness*."
						-- Material namex
						newMat.reflectionMap.name = "metal"
					)
				)
			)
			catch()
			
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
		vrayMtlList = getClassInstances VRay2SidedMtl
		for i in vrayMtlList do
		(
			-- Replace VRay2SidedMtl with Front material
			p = i.frontMtl 
			replaceinstances i p
		)
			
		-- Convert VRayLightMtl to VrayMtl
		vrayMtlList = getClassInstances VRayLightMtl
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
			
	-- end the undo block
	undo off
		
	-- refresh asset tracker
	ATSOps.Refresh()
)
