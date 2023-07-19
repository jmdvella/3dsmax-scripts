/*
Author: James Vella
Website: http://www.jamesvella.net/
Name-US: JV_PhysicalToCorona
Version: 2.1
Software: 3D Studio Max 2021.3
Engine: Corona 7.0
Language: Maxscript
Description-US: Convert Autodesk Physical Materials to Corona Physical Materials
*/

macroscript PhysicalToCorona
	category:"Vella" 
	internalcategory:"Automate"
	tooltip:"Automate PhysicalToCorona"
	buttonText:"PhysicalMtl To CoronaMtl"
	Icon:#("GameTools",2)

(
	undo on
		
	with animate off 
	(

		-- Function to recursively apply Gamma 1.0 to Bitmap
		fn applyGammaCorrection i =
		(
			-- Check if the input is a bitmap
			if isKindOf i BitmapTexture do
			(
				-- Apply Gamma 1.0 to the bitmap
				i.bitmap = openBitmap i.bitmap.filename gamma:1.0
			)

			-- Check if the input has sub-properties
			if i.numsubs > 0 do
			(
				-- Traverse the sub-properties
				for j = 1 to i.numsubs do
				(
					-- Recursively apply gamma correction to sub-properties
					applyGammaCorrection i[j]
				)
			)

			-- Return the input unchanged
			i
		)

		-- Function to replace Physical Mtl with Corona Mtl
		fn convertToCoronaMtl oldMat =
		(
			-- Standard Material Settings for Physical Corona Mtl
			newMat = CoronaPhysicalMtl()
			newMat.name = oldMat.name
			
			-- Replace Diffuse 
			try
			(
				-- Copy Base Color Weight value
				if (oldMat.base_weight != 1.0) then
				(
					newMat.baseLevel = oldMat.base_weight
				)
				
				-- If there is a bitmap texture
				if (oldMat.base_color_map != undefined) then
				(
					-- Copy bitmap from Physical Mtl
					newMat.baseTexmap = oldMat.base_color_map
				)
				
				-- Replace Diffuse Color Swatch if not using default color swatch
				if (oldMat.base_color != color 127.5 127.5 127.5 255) then
				(
					newMat.basecolor = oldMat.base_color
				)
			)
			catch()
			
			-- Replace Roughness 
			try
			(
				-- Set the Roughness/Glossiness value to match Physical Mtl value
				newMat.baseRoughness = oldMat.roughness
				
				-- If there is a bitmap texture
				if (oldMat.roughness_map != undefined) then
				(
					-- Copy bitmap from Physical Mtl
					newMat.baseRoughnessTexmap = oldMat.roughness_map
				
					-- Apply Gamma 1.0 from applyGammaCorrection function
					applyGammaCorrection oldMat.roughness_map
				)
				
				-- If Physical Mtl is using Reflection Glossiness 
				if (oldMat.roughness_inv == on) then 
				(
					-- Set Advanced Corona Material settings to use Glossiness mode.
					newMat.roughnessMode = 1
				)
			)
			catch()
			
			-- Replace Opacity 
			try
			(
				-- If there is a bitmap texture
				if (oldMat.cutout_map != undefined) then
				(
					-- Copy bitmap from Physical Mtl
					newMat.opacityTexmap = oldMat.cutout_map
					
					-- Apply Gamma 1.0 from applyGammaCorrection function
					applyGammaCorrection oldMat.cutout_map
				)
			)
			catch()

			-- Replace Bump  
			try
			(
				-- If there is a bitmap texture
				if (oldMat.bump_map != undefined) then
				(
					-- Copy from Bump node
					newMat.baseBumpTexmap = oldMat.bump_map
					
					-- If the Bump is a Normal Bump
					if (oldMat.bump_map.normal_map != undefined) then
					(
						-- Create Corona Normal node
						newmat.baseBumpTexmap = CoronaNormal ()
						
						-- Copy bitmap from Physical Mtl
						newmat.baseBumpTexmap.normalMap = oldMat.bump_map.normal_map
						
						-- If Additional Bump texture in Normal Bump node then copy bitmap
						if (oldMat.bump_map.bump_map != undefined) then
						(
							newmat.baseBumpTexmap.additionalBump = oldMat.bump_map.bump_map
						)
					)
					
					-- Apply Gamma 1.0 from applyGammaCorrection function
					applyGammaCorrection oldMat.bump_map
				)
			)
			catch()
			
			-- Replace Metal 
			try
			(
				-- If metal is using a bitmap
				if (oldMat.metalness_map != undefined) then
				(
					-- Change Physical Material to Metal type
					newMat.metalnessMode = 1
					
					-- Copy bitmap from Physical Mtl
					newMat.metalnessTexmap = oldMat.metalness_map
					
					-- Apply Gamma 1.0 from applyGammaCorrection function
					applyGammaCorrection oldMat.metalness_map
					
					-- If metal using a numeric value mixed with a bitmap
					if (oldMat.metalness > 0 and oldMat.metalness != 1) then
					(
						-- Create Output node in Corona Metal node
						newMat.metalnessTexmap = output ()
						
						-- Copy bitmap texture to Output bitmap node
						newMat.metalnessTexmap.map1 = oldMat.metalness_map
						
						-- Set numeric value from Physical to Corona Material in Output node
						newMat.metalnessTexmap.output.output_amount = oldMat.metalness
					)
				)
				
				-- If metal using a numeric value instead of a bitmap
				if (oldMat.metalness > 0 and oldMat.metalness != 1 and oldMat.metalness_map == undefined) then
				(
					-- Change Physical Material to Metal type
					newMat.metalnessMode = 1
					
					-- Create Output node in Corona Metal node
					newMat.metalnessTexmap = output ()
					
					-- Set numeric value from Physical to Corona Material in Output node
					newMat.metalnessTexmap.output.output_amount = oldMat.metalness
				)
				
				-- If metal set to 1.0 numeric value 
				if (oldMat.metalness == 1 and oldMat.metalness_map == undefined) then
				(
					-- Change Physical Material to Metal type
					newMat.metalnessMode = 1
				)
			)
			catch()
			
			-- Replace Displacement 
			try
			(
				-- If there is a bitmap texture
				if (oldMat.displacement_map != undefined) then
				(
					-- Copy bitmap from Physical Mtl
					newMat.displacementTexmap = oldMat.displacement_map
					
					-- Apply Gamma 1.0 from applyGammaCorrection function
					applyGammaCorrection oldMat.displacement_map
					
					-- Set displacement value if not default of 1.0
					if (oldMat.displacement_map_amt != 1) then
					(
						newMat.displacementMaximum = oldMat.displacement_map_amt
					)
				)
			)
			catch()
			
			-- Replace IOR 
			try
			(
				-- Apply IOR value
				newMat.baseIor = oldMat.trans_ior
				
				-- If there is a bitmap texture
				if (oldMat.trans_ior_map != undefined) then
				(
					-- Copy bitmap from Physical Mtl
					newMat.baseIorTexmap = oldMat.trans_ior_map
					
					-- Apply Gamma 1.0 from applyGammaCorrection function
					applyGammaCorrection oldMat.trans_ior_map
				)
			)
			catch()
			
			-- Replace Anisotropy
			try
			(
				-- Copy Anisotropy Value
				if oldMat.anisotropy != 1 then
				(
					newMat.baseAnisotropy = ((((oldMat.anisotropy - 0.01) / 99.99) * 2) - 1)
				)
				
				-- Copy Anisotropy Rotation (270 is a 0.75 offset to match the Physical Material rotation)
				newMat.baseAnisoRotation = (oldMat.anisoangle * 360 + 270)
				
				-- If there is a bitmap texture
				if (oldMat.anisotropy_map != undefined) then
				(
					-- Copy bitmap from Physical Mtl
					newMat.baseAnisotropyTexmap = oldMat.anisotropy_map
					
					-- Apply Gamma 1.0 from applyGammaCorrection function
					applyGammaCorrection oldMat.anisotropy_map
				)
			)
			catch() 
			
			-- Replace Emission
			try
			(
				-- If there is a bitmap texture
				if (oldMat.emit_color_map != undefined) then
				(
					-- Copy bitmap from Physical Mtl
					newMat.selfIllumTexmap = oldMat.emit_color_map
					
					-- Apply Gamma 1.0 from applyGammaCorrection function
					applyGammaCorrection oldMat.emit_color_map
					
					-- Set the self-illumination level to the emission value
					newMat.selfIllumLevel = oldMat.emission
				)
				else
				(
					-- Set the self-illumination level to 0 if there is no bitmap
					newMat.selfIllumLevel = if (oldMat.emit_color != color 0 0 0 255) then oldMat.emission else 0
				)
				
				-- If the Emission color is not black
				if (oldMat.emit_color != color 0 0 0 255) then
				(
					-- Copy Emission color to Self-Illumination color
					newMat.selfIllumColor = oldMat.emit_color
				)
			)
			catch()
			
			-- Replace Clearcoat
			try
			(
				-- Clearcoat Amount
				
				-- Set the Clearcoat Amount if there is no bitmap
				if (oldMat.coating != 0) then
				(
					newMat.clearcoatAmount = oldMat.coating
				)
				
				-- If there is a bitmap texture
				if (oldMat.coat_map != undefined) then
				(
					-- Copy bitmap from Physical Mtl
					newMat.clearcoatAmountTexmap = oldMat.coat_map
					
					-- Apply Gamma 1.0 from applyGammaCorrection function
					applyGammaCorrection oldMat.coat_map
				)
			)
			catch()
			
			try
			(
				-- Clearcoat IOR
				newMat.clearcoatIor = oldMat.coat_ior
			)
			catch()
			
			try
			(
				-- Clearcoat Coating Bump 
				if (oldMat.coat_bump_map != undefined) then
				(
					newMat.clearcoatBumpTexmap = oldMat.coat_bump_map
					
					-- Apply Gamma 1.0 from applyGammaCorrection function
					applyGammaCorrection oldMat.coat_bump_map
				)
			)
			catch()
			
			try
			(
				-- Clearcoat Roughness
				
				-- If there is a bitmap texture
				if (oldMat.coat_rough_map != undefined) then
				(
					-- If Reflection is set to Roughness and Clearcoat is set to Roughness
					if (oldMat.roughness_inv == off) and (oldMat.coat_roughness_inv == off) then 
					(
						-- Copy bitmap from Physical Mtl
						newMat.clearcoatRoughnessTexmap = oldMat.coat_rough_map
					)
					
					-- If Reflection is set to Roughness and Clearcoat is set to Glossiness
					if (oldMat.roughness_inv == off) and (oldMat.coat_roughness_inv == on) then 
					(
						-- Place Color Correction node in Cleatcoat Glossiness
						ccnode = ColorCorrection()
						newMat.clearcoatRoughnessTexmap = ccnode
						
						-- Copy bitmap from Physical Mtl
						ccnode.map = oldMat.coat_rough_map
						
						-- Setup Color Correction Settings (invert Channels) 
						ccnode.rewireMode = 2
						ccnode.name = "Invert_Roughness"
					)
					
					-- If Reflection is set to Glossiness and Clearcoat is set to Glossiness
					if (oldMat.roughness_inv == on) and (oldMat.coat_roughness_inv == on) then 
					(
						-- Copy bitmap from Physical Mtl
						newMat.clearcoatRoughnessTexmap = oldMat.coat_rough_map
					)
					
					-- If Reflection is set to Glossiness and Clearcoat is set to Roughness
					if (oldMat.roughness_inv == on) and (oldMat.coat_roughness_inv == off) then 
					(
						-- Place Color Correction node in Cleatcoat Glossiness
						ccnode = ColorCorrection()
						newMat.clearcoatRoughnessTexmap = ccnode
						
						-- Copy bitmap from Physical Mtl
						ccnode.map = oldMat.coat_rough_map
						
						-- Setup Color Correction Settings (invert Channels) 
						ccnode.rewireMode = 2
						ccnode.name = "Invert_Roughness"
					)
					
					-- Apply Gamma 1.0 from applyGammaCorrection function
					applyGammaCorrection oldMat.coat_rough_map
				)
				else
				(
					-- Set the Clearcoat Roughness if there is no bitmap
					
					-- If Reflection is set to Roughness and Clearcoat is set to Roughness
					if (oldMat.roughness_inv == off) and (oldMat.coat_roughness_inv == off) then 
					(
						newMat.clearcoatRoughness = oldMat.coat_roughness
					)
					
					-- If Reflection is set to Roughness and Clearcoat is set to Glossiness
					if (oldMat.roughness_inv == off) and (oldMat.coat_roughness_inv == on) then 
					(
						newMat.clearcoatRoughness = (1 - oldMat.coat_roughness)
					)
					
					-- If Reflection is set to Glossiness and Clearcoat is set to Glossiness
					if (oldMat.roughness_inv == on) and (oldMat.coat_roughness_inv == on) then 
					(
						newMat.clearcoatRoughness = oldMat.coat_roughness
					)
					
					-- If Reflection is set to Glossiness and Clearcoat is set to Roughness
					if (oldMat.roughness_inv == on) and (oldMat.coat_roughness_inv == off) then 
					(
						newMat.clearcoatRoughness = (1 - oldMat.coat_roughness)
					)
				)
			)
			catch()
			
			-- Convert Physical Mtl to Corona Mtl
			oldMat = newMat
		)

		--
		-- Execute convertToCoronaMtl function
		--

		-- Search through all scene materials
		for i in getClassInstances PhysicalMaterial do
		(
			p = convertToCoronaMtl i
			replaceInstances i p
		)

		-- Refresh asset tracker
		ATSOps.Refresh()
	)
)