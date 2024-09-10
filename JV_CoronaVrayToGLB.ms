macroscript CoronaVrayToGLB
category:"Vella" 
tooltip:"Automate CoronaVrayToGLB"
buttonText:"Vray Corona To GLB"
Icon:"MassFX\CreateHingeConstraint"
(
    /*
    Author: James Vella
    Website: http://www.jamesvella.net/
    Name-US: CoronaVrayToGLB
    Software: 3D Studio Max 2024.2.3
    Engine: V-Ray 6.20.03, Corona 11
    Language: Maxscript
    Description-US: Convert Vray Corona PBR materials to GLTF material
    */ 

    ---------- Variables ----------

    scriptVersion = "2.0"
    renderEngine = ""
    findTextures = true
    renameGltfMaps = true
    hideWarningPopups = false
    exportSelectedObjs = true
    removeGlbLogFile = true
    convertSelectedMaterials = true
    theTarget = rootnode -- switch to obj for selected objects
    missingTex = #()

    currentMaxVersion = maxVersion()
    defaultExportDirectory = @"C:\Users\" + sysInfo.username + @"\Documents\3ds Max " + (currentMaxVersion[8] as string) + @"\export\"
    if not doesFileExist defaultExportDirectory do makeDir defaultExportDirectory

    savedSettings = getDir(#userScripts) + "\\Vella\\CoronaVrayToGLB_Settings.txt" 

    ---------- 3dsmax settings ----------

    animButtonState = false -- Turn off "Auto Key"

    ---------- Functions ----------

    ----------------------------------
    -- Find Missing Bitmaps
    ----------------------------------

    -- Search asset tracker and repath all "Found" assets to actual path
    fn RepathFoundAssets =
    (
        -- "File Missing" in Asset Tracker
        missingATSFiles = #()
        enumerateFiles (fn getNames name a = appendIfUnique a name) missingATSFiles #missing

        -- Print Missing Assets
        for i in missingATSFiles do
        (
            appendIfUnique missingTex (getFilenameFile i + ": File Missing. Check the Asset Tracker and resolve Status to Found or OK")
        )
            
        -- Combine arrays removing missing files
        allFiles = for foundBitmap in (getClassInstances Bitmaptexture) collect foundBitmap.filename
        foundFiles = for f in allFiles where not (findItem missingATSFiles f > 0) collect f
    
        -- Repath Found or OK assets
        for i in foundFiles where (foundFiles.count > 0) do
        (
            ATSOps.SelectFiles i
            ATSOps.ResolveSelectionToAbsolute()
        )
    )

    -- Search the material for textures -> check directory for matching name
    fn FindMissingTextures currentMaterial textureType = 
    (
        -- Find any bitmap in the material
        locatedBitmap = undefined
        for foundBitmap in (getClassInstances Bitmaptexture target:currentMaterial) do
        (
            -- Check if foundBitmap has a valid filename (ignore File Missing in Asset Tracker)
            if (doesFileExist foundBitmap.filename) then
            (
                -- Copy bitmap so we dont overwrite the filename
                locatedBitmap = copy foundBitmap
                exit 
            )
        )

        if locatedBitmap != undefined then
        (
            wordsToRemove = #("Diff", "Base", "BaseColor", "Color", "Albe", "Alph", "Opac", "Metal", "Rough", "AO", "Occlus", "AmbientO", "Emiss", "SelfIllum", "Norm")

            bitmapDir = getFilenamePath locatedBitmap.bitmap.filename
            bitmapName = getFilenameFile locatedBitmap.bitmap.filename
            bitmapExtension = getFilenameType locatedBitmap.bitmap.filename
            cleanedBitmapName = ""

            -- Search for textures and remove suffix
            regexPattern = "[-_]("  -- Match hyphen or underscore eg Sofa_Diffuse or Sofa-Diffuse
            for i = 1 to wordsToRemove.count do
            (
                regexPattern += wordsToRemove[i] + ".*"
                if i < wordsToRemove.count do regexPattern += "|"
            )
            regexPattern += ")$"
            regexReplace = dotNetObject "System.Text.RegularExpressions.Regex" regexPattern (dotNetClass "System.Text.RegularExpressions.RegexOptions").IgnoreCase
            cleanedBitmapName = regexReplace.Replace bitmapName ""

            -- Locate all textures in that directory and assign them to an array
            allBitmapsInDirectory = #() 
            for f in getFiles (bitmapDir + "*.*") do 
            ( 
                append allBitmapsInDirectory (getFilenameFile f) 
            )

            -- Now find a matching bitmap for the node type (diffuse, roughness etc)
            wordsToFind = #()
            case textureType of
            (
                "Diffuse": wordsToFind = #("Diff", "Base", "BaseColor", "Color", "Albe")
                "Alpha": wordsToFind = #("Alph", "Opac")
                "Metal": wordsToFind = #("Metal")
                "Roughness": wordsToFind = #("Rough")
                "Occlusion": wordsToFind = #("AO", "Occlus", "Ambient")
                "Emission": wordsToFind = #("Emiss", "Self", "Illum")
                "Normal": wordsToFind = #("Norm")
            )

            -- Replace suffix
            for bitmapName in allBitmapsInDirectory do
            (
                -- Loop through the words to find
                for word in wordsToFind do
                (
                    regexPattern = cleanedBitmapName + "[-_](" + word + ".*)$"  -- Match hyphen or underscore eg Sofa_Diffuse or Sofa-Diffuse
                    regexSearch = dotNetObject "System.Text.RegularExpressions.Regex" regexPattern (dotNetClass "System.Text.RegularExpressions.RegexOptions").IgnoreCase

                    if regexSearch.IsMatch(bitmapName) then
                    (
                        locatedBitmap.filename = (bitmapDir + bitmapName + bitmapExtension)
                        return locatedBitmap
                    )
                )
            )
        )

        return undefined
    )

    -- Search for bitmaps if findTexture == True
    fn SearchBitmapNodes currentMaterial bitmapNode textureType = 
    (
        locatedBitmap = undefined
        
        -- Look for bitmap in this node tree
        if bitmapNode != undefined then 
        ( 
            for foundBitmap in (getClassInstances Bitmaptexture target:bitmapNode) do  
            (
                locatedBitmap = foundBitmap
                return foundBitmap
            )
        )
        
        -- No bitmap found -> search directory for texture
        if (locatedBitmap == undefined) or (classof locatedBitmap != Bitmaptexture) then
        (
            locatedBitmap = FindMissingTextures currentMaterial textureType
            if locatedBitmap != undefined then 
            (
                return locatedBitmap
            )
            else
            (
                if (bitmapNode != alphaNode) or (bitmapNode != emissionNode) then 
                (
                    -- Did not find bitmap in the texture directory that matches (eg. texture dir search)
                    appendIfUnique missingTex (currentMaterial.name + " - Missing: " + textureType + " Texture") 
                )
            )
        )

        return undefined
    )

    ----------------------------------
    -- Convert Materials
    ----------------------------------

    -- Replaces the found bitmap from Corona/Vray to GLTF node (eg. BaseColor or Rough)
    fn ReplaceGLTFBitmap materialName materialMap bitmapNode bitmapType gammaValue gltfCompliant = 
    (
        if bitmapNode != undefined then 
        ( 
            -- Look for bitmap in this node tree
            for foundBitmap in (getClassInstances Bitmaptexture target:bitmapNode) do  
            ( 
                materialMap = foundBitmap 
                if doesFileExist materialMap.filename then
                (
                    materialMap.bitmap = openBitmap materialMap.filename gamma:gammaValue
                )
                if materialMap != undefined then return materialMap
            ) 
        ) 
    
        if (materialMap == undefined) and (gltfCompliant == "Required") then 
        (
            appendIfUnique missingTex (materialName + " - Missing: " + bitmapType + " Texture") 
            return undefined
        )
    )

    -- Function to convert Corona or VrayMtl to glTF material 
    fn ConvertToGltf currentMaterial = 
    ( 
        -- Basic settings for GLTF shader 
        newMaterial = undefined
        (
            if isKindOf (gltfMat = execute "glTFMaterial") Material do
            (
                newMaterial = gltfMat()
            )
        )

        if newMaterial != undefined then
        (
            newMaterial.name = currentMaterial.name 
        ) 
        else
        (
            messageBox ("Your 3dsmax version does not support GLTF.\n3dsmax 2023+ Required.")
            return undefined
        )
        
        -- Set material nodes based on render engine
        diffuseNode = undefined
        roughNode = undefined
        bumpNode = undefined
        normalNode = undefined
        metalNode = undefined
        alphaNode = undefined
        emissionNode = undefined
        occlusionNode = undefined

        if renderEngine == "Corona" then
        (
            diffuseNode = currentMaterial.baseTexmap
            roughNode = currentMaterial.baseRoughnessTexmap
            bumpNode = currentMaterial.baseBumpTexmap
            try(normalNode = currentMaterial.baseBumpTexmap.normalMap)catch()
            metalNode = currentMaterial.metalnessTexmap
            alphaNode = currentMaterial.opacityTexmap
            emissionNode = currentMaterial.selfIllumTexmap
        )

        if renderEngine == "Vray" then
        (
            diffuseNode = currentMaterial.texmap_diffuse
            roughNode = currentMaterial.texmap_reflectionGlossiness
            bumpNode = currentMaterial.texmap_bump
            try(normalNode = currentMaterial.texmap_bump.normal_map)catch()
            metalNode = currentMaterial.texmap_metalness
            alphaNode = currentMaterial.texmap_opacity
            emissionNode = currentMaterial.texmap_self_illumination
        )


        -- Search directory for textures
        if findTextures == true then
        (
            foundDiffuse = SearchBitmapNodes currentMaterial diffuseNode "Diffuse"
            if foundDiffuse != undefined then diffuseNode = foundDiffuse

            foundRough = SearchBitmapNodes currentMaterial roughNode "Roughness"
            if foundRough != undefined then roughNode = foundRough

            foundMetal = SearchBitmapNodes currentMaterial metalNode "Metal"
            if foundMetal != undefined then metalNode = foundMetal

            foundEmission = SearchBitmapNodes currentMaterial emissionNode "Emission"
            if foundEmission != undefined then emissionNode = foundEmission

            foundOcclusion = SearchBitmapNodes currentMaterial undefined "Occlusion"
            if foundOcclusion != undefined then occlusionNode = foundOcclusion

            foundNormal = SearchBitmapNodes currentMaterial normalNode "Normal"
            if foundNormal != undefined then normalNode = foundNormal

            foundAlpha = SearchBitmapNodes currentMaterial alphaNode "Alpha"
            if foundAlpha != undefined then alphaNode = foundAlpha
        )
        
        -- Diffuse 
        gltfDiffuse = ReplaceGLTFBitmap newMaterial.name newMaterial.baseColorMap diffuseNode "Diffuse" 2.2 "Required"
        if gltfDiffuse != undefined then newMaterial.baseColorMap = gltfDiffuse

        -- Roughness 
        gltfRough = ReplaceGLTFBitmap newMaterial.name newMaterial.roughnessMap roughNode "Roughness" 1.0 "Required"
        if gltfRough != undefined then newMaterial.roughnessMap = gltfRough   
        
        -- Metalness
        gltfMetal = ReplaceGLTFBitmap newMaterial.name newMaterial.metalnessMap metalNode "Metalness" 1.0 "Required"
        newMaterial.metalnessMap = gltfMetal 

        -- Normal 
        gltfNormal = ReplaceGLTFBitmap newMaterial.name newMaterial.normalMap normalNode "Normal" 1.0 "Required"
        if gltfNormal != undefined then newMaterial.normalMap = gltfNormal 
            
        if newMaterial.normalMap == undefined then
        (
            -- Bump (Not GLTF compliant)
            gltfNormal = ReplaceGLTFBitmap newMaterial.name newMaterial.normalMap bumpNode "Bump" 1.0 "Optional"
            if gltfNormal != undefined then newMaterial.normalMap = gltfNormal 
        )

        -- Occlusion
        gltfOcclusion = ReplaceGLTFBitmap newMaterial.name newMaterial.ambientOcclusionMap occlusionNode "Occlusion" 1.0 "Required"
        if gltfOcclusion != undefined then newMaterial.ambientOcclusionMap = gltfOcclusion 

        -- Optional textures

        -- Emission 
        gltfEmission = ReplaceGLTFBitmap newMaterial.name newMaterial.emissionMap emissionNode "Emission" 2.2 "Optional"
        if gltfEmission != undefined then newMaterial.emissionMap = gltfEmission 
                
        -- Alpha 
        gltfAlpha = ReplaceGLTFBitmap newMaterial.name newMaterial.AlphaMap alphaNode "Alpha" 1.0 "Optional"
        if gltfAlpha != undefined then newMaterial.AlphaMap = gltfAlpha

        if newMaterial.AlphaMap != undefined then
        (
            newMaterial.alphaMode = 2	-- Mask mode 
            newMaterial.alphaCutoff = 1.0 
        )

        ----------------------------------
        -- Rename GLTF Maps
        ----------------------------------

        if renameGltfMaps == true then
        (
            try(newMaterial.baseColorMap.name = "Base Color")catch()
            try(newMaterial.roughnessMap.name = "Roughness")catch()
            try(newMaterial.metalnessMap.name = "Metalness")catch()
            try(newMaterial.AlphaMap.name = "Alpha")catch()
            try(newMaterial.emissionMap.name = "Emission")catch()
            try(newMaterial.ambientOcclusionMap.name = "Occlusion")catch()
            try(newMaterial.normalMap.name = "Normal")catch()
        )
                    
        -- Convert textures 
        return newMaterial
    ) 

    ---------- Vray Section ----------

    -- Convert Vray Bitmaps to Standard Bitmaps
    fn convertVrayBitamps =
    (
        for i in getClassInstances VRayBitmap target:theTarget do  
        (  
            if (i.HDRIMapName != undefined) and (doesFileExist i.HDRIMapName) then
            (
                newBitmap = Bitmaptexture() 
                newBitmap.filename = i.HDRIMapName  
                newBitmap.name = i.name
                replaceinstances i newBitmap  
            )
        )  
    )

    -- Convert Vray Materials to GLTF
    fn convertVrayMtls =
    (
        for i in getClassInstances VRayMtl target:theTarget do 
        (
            p = (ConvertToGltf i)
            if p != undefined then replaceInstances i p
        )
    )

    -- Replace any Vray material type if a child material is GLTF
    fn convertVrayClasses =
    (
        for i in material.classes do
        (
            if matchPattern (i as string) pattern:"*Vray*" then
            (
                -- Find instances of Vray type materials (j)
                for j in getClassInstances i do
                (
                    -- Replace with GLTF (k)
                    if isKindOf (gltfMat = execute "glTFMaterial") Material do
                    (
                        for k in getClassInstances gltfMat target:j do
                        (
                            replaceInstances j k
                        )
                    )
                )
            )
        )
    )

    ---------- Corona Section ----------

    -- Convert Corona Bitmaps to Standard Bitmaps
    fn convertCoronaBitmaps =
    (
        for i in getClassInstances CoronaBitmap target:theTarget do  
        (  
            if doesFileExist i.filename then
            (
                newBitmap = Bitmaptexture() 
                newBitmap.filename = i.filename  
                newBitmap.name = i.name
                replaceinstances i newBitmap  
            ) 
        ) 
    )

    -- Replace Corona Front/Back texmap with Front Face Side 
    fn convertCoronaFrontSide = 
    (
        for i in getClassInstances CoronaFrontBack target:theTarget do 
        (
            for j in getClassInstances Bitmaptexture target:i do
            (
                replaceinstances i j
            )
        )
    )

    -- Convert Corona Materials to GLTF
    fn convertCoronaMtls = 
    (
        for i in getClassInstances CoronaPhysicalMtl target:theTarget do 
        (
            p = (ConvertToGltf i)
            if p != undefined then replaceInstances i p
        )
    )

    -- Replace any Corona material type if a child material is GLTF
    fn convertCoronaClasses = 
    (
        for i in material.classes do
        (
            if matchPattern (i as string) pattern:"*Corona*" then
            (
                -- Find instances of Corona type materials (j)
                for j in getClassInstances i do
                (
                    -- Replace with GLTF (k)
                    if isKindOf (gltfMat = execute "glTFMaterial") Material do
                    (
                        for k in getClassInstances gltfMat target:j do
                        (
                            replaceInstances j k
                        )
                    )
                )
            )
        )
    )

    ----------------------------------
    -- Convert Materials (button)
    ----------------------------------

    fn ConvertCoronaVray = 
    (
        if matchPattern (renderers.current as string) pattern:"*V_RAY*" then
        (
            renderEngine = "Vray"

            convertVrayBitamps()
            convertVrayMtls()
            convertVrayClasses()
        )
        
        if matchPattern (renderers.current as string) pattern:"*Corona*" then
        (
            renderEngine = "Corona"

            convertCoronaBitmaps()
            convertCoronaFrontSide()
            convertCoronaMtls()
            convertCoronaClasses()
        )

        ForceCompleteRedraw()  
    )

    fn PrintMissingTextures =
    (
        if missingTex.count != 0 then 
        ( 
            for i in missingTex do 
            ( 
                print i 
            ) 
        
            if not hideWarningPopups then
            (
                messageBox ("Some of your materials are missing textures. Check the MAXScript Listener for details.") 
            )
        ) 
        -- free the array from memory, aka garbage collect it 
        free missingTex 
        
        -- Refresh asset tracker 
        ATSOps.Refresh() 
    )
    
    ----------------------------------
    -- Remove Subdivision Modifiers
    ----------------------------------
    fn RemoveSubdivions = 
    (
        for obj in objects do 
        ( 
            -- Check if any of the modifiers are OpenSubdiv, TurboSmooth, or MeshSmooth 
            for mod in obj.modifiers do 
            ( 
                if (mod.name == "OpenSubdiv" or mod.name == "TurboSmooth" or mod.name == "MeshSmooth") do 
                ( 
                    deleteModifier obj mod 
                )
            )
        )
    )

    ----------------------------------
    -- Collapse Multi-Sub Materials
    ----------------------------------

    -- Function to count bitmaps within each material in a multi-sub 
    -- This is to replace the multi-sub with the highest texture count in CollapseMultiSubs()
    fn CountBitmapsFromMaterial mat = 
    ( 
        foundMapCount = 0 
        for x in getClassInstances bitmaptexture do 
        ( 
            for y in refs.dependents x where y == mat do 
            ( 
                foundMapCount += 1 
            ) 
        ) 
        -- return count of found bitmaps 
        foundMapCount 
    )

    -- Replace multi-sub materials with a sub-material with highest texture count
    fn CollapseMultiSubs = 
    (
        -- Iterate through materials in multi-sub and make unique
        for mat in getClassInstances MultiMaterial target:rootnode do 
        (
            for i = 1 to mat.numsubs do 
            (
                if mat[i] != undefined then
                (
                    uniqueMat = copy mat[i]
                    mat[i] = uniqueMat 
                ) 
            )
        )
                
        -- Replace the Multi/Sub-Object material with the sub-material with the highest bitmap count 
        for mat in getClassInstances MultiMaterial target:rootnode do 
        ( 
            -- Variable to track the maximum bitmap count 
            maxCount = 0  
            -- Variable to store the material with the maximum bitmap count 
            maxMaterial = undefined  
                    
            -- Loop through sub-materials of the multi-sub material 
            for subMatIndex = 1 to mat.numsubs do 
            ( 
                subMat = mat[subMatIndex] 
                mCount = CountBitmapsFromMaterial subMat -- replace with material with highest texture count
                        
                -- Check if the current sub-material has a higher bitmap count than the previous maximum 
                if mCount > maxCount do 
                ( 
                    maxCount = mCount 
                    maxMaterial = subMat 
                ) 
            ) 
                    
            -- Replace the Multi/Sub-Object material with the sub-material 
            if maxMaterial != undefined do 
            ( 
                replaceInstances mat maxMaterial 
                maxMaterial.name = mat.name 
            ) 
        ) 
    )

    ----------------------------------
    -- Export GLB File(s)
    ----------------------------------

    -- Export to GLB files
    fn ExportToGLB glbPath textField obj isCombined = 
    (
        objSelected = false

        -- Individual glb files
        if (obj != undefined) and (isCombined == false) then 
        (
            exportToGLBFile = glbPath + obj.name + ".glb"
            objSelected = true
        )

        -- Combined glb file
        if (obj != undefined) and (isCombined == true) then 
        (
            if textField == "" then textField = "Unnamed"
            exportToGLBFile = glbPath + textField + ".glb"
            objSelected = true
        )

        -- Export all
        if (obj == undefined) and (isCombined == false) then 
        (
            if textField == "" then textField = "Unnamed"
            exportToGLBFile = glbPath + textField + ".glb"
        )

        exportFile exportToGLBFile #noPrompt selectedOnly:objSelected using:GLTF_Export
        if removeGlbLogFile then deleteFile (exportToGLBFile + ".log")
    )

    ---------- Rollout UI ----------

    try(cui.UnRegisterDialogBar CoronaVrayToGLB)catch()
    try(DestroyDialog CoronaVrayToGLB)catch()
    
    rollout CoronaVrayToGLB ("Corona Vray To GLB " + scriptVersion)
    (
        ---------- UI Layout ----------

        group "GLB Export Directory"
        (
            edittext et_path "" across:2 align:#left width:230 readonly:true
            button btn_browse "..." align:#right width:22 height:22 tooltip:"Change GLB Export Directory"
        )

        group "Settings"
        (
            checkbox chk_findTex "Find Missing Bitmaps" checked:true tooltip:"Search the directory for missing bitmaps. Example: If you have Sofa_BaseColor.png it will find Sofa_Occlusion.png if its in the same directory and bitmap prefix is the same, \"Sofa\" in this example. You must have at least one bitmap in the material"
            checkbox chk_renameGltfMaps "Rename GLTF Maps" checked:true tooltip:"Renames GLTF Map nodes. Example: Base Color name = \"Base Color\" instead of \"Map #1\" or whatever you had previously"
            checkbox chk_rmLog "Remove GLB .log file" checked:true tooltip:"Deletes the .log file saved in the same directory as the .glb file after export"
            checkbox chk_rmSubdiv "Remove Subdivision Modifiers" checked:true tooltip:"Removes Modifiers Opensubdiv, Turbosmooth, Meshsmooth"
            checkbox chk_rmMultiSub "Collapse Multi-Sub Materials" tooltip:"WARNING: Replaces all materials in the Multi-Sub with the sub-material with the highest texture count. USE WITH CAUTION!"
            checkbox chk_hWarnings "Hide Warning Popups (Missing Textures)" tooltip:"Disables pop up messages regaring missing textures in materials. Still prints to maxscript listener for debugging"
        )

        group "Convert Materials"
        (
            checkbox chk_cSelMat "Convert Materials (Selected)" checked:true tooltip:"Convert materials of selected object only. Unchecked converts all scene materials to GLTF. \n\nNote: It will only convert the materials for your current render engine (example: Corona), so if you also need to change them for Vray then switch the render engine to Vray after conversion and press the button again"
            button btn_convertMtl "Convert Materials" tooltip:"Converts Vray or Corona materials to GLTF materials"
        )

        group "Export"
        (
            checkbox chk_xpSel "Export Selected (Individual)" checked:true tooltip:"Export selected objects only as indidual GLB files eg. Box001.glb Box002.glb etc"
            checkbox chk_xpSelCombine "Export Selected (Combined)" checked:false tooltip:"Export selected objects only as one combined .glb file. Set the file name yourself (WITHOUT the .glb extension)"
            checkbox chk_xpAll "Export All (Scene)" checked:false tooltip:"Export all mesh objects in the scene as one object and set the file name yourself (WITHOUT the .glb extension)"
            edittext et_exportName "" tooltip:"Enter the GLB filename for all objects being exported (Do not add .glb in the filename)"
            button btn_exportGlb "Export GLB File(s)" tooltip:"Exports to the .glb file(s) to the Export Directory"
        )

        group "Customization"
        (
            button btn_saveSettings "Save Settings as Default" tooltip:"Save your own custom settings as default"
            button btn_restoreSettings "Restore Original Settings" tooltip:"Use original/default settings"
        )

        group "Contact"
        (
            label lbl_name "James Vella" align:#left
            hyperlink hyp_site "www.jamesvella.net" align:#left color:(color 92 216 157) hovercolor:(color 0 150 150) visitedcolor:(color 0 200 200) address:"https://www.jamesvella.net" 
            label lbl_spacer1
            label lbl_info1 "If you like the script you can buy me a coffee :)" align:#left
            hyperlink hyp_donate "Donate" align:#left color:(color 92 216 157) hovercolor:(color 0 150 150) visitedcolor:(color 0 200 200) address:"https://www.paypal.com/donate/?hosted_button_id=GL9MAY2KZVJBC" 
        )

        ---------- UI Functions ----------

        -- Open UI --
        on CoronaVrayToGLB open do
        (
            -- load user saved settings
            if doesFileExist savedSettings then 
            (
                fStream = openfile savedSettings  
                while not eof fStream do  
                (  
                    -- Read checkbox states from text file and update checkboxes 
                    et_path.text = readLine fStream
                    chk_findTex.state = (readValue fStream) == 1
                    chk_renameGltfMaps.state = (readValue fStream) == 1
                    chk_rmLog.state = (readValue fStream) == 1
                    chk_rmSubdiv.state = (readValue fStream) == 1
                    chk_rmMultiSub.state = (readValue fStream) == 1
                    chk_hWarnings.state = (readValue fStream) == 1
                    chk_cSelMat.state = (readValue fStream) == 1
                    chk_xpSel.state = (readValue fStream) == 1
                    chk_xpSelCombine.state = (readValue fStream) == 1
                    chk_xpAll.state = (readValue fStream) == 1
                )  
                -- Close the text file            
                close fStream  
                free fStream  
                ForceCompleteRedraw()   

                -- Export selected objects checkbox
                if chk_xpSel.state then
                (
                    et_exportName.visible = false
                )
            )
            else
            (
                -- load defaultExportDirectory
                et_path.text = defaultExportDirectory
                et_exportName.text = ""
                et_exportName.visible = false
            )
        )

        -- GLB Export Directory
        on btn_browse pressed do  
        (      
            previousDirectory = et_path.text           
            exportDirectory = getSavePath caption:"Save Directory" 
            et_path.text = (exportDirectory as string) + @"\"
            
            -- User presses cancel when selecting a directory
            if exportDirectory == undefined then et_path.text = previousDirectory
        )

        -- Convert Materials (button)
        on btn_convertMtl pressed do
        (
            clearListener()
            
            -- Rename GLTF Map Nodes
            if chk_renameGltfMaps.checked then renameGltfMaps = true else renameGltfMaps = false

            -- Hide Warning Popups
            if chk_hWarnings.checked then hideWarningPopups = true else hideWarningPopups = false

            -- Find Missing Bitmaps
            if chk_findTex.checked then findTextures = true else findTextures = false

            with undo on 
            (
                RepathFoundAssets()
                -- Remove Subdivisions
                if chk_rmSubdiv.checked then RemoveSubdivions()

                -- Collapse Multisubs
                if chk_rmMultiSub.checked then CollapseMultiSubs()

                -- Convert Materials to Corona/Vray
                if chk_cSelMat.checked then 
                (
                    convertSelectedMaterials = true 

                    if convertSelectedMaterials then 
                    (
                        for obj in selection where (selection.count > 0) do
                        (
                            theTarget = obj
                            ConvertCoronaVray()
                        )
                    )

                )
                else 
                (
                    convertSelectedMaterials = false

                    theTarget = rootnode
                    ConvertCoronaVray()
                )   
            )
            
            PrintMissingTextures()
        )

        -- Export (checkboxes)
        on chk_xpSel changed state do 
        (
            chk_xpSelCombine.checked = false
            chk_xpAll.checked = false
            et_exportName.visible = false
        )

        on chk_xpSelCombine changed state do 
        (
            chk_xpSel.checked = false
            chk_xpAll.checked = false
            et_exportName.visible = state == true
        )

        on chk_xpAll changed state do 
        (
            chk_xpSel.checked = false
            chk_xpSelCombine.checked = false
            et_exportName.visible = state == true
        )

        -- Export GLB File(s) (button)
        on btn_exportGlb pressed do
        (
            if chk_rmLog.checked then removeGlbLogFile = true else removeGlbLogFile = false

            if chk_xpSel.checked then
            (
                 -- hide/unhide so that only one object at a time is exported
                for obj in selection do
                (
                    hide selection
                    unhide obj
                    ExportToGLB et_path.text et_exportName.text obj false
                    unhide selection
                )
            )
            else if chk_xpSelCombine.checked then
            (
                for obj in selection do
                (
                    ExportToGLB et_path.text et_exportName.text obj true
                    -- exit after first object as it exports all selected in one file
                    exit 
                )
            )
            else if chk_xpAll.checked then
            (
                ExportToGLB et_path.text et_exportName.text undefined false
            )
            else if not (chk_xpAll.checked and chk_xpSelCombine.checked and chk_xpAll.checked) then
            (
                -- No export checkbox selected
                messageBox("You must pick one Export checkbox to export to GLB")
            )
        )

        -- Save Settings as Default (button)

        on btn_saveSettings pressed do  
        (  
            -- Save UI Settings to text file to remember user preference                 
            saveDirectory = getDir #userScripts + "\\Vella"  
            if not doesFileExist saveDirectory do makeDir saveDirectory  

            -- Save settings to text file           
            fStream = createFile savedSettings  
                
            -- Save to text file        
            format "%\n" et_path.text to:fStream 
            format "%\n" (if chk_findTex.state then 1 else 0) to:fStream  
            format "%\n" (if chk_renameGltfMaps.state then 1 else 0) to:fStream  
            format "%\n" (if chk_rmLog.state then 1 else 0) to:fStream  
            format "%\n" (if chk_rmSubdiv.state then 1 else 0) to:fStream  
            format "%\n" (if chk_rmMultiSub.state then 1 else 0) to:fStream  
            format "%\n" (if chk_hWarnings.state then 1 else 0) to:fStream  
            format "%\n" (if chk_cSelMat.state then 1 else 0) to:fStream  
            format "%\n" (if chk_xpSel.state then 1 else 0) to:fStream  
            format "%\n" (if chk_xpSelCombine.state then 1 else 0) to:fStream  
            format "%\n" (if chk_xpAll.state then 1 else 0) to:fStream  
            
            -- Close the text file          
            close fStream  
            free fStream  
            ForceCompleteRedraw()   
        )  

        -- Restore Original Settings (button)  

        on btn_restoreSettings pressed do  
        (  
            -- Delete the settings text file           
            if doesFileExist savedSettings then deleteFile savedSettings  

            -- Restore checkboxes
            et_path.text = defaultExportDirectory
            chk_findTex.checked = true 
            chk_renameGltfMaps.checked = true 
            chk_rmLog.checked = true 
            chk_rmSubdiv.checked = true
            chk_rmMultiSub.checked = false
            chk_hWarnings.checked = false
            chk_cSelMat.checked = true
            chk_xpSel.checked = true
            chk_xpSelCombine.checked = false
            chk_xpAll.checked = false
            et_exportName.visible = false
        )  
    )

    CreateDialog CoronaVrayToGLB POS:[100,200] width:300 height:605
    cui.RegisterDialogBar CoronaVrayToGLB
)   
