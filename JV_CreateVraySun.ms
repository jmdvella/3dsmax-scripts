/*
Author: James Vella
Website: http://www.jamesvella.net/
Name-US: JV_CreateVraySun
Version: 2.0
Software: 3D Studio Max 2021.3
Engine: V-Ray 5.20.23
Language: Maxscript
Description-US: Create Vray Sun, Disable black background on load (default gradient)
*/

macroScript CreateVraySun
	category:"Vella" 
	internalcategory:"Automate"
	tooltip:"Create Vray Sun"
	buttonText:"Create Vray Sun"
	Icon:#("Lights",2)
(
	-- Create Sun
	vrs = VRaySun name:"VRaySun01" isSelected:on pos:[90,0,100] target:(vrsTarget = Dummy())
		
	-- Create Sky linked to Sun
	useEnvironmentMap = on
	EnvironmentMap = VRaySky()
	EnvironmentMap.manual_sun_node = on
	EnvironmentMap.sun_node = vrs

	-- Reset Viewport to be Gradient
	viewport.SetRenderLevel #wireframe 				-- Switch to enable Background Gradient??
	viewport.EnableSolidBackgroundColorMode true	-- Switch to enable then disable??
	viewport.EnableSolidBackgroundColorMode false 	-- Set Background to Gradient
	viewport.SetRenderLevel #smooth 				-- Default Shading
	actionMan.executeAction -844228238 "13" 		-- Standard Shading
	completeRedraw() 
)
