/*
Author: James Vella
Website: http://www.jamesvella.net/
Name-US: JV_RoughToGloss 
Version: 1.0.0
Software: 3D Studio Max 2021.3
Engine: V-Ray 5.00.04
Language: Maxscript
Description-US: Convert Vray Roughness materials to Vray Glossiness
*/

macroscript RoughToGloss
	category:"Vella" 
	internalcategory:"Automate"
	tooltip:"Automate RoughToGloss"
	buttonText:"Rough To Gloss"
	Icon:#("SchematicView",1)

(
	-- Function to replace BRDF Glossiness to Roughness
	fn convert_to_glossiness i =
	(
		i.brdf_useRoughness = off
		
		-- Convert Roughness to Glossiness bitmap
		if i.texmap_reflectionGlossiness != undefined then
		(
			i.texmap_reflectionGlossiness.filename = substituteString i.texmap_reflectionGlossiness.filename "Roughness" "Glossiness"
		)
		
		-- Place BaseColor in Reflection, Remove Fresnsel (Metal), Set Diffuse to Black (Glossiness Metal Workflow)
		if i.texmap_metalness != undefined then
		(
			i.Diffuse = color 0 0 0
			i.texmap_reflection = i.texmap_diffuse
			i.texmap_diffuse = undefined
			i.reflection_fresnel = off
			i.texmap_metalness = undefined
		)
		
		return i
	)

	-- Function to replace VRay2SidedMtl with VrayMtl
		fn convert_Vray2Sided_to_VrayMtl i = 
		(
			newMat = i.frontMtl 
			
			-- Convert Vray to VrayMtl
			i = newMat
			
			-- Convert from VrayMtl to StandardMtl using convert_to_stdmtl Function
			convert_to_glossiness i
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
		-- Convert VrayMtl to BRDF Glossiness using convert_to_glossiness function
		if (classof i == VrayMtl) do 
		(
			p = convert_to_glossiness i
			
			if (i.name == p.name) and (i.name != undefined) do
			(
				replaceinstances i p
			)
		)
		-- Find Multi-Sub Materials
		if (classof i == Multimaterial) do 
		(
			-- Convert VrayMtl to BRDF Glossiness using convert_to_glossiness function
			for n in i do
			(
				if (classof n == VrayMtl) do 
				(
					p = convert_to_glossiness n
					
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