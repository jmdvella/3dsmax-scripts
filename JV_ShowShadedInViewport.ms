/*
Author: James Vella
Website: http://www.jamesvella.net/
Name-US: JV_ShowShadedInViewport
Version: 1.0
Software: 3D Studio Max 2021.3
Engine: V-Ray 5.20.23
Language: Maxscript
Description-US: Show Shaded Mtl In Viewport for selected objects (Vray only)
*/

macroscript ShowShadedMtl
	category:"Vella" 
	internalcategory:"Automate"
	tooltip:"Automate Show Shaded Mtl"
	buttonText:"Show Shaded Mtl In Viewport"
	Icon:#("Material_Modifiers",6)
(
	undo on
		
	for obj in selection do
	(
		for i in getClassInstances VRayMtl do
		(
			-- Enable "Show Shaded..." for Diffuse texture instead of Material
			if i.texmap_diffuse != undefined do
			(
				for b in getClassInstances Bitmaptexture target:i.texmap_diffuse do 
				(
					showTextureMap i b On
					exit
				)
			)
			-- If material using vraycolor enable "Show Shaded..." for Material
			if classof i.texmap_diffuse == VRayColor do
			(
				i.showInViewport = on
			)
			-- If material using opacity enable "Show Shaded..." for Material
			if i.texmap_opacity != undefined do
			(
				i.showInViewport = on
			)
		)
	)
)