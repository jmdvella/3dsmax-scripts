macroscript VrayToGLB
	category:"Vella" 
	internalcategory:"Automate"
	tooltip:"Automate VrayToGLB"
	buttonText:"Vray To GLB"
	Icon:#("Containers",6)
( 
	/*
	Author: James Vella
	Website: http://www.jamesvella.net/
	Name-US: JV_VrayToGLB
	Version: 4.4
	Software: 3D Studio Max 2024.2.3
	Engine: V-Ray 6.20.03
	Language: Maxscript
	Description-US: Convert Vray Roughness materials to GLTF material
	*/ 
	
	with undo on 
	(
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
			fn ReplaceBitmap i material_name old_pattern replace_pattern =  
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

				local matching_bitmap_names = #() 
				
				-- Try find the bitmap based on the material name 
				try 
				( 
					for val in found_strings where matchpattern val pattern:("*" + material_name + "_*") do 
					( 
						append matching_bitmap_names val 
					) 
				) 
				catch()  

				-- Otherwise Loop through the found matching filenames and store in matching_bitmap_names array 
				-- Can find multiple files if names are similar Eg. 3DC_KISB_Cabinets can match to 3DC_KISB_CabinetsIslands 
				if matching_bitmap_names.count == 0 then 
				( 
					for s in found_strings do 
					( 
						if regex.IsMatch s modified_bitmap_name then 
						( 
							append matching_bitmap_names s 
						) 
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
			
			-- Function to populate empty materials with bitmaps if the name material name is Glass/Liquid/Water 
			fn FindGlassTextures i newMat missingTex = 
			( 
				-- Regex to match material name from bitmaps in directory 
				
				-- Regex to capture the first 3 groups, prefix_ + prefix_ + word  
				local rgx_pattern = "^(\\w+?)_(\\w+?)_(\\w+?)(?:_|$)" 
				-- specific regex that finds prefix_prefix_name  
				local regex = dotNetObject "System.Text.RegularExpressions.Regex" rgx_pattern 
				-- Find the first match in the materialName 
				local match = (regex.Match newMat.name) 
				
				local bitmap_name_based_on_mtl = "" 
				
				-- Check if a match was found 
				if match.Success then 
				( 
					-- bitmap named on material eg. prefix_prefix_bitmapname_basecolor 
					bitmap_name_based_on_mtl = match.Groups.Item[1].Value + "_" + match.Groups.Item[2].Value + "_" + match.Groups.Item[3].Value 
				) 

				-- Find first bitmap in the scene  
				local first_bitmap_filename 

				for tex in getClassInstances bitmapTex target:rootnode do 
				( 
					first_bitmap_filename = tex.filename 
					exit	-- Exit the loop after the first instance is found 
				) 
				
				-- Variables for created bitmaps			 
				local created_diffuse = undefined 
				local created_roughness = undefined 

				-- Create Diffuse, from first found texture in the scene					 
				if i.texmap_diffuse == undefined then 
				( 
					-- Get file directory and extension from first_bitmap_filename 
					local bitmap_dir = getFilenamePath first_bitmap_filename 
					local bitmap_ext = getFilenameType first_bitmap_filename 
					
					try 
					( 
						-- Change the filename to match the material name 
						newMat.baseColorMap = Bitmaptexture fileName:"" 
						newMat.baseColorMap.filename = bitmap_dir + (bitmap_name_based_on_mtl) + "_NotFound" + bitmap_ext 

						-- ReplaceBitmap function > bitmap filename > replace from > replace with  
						newMat.baseColorMap.filename = ReplaceBitmap (newMat.baseColorMap.filename) newMat.name "NotFound" "Base|Color|Diffuse" 
						
						newMat.baseColorMap.name = "basecolor" 
						
						-- create a variable to copy to roughness 
						created_diffuse = newMat.baseColorMap 
					) 
					catch 
					( 
						-- Add missing texture to missingTex array 
						append missingTex (newMat.name as string + " - Missing: Diffuse Texture. Without the Diffuse texture all" +  
							" other textures for this material cannot be created") 
						newMat.baseColorMap = undefined 
					) 
				) 
				
				if created_diffuse != undefined then 
				( 
					-- Create Roughness, copy from diffuse 
					if i.texmap_reflectionGlossiness == undefined then 
					( 
						try 
						( 
							-- Copy diffuse texture 
							newMat.roughnessMap = copy created_diffuse 

							-- Apply Gamma 1.0 to the bitmap 
							newMat.roughnessMap.bitmap = openBitmap newMat.roughnessMap.filename gamma:1.0 
							
							-- ReplaceBitmap function > bitmap filename > replace from > replace with  
							newMat.roughnessMap.filename = ReplaceBitmap (newMat.roughnessMap.filename) newMat.name "Base|Color|Diffuse" "Rough" 
							
							-- Material name 
							newMat.roughnessMap.name = "roughness" 
							
							-- create a variable to copy to other textures 
							created_roughness = newMat.roughnessMap 
						) 
						catch 
						( 
							-- Add missing texture to missingTex array 
							append missingTex (newMat.name as string + " - Missing: Roughness Texture. Without the Roughness texture all" + 
								" other textures for this material cannot be created") 
							newMat.roughnessMap = undefined 
						) 
					) 
				) 
				
				if (created_diffuse != undefined and created_roughness != undefined) then 
				( 
					-- Create Metal, copy from roughness (gamma is set correctly on roughness) 
					if i.texmap_metalness == undefined then 
					( 
						try 
						( 
							-- Copy roughness texture 
							newMat.metalnessMap = copy created_roughness 
							
							-- ReplaceBitmap function > bitmap filename > replace from > replace with  
							newMat.metalnessMap.filename = ReplaceBitmap (newMat.metalnessMap.filename) newMat.name "Rough" "Metal" 
							
							-- Material name 
							newMat.metalnessMap.name = "metal"  
						) 
						catch 
						( 
							-- Add missing texture to missingTex array 
							append missingTex (newMat.name as string + " - Missing: Metal Texture.") 
							newMat.metalnessMap = undefined 
						) 
					) 
					
					-- Create Normal, copy from roughness (gamma is set correctly on roughness) 
					if i.texmap_bump == undefined then 
					( 
						try 
						( 
							-- Copy roughness texture 
							newMat.normalMap = copy created_roughness 
							
							-- if Cannot find Normal_OpenGL use anything with Normal in the filename 
							newMat.normalMap.filename = ReplaceBitmap (newMat.normalMap.filename) newMat.name "Rough" "Normal" 
							-- Material name 
							newMat.normalMap.name = "normal" 
						) 
						catch 
						( 
							-- Add missing texture to missingTex array 
							append missingTex (newMat.name as string + " - Missing: Normal Texture.") 
							newMat.normalMap = undefined 
						) 
					) 
					
					-- Create Opacity, copy from roughness (gamma is set correctly on roughness) 
					if i.texmap_opacity == undefined then 
					( 
						try 
						( 
							-- Copy roughness texture 
							newMat.AlphaMap = copy created_roughness 
							-- ReplaceBitmap function > bitmap filename > replace from > replace with  
							newMat.AlphaMap.filename = ReplaceBitmap (newMat.AlphaMap.filename) newMat.name "Rough" "Opacity|Alpha" 
							-- Material name 
							newMat.AlphaMap.name = "opacity" 
							
							-- Opacity settings 
							newMat.alphaMode = 3	-- Blend mode 
						) 
						catch 
						( 
							-- Add missing texture to missingTex array 
							append missingTex (newMat.name as string + " - Missing: Opacity Texture.") 
							newMat.AlphaMap = undefined 
						) 
					) 
					
					-- Create Occlusion, copy from roughness (gamma is set correctly on roughness) 
					try 
					( 
						-- Copy roughness texture 
						newMat.ambientOcclusionMap = copy created_roughness 
						-- ReplaceBitmap function > bitmap filename > replace from > replace with  
						newMat.ambientOcclusionMap.filename = ReplaceBitmap (newMat.ambientOcclusionMap.filename) newMat.name "Rough" "AO|Ambient|Occlusion" 
						-- Material name 
						newMat.ambientOcclusionMap.name = "ao" 
					) 
					catch 
					( 
						-- Add missing texture to missingTex array 
						append missingTex (newMat.name as string + " - Missing: Occlusion Texture.") 
						newMat.ambientOcclusionMap = undefined 
					) 
				) 
				
				return newMat 
			) 
			
			-- Function to convert VrayMtl to glTF material 
			fn ConvertToGltf i missingTex = 
			( 
				-- Basic settings for GLTF shader 
				-- local newMat = glTFMaterial name:i.name
				newMat = undefined
				(
					-- GLTF Fix thanks to DenisT.MaxDoctor
					if iskindof (gltf_mat = execute "glTFMaterial") Material do
					(
						newMat = gltf_mat()
					)
				)

				newMat.name = i.name 

				-- Glass/Liquid, replace when there is no diffuse texture  
				if ((MatchPattern (i.name) pattern:"*Glass*" ignoreCase:true) or 
					(MatchPattern (i.name) pattern:"*Water*" ignoreCase:true) or 
					(MatchPattern (i.name) pattern:"*Liquid*" ignoreCase:true)) and (i.texmap_diffuse == undefined) do 
				( 
					-- NOTE THIS SECTION ONLY APPLIES TO MY WORKFLOW - For example if your texture is named as your material name 
					-- then it will search the directory of the first found texture in the scene and locate the bitmap by using 
					-- the material name. 
					FindGlassTextures i newMat missingTex 
					-- Return without continuing the rest of the function for glass materials 
					return (i = newMat) 
				) 

				-- Diffuse 
				if i.texmap_diffuse != undefined then 
				( 
					-- look for bitmap in sub-nodes such as falloff/color-correct etc. 
					for found_bitmap in (getClassInstances Bitmaptexture target:i.texmap_diffuse) do  
					( 
						newMat.baseColorMap = found_bitmap 
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
						newMat.roughnessMap = found_bitmap 
					) 
				) 
				else 
				( 
					-- Add missing texture to missingTex array 
					append missingTex (newMat.name as string + " - Missing: Roughness Texture") 
				) 
				
				-- Metal 
				if i.texmap_metalness != undefined then 
				( 
					-- look for bitmap in sub-nodes such as falloff/color-correct etc. 
					for found_bitmap in (getClassInstances Bitmaptexture target:i.texmap_metalness) do  
					( 
						newMat.metalnessMap = found_bitmap 
					) 
				) 
				else 
				( 
					try 
					( 
						-- Copy roughness texture and search for bitmap in directory 
						for found_bitmap in (getClassInstances Bitmaptexture target:i.texmap_reflectionGlossiness) do  
						( 
							-- Copy roughness texture 
							newMat.metalnessMap = copy found_bitmap 
						) 
						-- Material name 
						newMat.metalnessMap.name = "metal" 
						-- ReplaceBitmap function > bitmap filename > replace from > replace with   
						newMat.metalnessMap.filename = ReplaceBitmap (newMat.metalnessMap.filename) newMat.name "Rough" "Metal" 
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
				if i.texmap_reflectionGlossiness != undefined then 
				( 
					-- Copy roughness texture and search for bitmap in directory 
					for found_bitmap in (getClassInstances Bitmaptexture target:i.texmap_reflectionGlossiness) do  
					( 
						-- Copy roughness texture 
						newMat.ambientOcclusionMap = copy found_bitmap 
					) 
					try 
					( 
						-- Material name 
						newMat.ambientOcclusionMap.name = "ao" 
						-- Replace with matching new name - (?i). is regex pattern for ignorecase 
						newMat.ambientOcclusionMap.filename = ReplaceBitmap (newMat.ambientOcclusionMap.filename) newMat.name "Rough" "AO|Ambient|Occlusion" 
						
						-- If bitmap filename contains the words "Channel2" then change the UV channel to 2 
						if (MatchPattern (newMat.ambientOcclusionMap.filename) pattern:"*Channel2*" ignoreCase:true) then 
						( 
							newMat.ambientOcclusionMap.coords.mapChannel = 2 
							newMat.DoubleSided = on -- Enable Double Sided for Plant Leaves 
						) 
					) 
					catch 
					( 
						-- Remove texture if it doesnt find _ao in the name  
						newMat.ambientOcclusionMap = undefined 
						-- Add missing texture to missingTex array 
						append missingTex (newMat.name as string + " - Missing: Occlusion Texture") 
					) 
				) 
				else 
				( 
					-- Add missing texture to missingTex array 
					append missingTex (newMat.name as string + " - Missing: Occlusion Texture") 
				) 

				-- Normal 
				if i.texmap_bump != undefined then 
				( 
					if (classof i.texmap_bump == VRayNormalMap) then 
					( 
						-- look for bitmap in sub-nodes such as falloff/color-correct etc. 
						for found_bitmap in (getClassInstances Bitmaptexture target:i.texmap_bump.normal_map) do  
						( 
							newMat.normalMap = found_bitmap 
						) 
					) 
					else if (classof i.texmap_bump == Normal_Bump) then 
					( 
						-- look for bitmap in sub-nodes such as falloff/color-correct etc. 
						for found_bitmap in (getClassInstances Bitmaptexture target:i.texmap_bump) do  
						( 
							newMat.normalMap = found_bitmap 
						) 
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
						-- Copy roughness texture and search for bitmap in directory 
						for found_bitmap in (getClassInstances Bitmaptexture target:i.texmap_reflectionGlossiness) do  
						( 
							-- Copy roughness texture 
							newMat.normalMap = copy found_bitmap 
						) 
						-- Material name 
						newMat.normalMap.name = "normal" 
						-- ReplaceBitmap function > bitmap filename > replace from > replace with  
						newMat.normalMap.filename = ReplaceBitmap (newMat.normalMap.filename) newMat.name "Rough" "Normal" 
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
						newMat.emissionMap = found_bitmap 
					) 
				) 
				
				-- Opacity 
				if i.texmap_opacity != undefined then 
				( 
					-- look for bitmap in sub-nodes such as falloff/color-correct etc. 
					for found_bitmap in (getClassInstances Bitmaptexture target:i.texmap_opacity) do  
					( 
						newMat.AlphaMap = found_bitmap 
					) 
					
					-- Opacity settings 
					newMat.alphaMode = 2	-- Mask mode 
					newMat.alphaCutoff = 0.1 
				) 
				else 
				( 
					try 
					( 
						-- Copy roughness texture and search for bitmap in directory 
						for found_bitmap in (getClassInstances Bitmaptexture target:i.texmap_reflectionGlossiness) do  
						( 
							-- Copy roughness texture 
							newMat.AlphaMap = copy found_bitmap 
						) 
						-- Material name 
						newMat.AlphaMap.name = "opacity" 
						-- ReplaceBitmap function > bitmap filename > replace from > replace with  
						newMat.AlphaMap.filename = ReplaceBitmap (newMat.AlphaMap.filename) newMat.name "Rough" "Alpha|Opacity" 

						-- Opacity settings  
						newMat.alphaMode = 2	-- Mask mode 
						newMat.alphaCutoff = 0.1 
					) 
					catch 
					( 
						-- Remove texture if not found 
						newMat.AlphaMap = undefined 
					) 
				) 
				
				-- Convert textures 
				return newMat
			) 

			-- Main: runs functions above --

			-- Array to collect missing textures 
			local missingTex = #() 
			
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

			-- Iterate through materials in multi-sub and make unique
			for mat in getClassInstances MultiMaterial target:rootnode do 
			(
				for i = 1 to mat.numsubs do 
				(
					if mat[i] != undefined then
					(
						uniqueMat = copy mat[i]
						mat[i] = uniqueMat 
					) 
				)
			)
			
			-- Replace the Multi/Sub-Object material with the sub-material with the highest bitmap count 
			for mat in getClassInstances MultiMaterial target:rootnode do 
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
			for i in getClassInstances multiSubMaterial target:rootnode do 
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
			for i in getClassInstances VRay2SidedMtl target:rootnode do 
			( 
				-- Replace VRay2SidedMtl with Front material 
				p = i.frontMtl  
				replaceinstances i p 
			) 
			
			-- Replace Vray material with GLTF material 
			for i in getClassInstances VRayMtl target:rootnode do 
			( 
				p = (ConvertToGltf i missingTex)
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
	)
	-- Refresh asset tracker 
	ATSOps.Refresh() 
) 
