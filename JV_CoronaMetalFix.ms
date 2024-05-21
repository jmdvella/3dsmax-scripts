/*
Author: James Vella
Website: http://www.jamesvella.net
Name-US: JV_CoronaMetalFix
Version: 1.0
Software: 3D Studio Max 2021.3
Engine: Corona 7.0
Language: Maxscript
Description-US: Convert CoronaMix on Metal textures back to BaseColor - from automatic conversion
*/

for i in (getClassInstances CoronaMix target:rootnode ) do
( 
	p = i.texmapBottom 
	replaceInstances i p
)
