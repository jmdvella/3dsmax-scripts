/*
Author: James Vella
Website: http://www.jamesvella.net/
Name-US: JV_Rotate180X
Version: 2.0
Software: 3D Studio Max 2021.3
Engine: Corona 7.0
Language: Maxscript
Description-US: Rotate object 180 degrees on the X axis
*/

macroScript Rotate180X
	category:"Vella" 
	internalcategory:"Automate"
	tooltip:"Rotate 180 X"
	buttonText:"Rotate 180 X"
	Icon:#("UVWUnwrapModes",4)
(
	try
	(
		for obj in $ do
		(
			if isGroupHead(obj) or not isGroupMember(obj) then
			(
				rotate obj (angleaxis 180 [1,0,0])
			)
		)
		redrawViews()
	)
	catch()
)