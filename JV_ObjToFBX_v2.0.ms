/*
Author: James Vella
Website: http://www.jamesvella.net/
Name-US: JV_ObjToFBX
Version: 1.0
Software: 3D Studio Max 2021.3
Engine: V-Ray 5.20.23
Language: Maxscript
Description-US: Export FBX to Documents/3dsmax/export folder
*/

macroscript ObjToFBX
	category:"Vella" 
	internalcategory:"Automate"
	tooltip:"Automate ObjToFBX"
	buttonText:"Obj To FBX"
	Icon:#("CWS_Output",1)
(
	-- Get the 3ds Max version as an array
	local currentMaxVersion = maxVersion()

	-- Extract the year (assuming it's at the 9th position in the array)
	local year = currentMaxVersion[8] as string

	-- Export FBX

	for obj in selection do
	(	
		-- Switch off metallic for FBX
		-- if isKindOf obj.material Standardmaterial do
		-- (
			-- obj.material.reflectionMapEnable = on
			-- obj.material.reflectionMapAmount = 0
		-- )
		
		-- Assign filename to selected object
	 	local fname = obj.name

	 	exportFile (@"C:\Users\" + sysInfo.username + @"\Documents\" + "3ds Max " + year + 
			@"\export\" + fname + @".fbx") #noPrompt selectedOnly:true using:FBXEXP 
	)
)