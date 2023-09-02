/*
Author: James Vella
Website: http://www.jamesvella.net/
Name-US: JV_CameraClipping
Version: 2.0
Software: 3D Studio Max 2021.3
Engine: V-Ray 5.20.23
Language: Maxscript
Description-US: Toggle Camera Clipping 0, 100, 200, 300, off
*/

macroScript CameraClipping
	category:"Vella" 
	internalcategory:"Automate"
	tooltip:"Camera Clipping"
	buttonText:"Camera Clipping"
	Icon:#("CamP",1)
(
	try
	(
		currentCam = getActiveCamera()

		if currentCam.clip_on == off then
		(
			currentCam.clip_on = on
			currentCam.clip_near = 0
		)
		else
		(
			if currentCam.clip_near >= 0 and currentCam.clip_near < 100 then
			(
				currentCam.clip_near = 100
			)
			else if currentCam.clip_near == 100 then
			(
				currentCam.clip_near = 200
			)
			else if currentCam.clip_near == 200 then
			(
				currentCam.clip_near = 300
			)
			else if currentCam.clip_near == 300 then
			(
				currentCam.clip_on = off
			)
			else if currentCam.clip_near == -100 then
			(
				currentCam.clip_near = 0
			)
			else if currentCam.clip_near == -200 then
			(
				currentCam.clip_near = -100
			)
			else if currentCam.clip_near == -300 then
			(
				currentCam.clip_near = -200
			)
			else if currentCam.clip_near == -400 then
			(
				currentCam.clip_near = -300
			)
			else if currentCam.clip_near == -500 then
			(
				currentCam.clip_on = on
				currentCam.clip_near = 0
			)
		)
	)
	catch()
)