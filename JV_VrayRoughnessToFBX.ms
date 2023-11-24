
macroscript VrayToFBX
	category:"Vella" 
	internalcategory:"Automate"
	tooltip:"Automate VrayToFBX"
	buttonText:"Vray To FBX"
	Icon:#("SchematicView",2)

(  
	/*
	Author: James Vella
	Website: http://www.jamesvella.net/
	Name-US: JV_VrayRoughnessToFBX
	Version: 3.5
	Software: 3D Studio Max 2021.3
	Engine: V-Ray 5.20.23
	Language: Maxscript
	Description-US: Convert Vray Roughness materials to Standard for export to FBX
	*/	 

	-- start an undo block       
	undo on  
	 
	with animate off  
	(  
		-- Array to collect missing textures       
		local missingTex = #()  
		 
		fn ReplaceTxFiles images =  
		(  
			-- Replace tx extension with jpg/jpeg or png      

			bitmap_dir = getFilenamePath images.HDRIMapName  
			bitmap_name = getFilenameFile images.HDRIMapName  
			 
			for f in getFiles (bitmap_dir + bitmap_name + ".*") do  
			(  
				if matchPattern f pattern:"*.jpg" or matchPattern f pattern:"*.jpeg" or matchPattern f pattern:"*.png" do  
				(  
					images.HDRIMapName = f  
				)  
			)  
		)  

		fn ConvertVrayBitmaps i =  
		(  
			-- Convert VrayBitmap to Standard Bitmap          
			local newBitmap = Bitmaptexture()   

			-- Set Gamma          
			if i.gamma == 1.0 or i.rgbColorSpace == 3 then  
			(  
				-- Open the bitmap file with the specified gamma value (works for stripped paths)    
				newBitmap.bitmap = openBitmap (filenameFromPath i.HDRIMapName) gamma:i.gamma  
			)  

			newBitmap.filename = i.HDRIMapName  
			newBitmap.name = i.name  

			return newBitmap  
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
			try
			(
				if i.texmap_metalness != undefined then  
				(  
					-- look for bitmap in sub-nodes such as falloff/color-correct etc.       
					for found_bitmap in (getClassInstances Bitmaptexture target:i.texmap_metalness) do  
					(  
						newMat.reflectionMap = found_bitmap  
					)  
					-- Set Coordinates to Texture instead of Environment       
					newMat.reflectionMap.coords.mappingType = 0  
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
					-- Try find metal texture in the directory       
					try  
					(  
						-- Copy roughness bitmap and change name to Metal       
						if i.texmap_reflectionGlossiness != undefined then  
						(  
							-- look for bitmap in sub-nodes such as falloff/color-correct etc.       
							for found_bitmap in (getClassInstances Bitmaptexture target:i.texmap_reflectionGlossiness) do  
							(  
								newMat.reflectionMap = copy found_bitmap  
							)  
							
							newMat.reflectionMap.filename = ReplaceBitmap (newMat.reflectionMap.filename) newMat.name "Rough" "Metal"  
							newMat.reflectionMap.name = "metal"  
							newMat.reflectionMapAmount = 100  
						)  
					)  
					catch  
					(  
						-- Add missing texture to missingTex array       
						append missingTex (newMat.name as string + " - Missing: Metal Texture")  
						newMat.reflectionMap = undefined  
					)  
				)  
				else  
				(  
					newMat.reflectionMapAmount = (i.reflection_metalness * 100)  
				)  
			)
			catch
			(
				/*User does not have Vray 5*/
				-- Disable Metal in Standard Material       
				newMat.reflectionMapEnable = on  
				newMat.reflectionMapAmount = 0  
			)
			 
			-- Replace Opacity       
			if i.texmap_opacity != undefined then  
			(  
				try  
				(  
					-- look for bitmap in sub-nodes such as falloff/color-correct etc.       
					for found_bitmap in (getClassInstances Bitmaptexture target:i.texmap_opacity) do  
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
		 
		-- Find and collect TX Bitmaps        
		local found_tx_bitmaps = #()
		try
		(  
			for i in getClassInstances VRayBitmap target:rootnode do  
			(  
				if MatchPattern i.filename pattern:"*.tx" then  
				(  
					append found_tx_bitmaps i  
				)  
			)  
		)
		catch
		(
			/*User does not have Vray 5*/
		)

		-- Convert TX Bitmaps to jpg/png        
		if found_tx_bitmaps.count > 0 then  
		(  
			-- for i in found_tx_bitmaps do ReplaceTxFiles i -- test without query     
			try  
			( 
				if queryBox("Found .tx files, would you like to convert them to jpg or png\n(which ever is found in that directory)?") then  
				(  
					for i in found_tx_bitmaps do ReplaceTxFiles i  
				)  
			) 
			catch 
			( 
				messagebox("Unable to convert .tx images to .jpg or .png.") 
			) 
		)  

		-- Convert VrayBitmap to Standard Bitmap     
		try  
		(  
			for i in getClassInstances VRayBitmap target:rootnode do  
			(  
				p = ConvertVrayBitmaps i  
				replaceinstances i p  
			)  
		)  
		catch  
		(  
			messagebox("Unable to convert Vray Bitmaps to Standard Bitmaps.")  
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
