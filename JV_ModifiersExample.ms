	-- Switch to modifiers tab
	max modify mode

	-- Modifier
	theMod = Chamfer()
	-- Modifier Settings
	theMod.SmoothType = 1
	theMod.miteringType = 0
	theMod.amount = 0.25
	theMod.useminangle = off
	theMod.tension = 0.5
	theMod.smoothtoadjacent = on
	theMod.segments = 2

	-- Instance modifier on sub-object level or muiltiple objects
	if modPanel.validModifier theMod then modPanel.addModToSelection theMod
