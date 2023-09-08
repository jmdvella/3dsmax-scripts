/*
Author: James Vella
Website: http://www.jamesvella.net/
Name-US: JV_ShowShadedInViewportCorona
Version: 1.0
Software: 3D Studio Max 2024
Engine: Corona 10
Language: Maxscript
Description-US: Show Shaded CoronaMtl In Viewport
*/
macroscript ShowShadedMtlCorona
	category:"Vella" 
	internalcategory:"Automate"
	tooltip:"Automate Show Shaded CoronaMtl"
	buttonText:"Show Shaded CoronaMtl In Viewport"
	Icon:#("Material_Modifiers",6)
(
	undo on
		
	for obj in selection do
	(
		for i in getClassInstances CoronaPhysicalMtl do
		(
			-- Enable "Show Shaded..." for Diffuse texture instead of Material
			if i.baseTexmap != undefined do
			(
				for b in (getClassInstances Bitmaptexture target:i.baseTexmap) + (getClassInstances CoronaBitmap target:i.baseTexmap) do 
				(
					showTextureMap i b On
					exit
				)
			)
			-- If material using vraycolor enable "Show Shaded..." for Material
			if classof i.baseTexmap == CoronaColor do
			(
				i.showInViewport = on
			)
			-- If material using opacity enable "Show Shaded..." for Material
			if i.opacityTexmap != undefined do
			(
				i.showInViewport = on
			)
		)
		
		for i in getClassInstances CoronaLegacyMtl do
		(
			-- Enable "Show Shaded..." for Diffuse texture instead of Material
			if i.texmapDiffuse != undefined do
			(
				for b in (getClassInstances Bitmaptexture target:i.texmapDiffuse) + (getClassInstances CoronaBitmap target:i.texmapDiffuse) do 
				(
					showTextureMap i b On
					exit
				)
			)
			-- If material using vraycolor enable "Show Shaded..." for Material
			if classof i.texmapDiffuse == CoronaColor do
			(
				i.showInViewport = on
			)
			-- If material using opacity enable "Show Shaded..." for Material
			if i.texmapOpacity != undefined do
			(
				i.showInViewport = on
			)
		)
	)
)