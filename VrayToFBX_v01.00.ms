/*
3dsmax to Blender FBX Material Converter 
jmdvella@gmail.com
2022
*/

macroscript VrayToFBX
	category:"Vella" 
	internalcategory:"Automate"
	tooltip:"Automate VrayToFBX"
	buttonText:"Vray To FBX"
	Icon:#("SchematicView",2)

(
	-- Function to replace Vray with Standard and setup PBR settings for FBX/Blender
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
		)
		
		-- Replace Opacity
		if i.texmap_opacity != undefined then
		(
			newMat.opacityMap = i.texmap_opacity
		)
		
		-- Replace Normal texture
		if i.texmap_bump != undefined then
		(
			newMat.bumpMap = i.texmap_bump.normal_map
		)
		
		-- Convert DirectX Normal texture to OpenGL (Optional) 	<--------------
		if i.texmap_bump != undefined then
		(
			i.texmap_bump.normal_map.filename = substituteString i.texmap_bump.normal_map.filename "DirectX" "OpenGL"
		)
		
		-- Convert Vray to Standard Mtl
		i = newMat

	)
	
	-- Function to replace VRay2SidedMtl with VrayMtl
	fn convert_Vray2Sided_to_VrayMtl i = 
	(
		newMat = i.frontMtl 
		
		-- Convert Vray to VrayMtl
		i = newMat
		
		-- Convert from VrayMtl to StandardMtl using convert_to_stdmtl Function
		convert_to_stdmtl i
	)
	
	-- Find all VRay2SidedMtl and replace with VrayMtl in the scene
	for i in sceneMaterials do
	(
		if (classof i == VRay2SidedMtl) do
		(
			p = convert_Vray2Sided_to_VrayMtl i
			
			if (i.name == p.name) and (i.name != undefined) do
			(
				replaceinstances i p
			)
		)
	)		
	
	-- Find all VrayMtls and VrayMtls in Multi-Sub in the scene
	for i in sceneMaterials do
	(
		-- Convert VrayMtl to StandardMtl using convert_to_stdmtl function
		if (classof i == VrayMtl) do 
		(
			p = convert_to_stdmtl i
			
			if (i.name == p.name) and (i.name != undefined) do
			(
				replaceinstances i p
			)
			
		)
		
		-- Find Multi-Sub Materials
		if (classof i == Multimaterial) do 
		(
			-- Convert VrayMtl to StandardMtl using convert_to_stdmtl function
			for n in i do
			(
				if (classof n == VrayMtl) do 
				(
					p = convert_to_stdmtl n
					
					if (n.name == p.name) and (n.name != undefined) do
					(
						replaceInstances n p
					)
					
				)	
			) 
		)
	)
			
	-- refresh asset tracker
	ATSOps.Refresh()
)
