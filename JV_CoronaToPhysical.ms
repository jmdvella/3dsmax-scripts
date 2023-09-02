/*
Author: James Vella
Website: http://www.jamesvella.net
Name-US: JV_CoronaToPhysical
Version: 1.8
Software: 3D Studio Max 2021.3
Engine: Corona 7.0
Language: Maxscript
Description-US: Convert Corona Physical Materials to Autodesk Physical Materials 
*/

undo on

with animate off 
(
	-- Function to replace CoronaBitmap with Standard Bitmap
	fn convertCoronaBitmapToStandard =
	(
		-- Replace CoronaBitmap with Standard Bitmap
		for i in getClassInstances CoronaBitmap target:rootnode do
		(
			-- New variable for Standard Bitmap
			local newBitmap = BitmapTexture()
			
			-- Check if Bitmap gamma is set to 1.0
			if i.gamma == 1.0 then
			(
				-- Open the bitmap file with the specified gamma value (works for stripped paths)
				newBitmap.bitmap = openBitmap (filenameFromPath i.filename) gamma:i.gamma
			)

			-- Assign the filename of the CoronaBitmap to the new BitmapTexture
			newBitmap.filename = i.filename

			-- Restore the original name to the new BitmapTexture
			newBitmap.name = i.name
			
			-- Set Corona Bitmap Settings
			newBitmap.coords.realWorldScale = i.realWorldScale
			newBitmap.coords.blur = i.filteringBlur
			newBitmap.coords.U_Offset = i.uvwOffset[1]
			newBitmap.coords.V_Offset = i.uvwOffset[2]
			newBitmap.coords.U_Tiling = i.uvwScale[1]
			newBitmap.coords.V_Tiling = i.uvwScale[2]
			newBitmap.coords.W_angle = i.wAngle
			newBitmap.apply = i.clippingOn
			newBitmap.clipu = i.clippingU
			newBitmap.clipv = i.clippingV
			newBitmap.clipw = i.clippingWidth
			newBitmap.cliph = i.clippingHeight
			newBitmap.alphaSource = i.alphaSource
			newBitmap.monoOutput = i.monoChannelOutput
			newBitmap.rgbOutput = i.rgbChannelOutput
			newBitmap.output.invert = i.output.invert
			newBitmap.output.clamp = i.output.clamp 
			--newBitmap.output.alphaFromRGB = i.alphaFromRGB
			newBitmap.output.output_amount = i.output.output_amount
			newBitmap.output.rgb_offset = i.output.rgb_offset
			newBitmap.output.rgb_level = i.output.rgb_level
			newBitmap.output.bump_amount = i.output.bump_amount

			-- Replace the CoronaBitmap with the new BitmapTexture
			replaceInstances i newBitmap
		)
		
		-- Check through CoronaNormal nodes to see if the 'Add gamma to input' checkbox is enabled
		for i in getClassInstances CoronaNormal target:rootnode do
		(
			-- If the Bump / Normal Bump is using a Bitmap
			if (i.normalMap != undefined) then
			(
				-- If CoronaNormal using 'Add gamma to input' checkbox
				if (i.addGamma == on) then
				(
					-- filenameFromPath copies only "myImage.jpg" instead of full path so (works for stripped paths)
					n = openBitmap (filenameFromPath i.normalMap.filename) gamma:1.0
					
					-- copy Bitmap filename
					n.filename = i.normalMap.filename
					
					-- Assign Bitmap gamma 1.0
					n.gamma = 1.0
					
					-- Replace the Normal Map Bitmap with the updated gamma 1.0 (reload Bitmap)
					i.normalMap.bitmap = n 
				)
			)
		)
	)
	
	-- Function to replace Corona Mtl with Physical Mtl
	fn convertToPhysicalMtl oldMat =
	(
		-- Standard Material Settings for Autdoesk Physical Mtl
		newMat = PhysicalMaterial()
		newMat.name = oldMat.name
		
		-- Convert CoronaBitmaps to Standard Bitmap
		convertCoronaBitmapToStandard()
		
		-- Diffuse 
		try
		(	
			-- Copy Base Color Weight value
			if (oldMat.baseLevel != 1.0) then
			(
				newMat.base_weight = oldMat.baseLevel
			)
			
			-- If there is a bitmap texture
			if (oldMat.baseTexmap != undefined) then
			(
				-- Copy bitmap from Corona Mtl
				newMat.base_color_map = oldMat.baseTexmap
			)
			
			-- Replace Diffuse Color Swatch if not using default color swatch
			if (oldMat.basecolor != color 128 128 128 255) then
			(
				newMat.base_color = oldMat.basecolor
			)
		)
		catch()
		
		-- Roughness 
		try
		(
			-- Set the Roughness/Glossiness value to match Corona Mtl value
			newMat.roughness = oldMat.baseRoughness
			
			-- If there is a bitmap texture
			if (oldMat.baseRoughnessTexmap != undefined) then
			(
				-- Copy bitmap from Corona Mtl
				newMat.roughness_map = oldMat.baseRoughnessTexmap
			)
			
			-- If Corona Mtl is using Reflection Glossiness 
			if (oldMat.roughnessMode == 1) then 
			(
				-- Set Physical Material settings to use Glossiness mode.
				newMat.roughness_inv = on
			)
		)
		catch()
		
		-- Opacity 
		try
		(
			-- If there is a bitmap texture
			if (oldMat.opacityTexmap != undefined) then
			(
				-- Copy bitmap from Corona Mtl
				newMat.cutout_map = oldMat.opacityTexmap
			)
		)
		catch()
		
		-- Bump  
		try
		(
			-- Copy Bump Amount value
			newMat.bump_map_amt = oldMat.baseBumpMapAmount
			
			-- If there is a bitmap texture
			if (oldMat.baseBumpTexmap != undefined) then
			(
				-- Copy from Bump node
				newMat.bump_map = oldMat.baseBumpTexmap
				
				-- If the Bump is a Normal Bump
				if (oldMat.baseBumpTexmap.normalMap != undefined) then
				(
					-- Create Physical Normal node
					newMat.bump_map = Normal_Bump ()
					
					-- Copy bitmap from Corona Mtl
					newMat.bump_map.normal_map = oldMat.baseBumpTexmap.normalMap
					
					-- Copy Strength Multiplier
					newMat.bump_map.mult_spin = oldMat.baseBumpTexmap.multiplier
					
					-- Copy Normal Bump settings
					newMat.bump_map.flipred = oldMat.baseBumpTexmap.flipred
					newMat.bump_map.flipgreen = oldMat.baseBumpTexmap.flipgreen
					newMat.bump_map.swap_rg = oldMat.baseBumpTexmap.swapRedGreen

					-- If Additional Bump texture in Normal Bump node then copy bitmap
					if (oldMat.baseBumpTexmap.additionalBump != undefined) then
					(
						-- Copy bitmap from Corona Mtl
						newMat.bump_map.bump_map = oldMat.baseBumpTexmap.additionalBump
						
						-- Copy Strength Multiplier
						newMat.bump_map.bump_spin = oldMat.baseBumpTexmap.additionalBumpStrength
					)
				)
			)
		)
		catch()
		
		-- Metal 
		try
		(
			-- If metal is using a bitmap
			if (oldMat.metalnessTexmap != undefined) then
			(
				-- Copy bitmap from Corona Mtl
				newMat.metalness_map = oldMat.metalnessTexmap
			)
			
			-- If metal using a numeric value instead of a bitmap
			if (oldMat.metalnessMode == 1) then
			(
				-- Set Metalness in Physical to 1.0
				newMat.metalness = 1
			)
		)
		catch()	
		
		-- Displacement 
		try
		(
			-- If there is a bitmap texture
			if (oldMat.displacementTexmap != undefined) then
			(
				-- Copy bitmap from Corona Mtl
				newMat.displacement_map = oldMat.displacementTexmap
				
				-- Set displacement value if not default of 1.0
				if (oldMat.displacementMaximum != 1) then
				(
					newMat.displacement_map_amt = oldMat.displacementMaximum
				)
			)
		)
		catch()
		
		-- IOR 
		try
		(
			-- Apply IOR value
			newMat.trans_ior = oldMat.baseIor
			
			-- If there is a bitmap texture
			if (oldMat.baseIor != undefined) then
			(
				-- Copy bitmap from Corona Mtl
				newMat.trans_ior_map = oldMat.baseIorTexmap
			)
		)
		catch()
		
		-- Anisotropy
		try
		(
			-- Copy Anisotropy Amount numerical value
			if oldMat.baseAnisotropy != 0 then
			(
				newMat.anisotropy = ((((oldMat.baseAnisotropy + 1) / 2) * 99.99) + 0.01)
				
				-- Copy Anisotropy Rotation numerical value (270 is a 0.75 offset to match the Corona Material rotation)
				newMat.anisoangle = ((oldMat.baseAnisoRotation - 270) / 360.0)
			)
			
			-- Copy Anisotropy Amount bitmap
			if (oldMat.baseAnisotropyTexmap != undefined) then
			(
				-- Copy bitmap from Corona Mtl
				newMat.anisotropy_map = oldMat.baseAnisotropyTexmap
			)
			
			-- Copy Anisotropy Rotation bitmap
			if (oldMat.baseAnisoRotationTexmap != undefined) then
			(
				-- Copy bitmap from Corona Mtl
				newMat.aniso_angle_map = oldMat.baseAnisoRotationTexmap
				
				-- Convert Corona Bitmap to Standard Bitmap
				newMat.aniso_angle_map = convertCoronaBitmapToStandard(oldMat.baseAnisoRotationTexmap)
			)
			
		)
		catch() 
		
		-- Self-Illumination
		try
		(
			-- Set Emission color to match Self-Illumination color
			if (oldMat.selfIllumColor != color 255 255 255) then
			(
				-- Set Emission color to match Self-Illumination color
				newMat.emit_color = oldMat.selfIllumColor
				
				-- If illumination color set but Multiplier is 0.0 set Emission to 0.0 numeric value 
				if (oldMat.selfIllumLevel == 0) then
				(
					newMat.emission = 0
				)
			)
			
			-- If there is a bitmap texture
			if (oldMat.selfIllumTexmap != undefined) then
			(
				-- Copy bitmap from Corona Mtl
				newMat.emit_color_map = oldMat.selfIllumTexmap
				
				-- Set the Emission Value to the Self-Illumination value
				newMat.emission = oldMat.selfIllumLevel
			)
			else
			(
				-- Set the Emission to default (black/off) if Self-Illumination Multiplier is 0.0
				if (oldMat.selfIllumLevel != 0) then
				(
					-- Set Emission value to match Self-Illumination value
					newMat.emission = oldMat.selfIllumLevel
				)
			)
		)
		catch()
		
		-- Refraction
		try
		(
			-- If there is a bitmap texture
			if (oldMat.refractionAmountTexmap != undefined) then
			(
				-- Copy Refraction bitmap from Corona Mtl to Transparency in Physical
				newMat.transparency_map = oldMat.refractionAmountTexmap
			)
			
			-- If Refraction is not 0.0
			if (oldMat.refractionAmount != 0) then
			(
				newMat.transparency = oldMat.refractionAmount
			)
			
			-- If Corona Mtl using 'Thin shell'
			if (oldMat.useThinMode == on) then
			(
				newMat.thin_walled = on
			)
		)
		catch()
		
		-- Clearcoat
		try
		(		
			-- Set the Clearcoat Amount
			if (oldMat.clearcoatAmount != 0) then
			(
				newMat.coating = oldMat.clearcoatAmount
			)
			
			-- If there is a bitmap texture
			if (oldMat.clearcoatAmountTexmap != undefined) then
			(
				-- Copy bitmap from Corona Mtl
				newMat.coat_map = oldMat.clearcoatAmountTexmap
			)
		)
		catch()
		
		-- Clearcoat IOR
		try
		(
			newMat.coat_ior = oldMat.clearcoatIor
		)
		catch()
		
		-- Clearcoat Coating Bump 
		try
		(
			-- Set the Clearcoat Bump Amount 
			newMat.clearcoat_bump_map_amt = oldMat.clearcoatBumpMapAmount
			
			if (oldMat.clearcoatBumpTexmap != undefined) then
			(
				-- Copy bitmap from Corona Mtl
				newMat.coat_bump_map = oldMat.clearcoatBumpTexmap
			)
		)
		catch()
		
		-- Clearcoat Roughness
		try
		(
			-- If Clearcoat Roughness is not default 0.0 numeric value set Physical Clearcoat numeric value
			if (oldMat.clearcoatRoughness != 0) then
			(
				newMat.coat_roughness = oldMat.clearcoatRoughness
			)
			
			-- If there is a bitmap texture
			if (oldMat.clearcoatRoughnessTexmap != undefined) then
			(
				-- Copy bitmap from Corona Mtl
				newMat.coat_rough_map = oldMat.clearcoatRoughnessTexmap
			)
			
			-- If Corona Advanced Reflection is set to Glossiness
			if (oldMat.roughnessMode == 1) then 
			(
				-- Set Physical Clearcoat to Glossiness
				newMat.coat_roughness_inv = on
			)
		)
		catch()
		
		-- Convert Corona Mtl to Physical Mtl  
		oldMat = newMat
	)
	
	--
	-- Execute convertToPhysicalMtl function scene wide
	--

	-- Search through all scene materials and convert Corona Physical Mtl to Autodesk Physical Mtl
	for i in getClassInstances CoronaPhysicalMtl target:rootnode do
	(
		p = convertToPhysicalMtl i
		replaceInstances i p
	)
	
	-- Refresh asset tracker
	ATSOps.Refresh()
)
