
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
	Version: 2.0
	Software: 3D Studio Max 2024.1
	Engine: Corona 10.0
	Language: Maxscript
	Description-US: Add Corona Mapping Randomizer to all bitmaps in selected objects 
	*/ 

	-- undo on 

	with animate off  
	(
		function addRandomizer obj crandomizer =
		(
			-- Find all used inputs in the material (diffuse/gloss/etc)
            for i in 1 to obj.material.numsubs do
            (
                local tex = getSubAnim obj.material i
				
				-- Only add CoronaMappingRandomizer material nodes that are used by a bitmap or node group
				if (tex != undefined) and (tex[1] != undefined) do
				(
					-- count how many inputs/outputs needed for corona randomizer
					local new_output = MultiOutputChannelTexmapToTexmap() -- create for additional outputs
					local input_count = crandomizer.additionalOutputs += 1 -- add a new output per found node
					local current_tex = tex.value -- first subanim:value 

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
				)
			)
		)
		
		function addTriplanar obj ctriplanar = 
		(
			-- Find all used inputs in the material (diffuse/gloss/etc)
            for i in 1 to obj.material.numsubs do
            (
                local tex = getSubAnim obj.material i
				
				-- Only add CoronaMappingRandomizer material nodes that are used by a bitmap or node group
				if (tex != undefined) and (tex[1] != undefined) do
				(
					-- count how many inputs/outputs needed for corona randomizer
					local new_output = MultiOutputChannelTexmapToTexmap() -- create for additional outputs
					local input_count = ctriplanar.additionalOutputs += 1 -- add a new output per found node
					local current_tex = tex.value -- first subanim:value 

					ctriplanar.additionalTexmapX[input_count] = current_tex -- add inputs based on the number of additionalOutputs
					new_output.outputChannelIndex = (input_count)
					new_output.sourceMap = ctriplanar
					tex.value = new_output

					-- if more than 1 node input, reset the order to accept more input/outputs for randomizer
					if ctriplanar.texmapX == undefined then
					(
						ctriplanar.texmapX = current_tex-- put first texture (diffuse) back into 'input' after being moved to 'input1'
						new_output.sourceMap.additionalOutputs = 0 -- reorder outputs to start back at index 1
					)
					else
					(
						-- re-order input/output based on additional output update
						new_output.outputChannelIndex = (input_count +1) -- move first output down 1 index so output 1 does not have 2 outputs
					)
				)
			)
		)

		rollout randomizer_rl "Corona Randomizer" width:200 height:250
		(
			group "Version 2.0"
			(

			)
			group "Instructions"
			(
				label lbl_0 "1. Select the objects first." align:#left
				label lbl_1 "2. Choose your randomizer." align:#left
				label lbl_2 "3. Undo available if required." align:#left
			)
			group "Actions"  
			(
				button both_uvw_triplanar "Randomizer + Triplanar" align:#left
				button cmapping "Randomizer" align:#left
				button ctriplanar "Triplanar" align:#left
			)
			group "Help"
			(
				HyperLink hyp_tutorial "Contact"align:#left color:(color 0 255 255) hovercolor:(color 0 150 150) visitedcolor:(color 0 200 200) address:"mailto:jmdvella@gmail.com" 
				-- label lbl_3 "jmdvella@gmail.com" align:#left
			)

			-- Functions for rollout
			on both_uvw_triplanar pressed do  
			(
				undo on 
				for obj in selection where (isKindOf obj.material CoronaPhysicalMtl or 
											isKindOf obj.material CoronaLegacyMtl) do
				(
					local crandomizer = CoronaMappingRandomizer()
					local ctriplanar = CoronaTriplanar()
					-- CoronaMappingRandomizer
					addRandomizer obj crandomizer
					-- CoronaTriplanar
					addTriplanar obj ctriplanar 
				)
			)

			on cmapping pressed do  
			(
				undo on 
				for obj in selection where (isKindOf obj.material CoronaPhysicalMtl or 
											isKindOf obj.material CoronaLegacyMtl) do
				(
					local crandomizer = CoronaMappingRandomizer()
					addRandomizer obj crandomizer
				)
			)

			on ctriplanar pressed do  
			(
				undo on 
				for obj in selection where (isKindOf obj.material CoronaPhysicalMtl or 
											isKindOf obj.material CoronaLegacyMtl) do
				(
					local crandomizer = CoronaMappingRandomizer()
					local ctriplanar = CoronaTriplanar()
					-- CoronaTriplanar
					addTriplanar obj ctriplanar 
				)
			)
		)
		createDialog randomizer_rl escapeEnable:true style:#(#style_titlebar, #style_sysmenu, #style_toolwindow, #style_resizing, #style_border)
    )
)

