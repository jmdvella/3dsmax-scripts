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
    Version: 2.0
    Software: 3D Studio Max 2024.2.3
    Engine: Corona 12 Update 1 (Hotfix 1) 
    Language: Maxscript
    Description-US: Place bitmap or corona bitmap from bump in corona normal and set gamma, recursive tree search
    */

    -- Tree search for bitmap or corona bitmap
    fn findBitmapInNode mNode =
    (
        -- add classes in array you want to search for
        for cls in #(Bitmaptexture, CoronaBitmap) do
        (
            local arr = getClassInstances cls target:mNode
            if arr.count > 0 then return arr[1]
        )
    )

    -- Place bitmap or corona bitmap from bump in corona normal
    fn ConvertCoronaNormal obj =
    (
        local bumpProps = #(#texmapBump, #baseBumpTexmap) -- add extra properties you want to check for

        for m in (getClassInstances CoronaPhysicalMtl target:obj) + (getClassInstances CoronaLegacyMtl target:obj) do
        (
            for p in bumpProps where isProperty m p do
            (
                -- Check if nodes in bump node
                local bNode = getProperty m p
                
                -- Tree search for bitmaps within bump node
                if bNode != undefined and classof bNode != CoronaNormal then 
                (
                    local foundBitmap = findBitmapInNode bNode

                    if foundBitmap != undefined then
                    (
                        local cNormal = CoronaNormal()
                        cNormal.normalMap = foundBitmap

                        -- Set gamma for CoronaNormal()
                        if (classof foundBitmap == Bitmaptexture and foundBitmap.bitmap.inputGammaValue != 1.0) or (classof foundBitmap == CoronaBitmap and foundBitmap.gamma != 1.0) then
                        (
                            cNormal.addGamma = on
                        )

                        -- Rewire bitmaps to CoronaNormal() node and put in material bump slot
                        setProperty m p cNormal
                    )
                )                
            )
        )
    )

    -- Run function
    undo on
    (
        with animate off
        (
            -- Selected objects only (change 'selection' to 'objects' if you want all scene objects)
            for obj in selection do ConvertCoronaNormal obj
        )
    )

)
