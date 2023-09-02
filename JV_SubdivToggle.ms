/*
Author: James Vella
Website: http://www.jamesvella.net/
Name-US: JV_SubdivToggle
Version: 1.0
Software: 3D Studio Max 2021.3
Engine: V-Ray 5.20.23
Language: Maxscript
Description-US: Toggle Subdivision Modifier on/off based on render iterations
*/

macroscript SubdivToggle
	category:"Vella" 
	internalcategory:"Automate"
	tooltip:"SubDiv Toggle"
	buttonText:"SubDiv Toggle"
	Icon:#("AtmosApp",3)
(
	for obj in objects do
	(
		for o in (getClassInstances OpenSubdiv target:obj) + (getClassInstances Turbosmooth target:obj) + (getClassInstances meshsmooth target:obj) do 
		(
			-- Store Render Iterations to variable for toggle on/off
			local iters = o.iterations 
			local render_iters = o.renderIterations
				
			if o.useRenderIterations == on do
			(
				if iters == 0 then
				(
					o.iterations = render_iters
				)
				else
				(
					o.iterations = 0
				)
			)
		)
	)
)
