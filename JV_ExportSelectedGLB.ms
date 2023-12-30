
macroScript ExportSelectedGLB
	category:"Vella" 
	internalcategory:"Automate"
	tooltip:"Export Selected GLB"
	buttonText:"Export Selected GLB"
	Icon:#("Containers",15)

(
	/*
	Author: James Vella
	Website: http://www.jamesvella.net/
	Name-US: JV_ExportSelectedGLB
	Version: 3.1
	Software: 3D Studio Max 2024.1
	Engine: GLTF/GLB
	Language: Maxscript
	Description-US: Export selected objects directly to .glb, no prompts, 
					overwrite previous, naming based on object name.
	*/


	for obj in selection do
	(
		-- Isolate the current object
		hide selection
		unhide obj

		-- Reset rotation/position
		obj.rotation = eulerangles 0 0 0
		oldPosition = obj.position
		obj.position = [0,0,0]

		local exportPath = (@"C:\Users\" + sysInfo.username + @"\Desktop\" + obj.name + ".glb")
		
		-- Export the isolated object to its own .glb file
		exportFile exportPath #noPrompt selectedOnly:true using:GLTF_Export
		
		obj.position = oldPosition

		-- Unhide all objects again
		unhide selection
		
		-- Optionally, delete the log file
		deleteFile (exportPath + ".log")
		
	)
)
