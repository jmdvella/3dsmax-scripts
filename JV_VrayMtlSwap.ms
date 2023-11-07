
macroscript VrayMtlSwap
	category:"Vella" 
	internalcategory:"Automate"
	tooltip:"Automate VrayMtlSwap"
	buttonText:"Vray Mtl Swap"
	Icon:#("StateSets",1)

(
	/*
	Author: James Vella
	Website: http://www.jamesvella.net/
	Name-US: JV_VrayMtlSwap
	Version: 2.1
	Software: 3D Studio Max 2021.3
	Engine: V-Ray 5.20.23
	Language: Maxscript
	Description-US: Swap materials based on Object name
	*/
	undo on
	
	with animate off 
	(
		-- Function to replace bitmaps
		fn ReplaceBitmap i newMat replace_pattern = 
		(
			-- Get the directory path & filename of the bitmap
			local bitmap_dir = getFilenamePath i
			local bitmap_name = getFilenameFile i
			
			-- Search for matching bitmap names to object name
			local found_strings = #()
			for f in getFiles (bitmap_dir + "*.*") where (MatchPattern f pattern:("*" + newMat + "*")) do
			(
				append found_strings (getFilenameFile f)
			)
			
-- 			print found_strings
			
			-- replace bitmap name with new name such as _Metallic
			local regex_pattern = "(?i)_?" + replace_pattern + ".*"
			
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
				for val in found_strings where matchpattern val pattern:("*" + newMat + "_*") do
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
			
			print matching_bitmap_names
			
			-- Replace bitmap_name with found replacement (eg. Photo = Photo_AO)
			local found_bitmap = ""
			for m in matching_bitmap_names do
			(
				if regex.IsMatch(m) then
				(
					-- Change previous filename to new found filename
					found_bitmap = m
					free matching_bitmap_names	-- remove items from array for speed
					free found_strings			-- remove items from array for speed
					return (bitmap_dir + found_bitmap + (getFilenameType i))
				)
			)
		)
		
		fn ReplaceVrayMat replace_name newMat = 
		(
			-- Diffuse
			if newMat.texmap_diffuse != undefined then
			(
				try
				(
					newMat.texmap_diffuse.filename = ReplaceBitmap (newMat.texmap_diffuse.filename) replace_name "Base|Color|Diffuse"
				)
				catch()
			)
		
			-- Roughness
			if newMat.texmap_reflectionGlossiness != undefined then
			(
				try
				(
					newMat.texmap_reflectionGlossiness.filename = ReplaceBitmap (newMat.texmap_reflectionGlossiness.filename) replace_name "Rough"
				)
				catch()
			)
			
			-- Normal
			if newMat.texmap_bump != undefined then
			(
				try
				(
					if newMat.texmap_bump.normal_map != undefined then
					(
						try
						(
							newMat.texmap_bump.normal_map.filename = ReplaceBitmap (newMat.texmap_bump.normal_map.filename) replace_name "Normal_DirectX"
						)
						catch
						(
							-- if texture not found, remove it from the material
							newMat.texmap_bump = undefined
							newMat.texmap_bump_on = off
						)
					)
				)
				catch()
			)
			
			-- Metal
			if newMat.texmap_metalness != undefined then
			(
				try
				(
					newMat.texmap_metalness.filename = ReplaceBitmap (newMat.texmap_metalness.filename) replace_name "Metal"
				)
				catch
				(
					-- if texture not found, remove it from the material
					newMat.texmap_metalness = undefined
					newMat.reflection_metalness = 0
				)
			)
			
			-- Translucent
			if newMat.texmap_translucent != undefined then
			(
				try
				(
					newMat.texmap_translucent.filename = ReplaceBitmap (newMat.texmap_translucent.filename) replace_name "Translucency"
				)
				catch
				(
					-- if texture not found, remove it from the material
					newMat.texmap_translucent = undefined
				)
			)
			
			-- Opacity
			if newMat.texmap_opacity != undefined then
			(
				try
				(
					newMat.texmap_opacity.filename = ReplaceBitmap (newMat.texmap_opacity.filename) replace_name "Opacity"
				)
				catch
				(
					-- if texture not found, remove it from the material
					newMat.texmap_opacity = undefined
				)
			)
			
			-- Return material with changed filenames 
			return newMat
		)
	)
	
	for obj in selection do
	(
		-- Change name of material to match object name
		obj.mat.name = obj.name
		
		-- Swap bitmaps in Vray Material
		if classof obj.mat == VRayMtl do
		(
			ReplaceVrayMat obj.name obj.mat
		)
		
		-- Swap bitmaps in Multi-Sub material
		if classof obj.mat == multiSubMaterial do
		(
			for i in (getClassInstances multiSubMaterial target:obj) do
			(
				for n = 1 to i.numsubs do
				(
					-- Replace sub material bitmaps
					local subMat = i[n]
					subMat = ReplaceVrayMat obj.name subMat
					
					-- Set name to Material name + Multi-Sub "Name" eg. 3DC_KISB_Plant = ID1: 3DC_KISB_Plant_Leaves, ID2: 3DC_KISB_Pot etc.
					subMat.name = i.name + "_" + i.names[n]
				)
			)
		)
	)
	
	
	
	undo off
	
	-- refresh asset tracker
	ATSOps.Refresh()
	
)
