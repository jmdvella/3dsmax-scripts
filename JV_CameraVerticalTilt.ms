/*
Author: James Vella
Website: http://www.jamesvella.net/
Name-US: JV_CameraVerticalTilt
Version: 2.0
Software: 3D Studio Max 2021.3
Engine: V-Ray 5.20.23
Language: Maxscript
Description-US: Toggle Camera Vertical Tilt on/off
*/

macroScript CameraVerticalTilt
	category:"Vella" 
	internalcategory:"Automate"
	tooltip:"Camera Vertical Tilt"
	buttonText:"Camera Vertical Tilt"
	Icon:#("Cameras",3)
(
	try
	(
		currentCam = getActiveCamera()
		select currentCam

		$.auto_vertical_tilt_correction = on
		$.auto_vertical_tilt_correction = off
	)
	catch()
)