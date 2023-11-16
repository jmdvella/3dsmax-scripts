
macroscript CoronaRandomizer
	category:"Vella" 
	internalcategory:"Automate"
	tooltip:"Automate CoronaRandomizer"
	buttonText:"Corona Randomizer"
	Icon:#("UVWUnwrapTools",41)

( 
	/*
	Author: James Vella
	Website: http://www.jamesvella.net
	Name-US: JV_CoronaRandomizer
	Version: 1.0
	Software: 3D Studio Max 2024.1
	Engine: Corona 10.0
	Language: Maxscript
	Description-US: Add Corona Mapping Randomizer to all bitmaps in selected objects 
	*/ 

	undo on 

	with animate off  
	( 
        
        for obj in selection where (isKindOf obj.material CoronaPhysicalMtl or 
                                    isKindOf obj.material CoronaLegacyMtl) do
        (
			local crandomizer = CoronaMappingRandomizer()

			-- Find all used inputs in the material (diffuse/gloss/etc)
            for i in 1 to obj.material.numsubs do
            (
                local tex = getSubAnim obj.material i
				-- local found_tex = #()
				
				-- Only add CoronaMappingRandomizer material nodes that are used by a bitmap or node group
				if (tex != undefined) and (tex[1] != undefined) do
				(
					-- count how many inputs/outputs needed for corona randomizer
					local new_output = MultiOutputChannelTexmapToTexmap() -- create for additional outputs
					local input_count = crandomizer.additionalOutputs += 1 -- add a new output per found node
					local current_tex = tex.value -- first subanim:value 
					-- append found_tex current_tex

					crandomizer.additionalInput[input_count] = current_tex -- add inputs based on the number of additionalOutputs
					new_output.outputChannelIndex = (input_count)
					new_output.sourceMap = crandomizer
					tex.value = new_output

					-- if more than 1 node input, reset the order to accept more input/outputs for randomizer
					if crandomizer.input == undefined then
					(
						crandomizer.input = current_tex-- put first texture (diffuse) back into 'input' after being moved to 'input1'
						new_output.sourceMap.additionalOutputs = 0 -- reorder outputs to start back at index 1
					)
					else
					(
						-- re-order input/output based on additional output update
						new_output.outputChannelIndex = (input_count +1) -- move first output down 1 index so output 1 does not have 2 outputs 
						
					)
					-- print found_tex
				)
			) 
        )
    )

)

