
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
	Version: 3.0
	Software: 3D Studio Max 2024.1
	Engine: Corona 10.0
	Language: Maxscript
	Description-US: Add Corona Mapping Randomizer to all bitmaps in selected objects 
	*/ 

	-- undo on 

	with animate off  
	(
		function addRandomizer obj crandomizer  =
		(
			-- Apply CoronaMappingRandomizer node and re-wire all inputs/outputs --

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

		function saveRandomizerSettings crandomizer chk_stochastic chk_hqblending =
		(
			-- Check if directory exists, if not create it
			local saved_dir = getDir #userScripts + "\\Vella"
			if not doesFileExist saved_dir do makeDir saved_dir

			-- Save settings to text file
			local saved_settings = getDir(#userScripts) + "\\Vella\\CoronaRandomizer_Settings.txt"  
			local file_stream = createFile saved_settings 
			
			-- Save numerical properties
			format "%\n" crandomizer.offset_U_from 					to:file_stream
			format "%\n" crandomizer.offset_U_to					to:file_stream
			format "%\n" crandomizer.offset_V_from					to:file_stream
			format "%\n" crandomizer.offset_V_to					to:file_stream
			format "%\n" crandomizer.rotation_W_to					to:file_stream
			format "%\n" crandomizer.tiling_stochastic				to:file_stream
			format "%\n" crandomizer.tiling_high_quality_blending 	to:file_stream 
			-- Save checkbox states
			format "%\n" (if chk_stochastic.state then 1 else 0) 	to:file_stream
    		format "%\n" (if chk_hqblending.state then 1 else 0) 	to:file_stream
			-- Close the text file
			close file_stream
			free file_stream  
			ForceCompleteRedraw()
		)
		
		function addTriplanar obj ctriplanar = 
		(
			-- Apply CoronaTriplanar node and re-wire all inputs/outputs --

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

		-- Variables for Rollout
		local crandomizer_custom = CoronaMappingRandomizer()

		rollout randomizer_rl "Main Menu" category:1 
		(
			-- Main UI Rollout --

			group "Information" 
			(
				label lbl_ver "Version 3.0" align:#left across:2
				HyperLink hyp_tutorial "Contact" align:#right color:(color 0 255 255) hovercolor:(color 0 150 150) visitedcolor:(color 0 200 200) address:"mailto:jmdvella@gmail.com" 
			)
			group "Instructions"
			(
				label lbl_0 "1. Select the objects first." align:#left
				label lbl_1 "2. Choose your randomizer." align:#left
				label lbl_2 "3. Undo available if required." align:#left
			)
			group "Actions"  
			(
				button btn_both "Randomizer + Triplanar" align:#left tooltip:("CoronaMappingRandomizer + CoronaTriplanar") 
				button btn_cmapping "Randomizer" align:#left tooltip:("CoronaMappingRandomizer") 
				button btn_ctriplanar "Triplanar" align:#left tooltip:("CoronaTriplanar") 
			)

			-- Functions and Buttons for rollout
			on btn_both pressed do  
			(
				theHold.Begin() -- undo on
				for obj in selection where (isKindOf obj.material CoronaPhysicalMtl or 
											isKindOf obj.material CoronaLegacyMtl) do
				(
					-- CoronaMappingRandomizer
					local crandomizer = crandomizer_custom
					addRandomizer obj crandomizer
					-- CoronaTriplanar
					local ctriplanar = CoronaTriplanar()
					addTriplanar obj ctriplanar 
				)
				theHold.Accept "Undo Randomizer" -- undo off
			)

			on btn_cmapping pressed do  
			(
				theHold.Begin() -- undo on
				for obj in selection where (isKindOf obj.material CoronaPhysicalMtl or 
											isKindOf obj.material CoronaLegacyMtl) do
				(
					-- CoronaMappingRandomizer
					local crandomizer = crandomizer_custom
					addRandomizer obj crandomizer
				)
				theHold.Accept "Undo Randomizer" -- undo off
			)

			on btn_ctriplanar pressed do  
			(
				theHold.Begin() -- undo on
				for obj in selection where (isKindOf obj.material CoronaPhysicalMtl or 
											isKindOf obj.material CoronaLegacyMtl) do
				(
					-- CoronaTriplanar
					local ctriplanar = CoronaTriplanar()
					addTriplanar obj ctriplanar 
				)
				theHold.Accept "Undo Triplanar" -- undo off
			)
		)

		rollout settings_rand_rl "Randomizer: Settings" category:2 
		(
			-- UI for Randomizer Settings
			group "Offset and Tiling"
			(
				checkbox chk_stochastic "Stochastic" align:#left across:2 tooltip:("U|X, V|Y, W|Z Offset and Rotation + Randomize Each Tile")
				checkbox chk_hqblending "HQ Blending" checked:true tooltip:("Tiling: High quality blending") 
			)

			group "Save Settings"
			(
				button btn_save "Save as Default" across:2 tooltip:("Save current CoronaMappingRandomizer settings as Default")
				button btn_reset "Reset all Settings" tooltip:("Return to Default CoronaMappingRandomizer settings")
			)

			-- Settings for checkboxes
			on chk_stochastic changed state do
			(
				if state then
				(
					crandomizer_custom.offset_U_from 		= -1.0
					crandomizer_custom.offset_U_to 			= 1.0
					crandomizer_custom.offset_V_from 		= -1.0
					crandomizer_custom.offset_V_to 			= 1.0
					crandomizer_custom.rotation_W_to 		= 360.0
					crandomizer_custom.tiling_stochastic 	= on
				)
				else
				(
					crandomizer_custom.offset_U_from 		= 0.0
					crandomizer_custom.offset_U_to 			= 0.0
					crandomizer_custom.offset_V_from 		= 0.0
					crandomizer_custom.offset_V_to 			= 0.0
					crandomizer_custom.rotation_W_to 		= 0.0
					crandomizer_custom.tiling_stochastic 	= off
				)
			)

			on chk_hqblending changed state do
			(
				if state then
				(
					crandomizer_custom.tiling_high_quality_blending = on
				)
				else
				(
					crandomizer_custom.tiling_high_quality_blending = off
				)
			) 

			-- Saving or Resetting Settings
			on btn_save pressed do
			(
				saveRandomizerSettings crandomizer_custom chk_stochastic chk_hqblending
			)

			-- Reset crandomizer to default
			on btn_reset pressed do 
			(
				crandomizer_custom = CoronaMappingRandomizer()
				-- Reset UI
				chk_stochastic.checked = false
				chk_hqblending.checked = true
				-- Delete the settings text file
				local saved_settings = getDir(#userScripts) + "\\Vella\\CoronaRandomizer_Settings.txt"
				if doesFileExist saved_settings then deleteFile saved_settings
			)

			-- Check for current settings, if exist use those
			on settings_rand_rl open do
			(
				local saved_settings = getDir(#userScripts) + "\\Vella\\CoronaRandomizer_Settings.txt"
				if doesFileExist saved_settings then  
				(  
					local file_stream = openfile saved_settings
					while not eof file_stream do  
					(  
						-- Read randomizer settings from text file
						crandomizer_custom.offset_U_from =					readValue file_stream
						crandomizer_custom.offset_U_to =					readValue file_stream
						crandomizer_custom.offset_V_from =					readValue file_stream
						crandomizer_custom.offset_V_to =					readValue file_stream
						crandomizer_custom.rotation_W_to =					readValue file_stream
						crandomizer_custom.tiling_stochastic =				readValue file_stream
						crandomizer_custom.tiling_high_quality_blending = 	readValue file_stream 
						-- Read checkbox states from text file and update checkboxes
						chk_stochastic.state = (readValue file_stream) == 1
						chk_hqblending.state = (readValue file_stream) == 1
					)
					-- Close the text file  
					close file_stream
					free file_stream  
					ForceCompleteRedraw()  
				) 
			)

		)

		rollout settings_tri_rl "Triplanar" category:3
		(
			-- UI for Triplanar Settings
			checkbox chk_prim "Primitive" align:#left across:2
			checkbox chk_instance "Instance"
		)

		rf = newRolloutFloater "Corona Randomizer" 280 400 
		addRollout randomizer_rl rf 
		addRollout settings_rand_rl rf --rolledUp:true
		-- addRollout settings_tri_rl rf --rolledUp:true
		CUI.REGISTERDIALOGBAR rf
		-- createDialog randomizer_rl escapeEnable:true style:#(#style_titlebar, #style_sysmenu, #style_toolwindow, #style_resizing, #style_border)
    )
)

