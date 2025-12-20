macroscript CoronaNormal
category:"Vella" 
tooltip:"Automate CoronaNormal"
buttonText:"Corona Bitmap to CoronaNormal"
Icon:"CivilView\Normal"
(
    /*
    Author: James Vella
    Website: http://www.jamesvella.net
    Name-US: JV_CoronaNormal
    Version: 3.0
    Software: 3D Studio Max 2024.2.3
    Engine: Corona 12 Update 1 (Hotfix 1) 
    Language: Maxscript
    Description-US: Place bitmap or corona bitmap from bump in corona normal and set gamma, recursive tree search
    */

    -- Tree search for bitmap within class array, mNode = target node in material
    fn FindBitmapInNodeTree classArr mNode =
    (
        -- add classes in classArr you want to search for
        for cls in classArr do
        (
            local arr = getClassInstances cls target:mNode
            if arr.count > 0 then return arr[1]
        )
    )

    -- Create CoronaNormal() if bitmap found
    fn AddCoronaNormal foundBitmap =
    (
        local cNormal = CoronaNormal()
        cNormal.normalMap = foundBitmap

        -- Set gamma for CoronaNormal()
        if (classof foundBitmap == Bitmaptexture and foundBitmap.bitmap.inputGammaValue != 1.0) or (classof foundBitmap == CoronaBitmap and foundBitmap.gamma != 1.0) then
        (
            cNormal.addGamma = on
        )

        return cNormal
    )

    -- Place bitmap or corona bitmap from bump in CoronaNormal
    fn ConvertCoronaNormal obj =
    (
        local bumpProps = #(#texmapBump, #baseBumpTexmap) -- add extra properties you want to search for

        for m in (getClassInstances CoronaPhysicalMtl target:obj) + (getClassInstances CoronaLegacyMtl target:obj) do
        (
            -- m = material, p = property
            for p in bumpProps where isProperty m p do
            (
                -- Check if any nodes in bump node
                local bNode = getProperty m p           

                if bNode != undefined and classof bNode != CoronaNormal then 
                (
                    local classArr = #(Bitmaptexture, CoronaBitmap) -- add extra classes you want to search for
                    local foundBitmap = FindBitmapInNodeTree classArr bNode

                    if foundBitmap != undefined then
                    (
                        local cNormal = AddCoronaNormal foundBitmap
                        if cNormal != undefined then setProperty m p cNormal  
                    )                    
                )                
            )
        )
    )

    -- Run Main function
    undo on
    (
        with animate off
        (
            -- Selected objects only (change 'selection' to 'objects' if you want all scene objects)
            for obj in selection do ConvertCoronaNormal obj
        )
    )
)
