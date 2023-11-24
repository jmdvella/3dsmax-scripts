
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
	Version: 3.4
	Software: 3D Studio Max 2024.1
	Engine: Corona 10.0
	Language: Maxscript
	Description-US: Add CoronaMappingRandomizer and/or CoronaTriplanar to all bitmaps in selected objects 
	*/ 

	with animate off  
	(
		function addRandomizer selected_material crandomizer  =
		(		
			-- Find all used inputs in the material (diffuse/gloss/etc)
            for i in 1 to selected_material.numsubs do
            (
                local tex = getSubAnim selected_material i
				
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
		
		function addTriplanar selected_material ctriplanar = 
		(
			-- Apply CoronaTriplanar node and re-wire all inputs/outputs --

			-- Find all used inputs in the material (diffuse/gloss/etc)
            for i in 1 to selected_material.numsubs do
            (
                local tex = getSubAnim selected_material i
				
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

		function addSelectedMaterials =
		(
			-- Returns selected materials from slate editor as array --
			-- Thanks to Frood from the Corona Forums for this function

			local selected_materials = #()
			if (sme.getview sme.activeView) != undefined then 
			(
				selected_nodes = (sme.getview sme.activeView).GetSelectedNodes()
				if selected_nodes.count != 0 then 
				(
					for node in selected_nodes do 
					(
						if (superclassof node.reference == material) then 
						(
							append selected_materials node.reference
						)
					)
					return selected_materials
				)
			)
			else
			(
				return undefined
			)
		)

		-- Variables for Rollout
		local crandomizer_custom = CoronaMappingRandomizer()
		local ctriplanar_custom = CoronaTriplanar()
		local all_selected_materials = undefined
		
		rollout randomizer_rl "Main Menu" category:1 
		(
			-- Main UI Rollout --

			group "Information" 
			(
				label lbl_ver "Version 3.4" align:#left across:2
				HyperLink hyp_tutorial "Contact" align:#right color:(color 0 255 255) hovercolor:(color 0 150 150) visitedcolor:(color 0 200 200) address:"mailto:jmdvella@gmail.com" 
			)
			group "Instructions"
			(
				label lbl_0 "1. Select the objects first" align:#left
				label lbl_1 "2. If no objects selected then select material(s)" align:#left
				label lbl_2 "3. Choose your randomizer(s)" align:#left
				label lbl_3 "4. Undo available if required" align:#left
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
				undo on
				(
					-- Material is selected, not the object
					if selection.count == 0 then
					(
						all_selected_materials = addSelectedMaterials()
						if all_selected_materials != undefined then
						(
							for selected_material in all_selected_materials do
							(
								if (isKindOf selected_material CoronaPhysicalMtl or 
									isKindOf selected_material CoronaLegacyMtl) do
								(
									-- CoronaMappingRandomizer
									local crandomizer = copy crandomizer_custom
									addRandomizer selected_material crandomizer
									-- CoronaTriplanar
									local ctriplanar = copy ctriplanar_custom
									addTriplanar selected_material ctriplanar

								)
							)
						)	
					)
					-- Object is selected, not material
					else
					(
						for obj in selection where (isKindOf obj.material CoronaPhysicalMtl or 
													isKindOf obj.material CoronaLegacyMtl) do
						(
							-- CoronaMappingRandomizer
							local crandomizer = copy crandomizer_custom
							addRandomizer obj.material crandomizer
							-- CoronaTriplanar
							local ctriplanar = copy ctriplanar_custom
							addTriplanar obj.material ctriplanar 
						)	
					)
				)
			)

			on btn_cmapping pressed do  
			(
				-- all_selected_materials = addSelectedMaterials()
				undo on
				(
					-- Material is selected, not the object
					if selection.count == 0 then
					(
						all_selected_materials = addSelectedMaterials()
						if all_selected_materials != undefined then
						(
							for selected_material in all_selected_materials do
							(
								-- Process the selected material
								if (isKindOf selected_material CoronaPhysicalMtl or 
									isKindOf selected_material CoronaLegacyMtl) do
								(
									-- CoronaMappingRandomizer
									local crandomizer = copy crandomizer_custom
									addRandomizer selected_material crandomizer
								)
							)
						)
					)
					-- Object is selected, not material
					else
					(
						-- Process the selected object
						for obj in selection where (isKindOf obj.material CoronaPhysicalMtl or 
													isKindOf obj.material CoronaLegacyMtl) do
						(
							-- CoronaMappingRandomizer
							local crandomizer = copy crandomizer_custom
							addRandomizer obj.material crandomizer
						)
					)
				)
				
			)

			on btn_ctriplanar pressed do  
			(
				undo on
				(
					-- Material is selected, not the object
					if selection.count == 0 then
					(
						all_selected_materials = addSelectedMaterials()
						if all_selected_materials != undefined then
						(
							for selected_material in all_selected_materials do
							(
								-- Process the selected material
								if (isKindOf selected_material CoronaPhysicalMtl or 
									isKindOf selected_material CoronaLegacyMtl) do
								(
									-- CoronaTriplanar
									local ctriplanar = copy ctriplanar_custom
									addTriplanar selected_material ctriplanar
								)
							)
						)
					)
					-- Object is selected, not material
					else
					(
						for obj in selection where (isKindOf obj.material CoronaPhysicalMtl or 
													isKindOf obj.material CoronaLegacyMtl) do
						(
							-- CoronaTriplanar
							local ctriplanar = copy ctriplanar_custom
							addTriplanar obj.material ctriplanar 
						)
					)
				)
			)
		)

		rollout settings_rand_rl "Randomizer: Settings" category:2 
		(
			-- UI for Randomizer Settings
			group "Offset and Tiling"
			(
				checkbox chk_stochastic "Stochastic Mapping" align:#left across:2 tooltip:("U|X: -1.0 to 1.0\nV|Y: -1.0 to 1.0\nW|Z: 0 to 360\nRandomize each tile (on)")
				checkbox chk_hqblending "High Quality Blending" align:#right checked:true tooltip:("Tiling: High quality blending") 
			)

			group "Save Settings"
			(
				button btn_save "Save as Default" across:2 tooltip:("Save current CoronaMappingRandomizer settings as Default Settings for this script.")
				button btn_reset "Reset all Settings" tooltip:("Return to Default CoronaMappingRandomizer settings as Default Settings for this script")
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
				-- local test = addSelectedMaterials()
				-- print test
				-- print (classof test)
				print all_selected_materials

				local saved_settings = getDir(#userScripts) + "\\Vella\\CoronaRandomizer_Settings.txt"
				if doesFileExist saved_settings then  
				(  
					local file_stream = openfile saved_settings
					while not eof file_stream do  
					(  
						-- Read randomizer settings from text file
						crandomizer_custom.offset_U_from 					= readValue file_stream
						crandomizer_custom.offset_U_to						= readValue file_stream
						crandomizer_custom.offset_V_from 					= readValue file_stream
						crandomizer_custom.offset_V_to 						= readValue file_stream
						crandomizer_custom.rotation_W_to 					= readValue file_stream
						crandomizer_custom.tiling_stochastic 				= readValue file_stream
						crandomizer_custom.tiling_high_quality_blending 	= readValue file_stream 
						-- Read checkbox states from text file and update checkboxes
						chk_stochastic.state 								= (readValue file_stream) == 1
						chk_hqblending.state 								= (readValue file_stream) == 1
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

		rf = newRolloutFloater "Corona Randomizer" 280 410 
		addRollout randomizer_rl rf 
		addRollout settings_rand_rl rf --rolledUp:true
		-- addRollout settings_tri_rl rf --rolledUp:true
		CUI.REGISTERDIALOGBAR rf
		-- createDialog randomizer_rl escapeEnable:true style:#(#style_titlebar, #style_sysmenu, #style_toolwindow, #style_resizing, #style_border)
    )
)

