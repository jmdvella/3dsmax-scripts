/*
Author: James Vella
Website: http://www.jamesvella.net/
Name-US: JV_Rotate180Z
Version: 2.0
Software: 3D Studio Max 2021.3
Engine: V-Ray 5.20.23
Language: Maxscript
Description-US: Rotate Selected Object 180 Degrees on the Z Axis
*/

macroscript Rotate180Z
	category:"Vella" 
	internalcategory:"Automate"
	tooltip:"Rotate 180 Z"
	buttonText:"Rotate 180 Z"
	Icon:#("UVWUnwrapModes",3)
(
	try
	(
		for obj in $ do
		(
			if isGroupHead(obj) or not isGroupMember(obj) then
			(
				rotate obj (angleaxis 180 [0,0,1])
			)
		)
		redrawViews()
	)
	catch()
)