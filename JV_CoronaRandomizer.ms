
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
	Version: 4.1
	Software: 3D Studio Max 2024.1
	Engine: Corona 10.0
	Language: Maxscript
	Description-US: Add CoronaMappingRandomizer and/or CoronaTriplanar to all bitmaps in selected objects 
	*/	 

	with animate off  
	(  
		function addRandomizer all_selected_materials crandomizer =  
		(  
			-- Apply CoronaMappingRandomizer node and re-wire all inputs/outputs --        
			 
			for selected_material in all_selected_materials do  
			(  
				-- Process the selected material        
				if (isKindOf selected_material CoronaPhysicalMtl or  
					isKindOf selected_material CoronaLegacyMtl) do  
				(  
					-- Find all used inputs in the material (diffuse/gloss/etc)        
					for i in 1 to selected_material.numsubs do  
					(  
						local tex = getSubAnim selected_material i  
						 
						-- Only add CoronaMappingRandomizer material nodes that are used by a bitmap or node group        
						if (tex != undefined) and (tex[1] != undefined) do  
						(  
							-- count how many inputs/outputs needed for corona randomizer        
							local new_output = MultiOutputChannelTexmapToTexmap()  -- create for additional outputs        
							local input_count = crandomizer.additionalOutputs += 1 -- add a new output per found node        
							local current_tex = tex.value -- first subanim:value         

							crandomizer.additionalInput[input_count] = current_tex -- add inputs based on the number of additionalOutputs        
							new_output.outputChannelIndex = (input_count)  
							new_output.sourceMap = crandomizer  
							tex.value = new_output  

							-- if more than 1 node input, reset the order to accept more input/outputs for randomizer        
							if crandomizer.input == undefined then  
							(  
								crandomizer.input = current_tex -- put first texture (diffuse) back into 'input' after being moved to 'input1'        
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
			)  
		)  

		function saveRandomizerSettings crandomizer chk_stochastic chk_hqblending =  
		(  
			-- Save UI Settings to text file to remember user preference --        

			-- Check if directory exists, if not create it        
			local saved_dir = getDir #userScripts + "\\Vella"  
			if not doesFileExist saved_dir do makeDir saved_dir  

			-- Save settings to text file        
			local saved_settings = getDir(#userScripts) + "\\Vella\\CoronaRandomizer_Settings.txt"  
			local file_stream = createFile saved_settings  
			 
			-- Save numerical properties        
			format "%\n" crandomizer.offset_U_from to:file_stream  
			format "%\n" crandomizer.offset_U_to to:file_stream  
			format "%\n" crandomizer.offset_V_from to:file_stream  
			format "%\n" crandomizer.offset_V_to to:file_stream  
			format "%\n" crandomizer.rotation_W_to to:file_stream  
			format "%\n" crandomizer.tiling_stochastic to:file_stream  
			format "%\n" crandomizer.tiling_high_quality_blending to:file_stream  
			-- Save checkbox states        
			format "%\n" (if chk_stochastic.state then 1 else 0) to:file_stream  
			format "%\n" (if chk_hqblending.state then 1 else 0) to:file_stream  

			-- Close the text file        
			close file_stream  
			free file_stream  
			ForceCompleteRedraw()   
		)  
		 
		function addTriplanar all_selected_materials ctriplanar =  
		(  
			-- Apply CoronaTriplanar node and re-wire all inputs/outputs --        

			for selected_material in all_selected_materials do  
			(  
				-- Process the selected material        
				if (isKindOf selected_material CoronaPhysicalMtl or  
					isKindOf selected_material CoronaLegacyMtl) do  
				(  
					-- Find all used inputs in the material (diffuse/gloss/etc)        
					for i in 1 to selected_material.numsubs do  
					(  
						local tex = getSubAnim selected_material i  
						 
						-- Only add CoronaMappingRandomizer material nodes that are used by a bitmap or node group        
						if (tex != undefined) and (tex[1] != undefined) do  
						(  
							-- count how many inputs/outputs needed for corona randomizer        
							local new_output = MultiOutputChannelTexmapToTexmap()  -- create for additional outputs        
							local input_count = ctriplanar.additionalOutputs += 1 -- add a new output per found node        
							local current_tex = tex.value -- first subanim:value         

							ctriplanar.additionalTexmapX[input_count] = current_tex -- add inputs based on the number of additionalOutputs        
							new_output.outputChannelIndex = (input_count)  
							new_output.sourceMap = ctriplanar  
							tex.value = new_output  

							-- if more than 1 node input, reset the order to accept more input/outputs for randomizer        
							if ctriplanar.texmapX == undefined then  
							(  
								ctriplanar.texmapX = current_tex -- put first texture (diffuse) back into 'input' after being moved to 'input1'        
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
			)  
		)  
		 
		function addColorCorrect selected_materials =  
		(  
			-- Takes the diffuse and adds it to ColorCorrect then back to the materials --      

			local ccorrect = CoronaColorCorrect()   
			 
			for selected_material in selected_materials do  
			(  
				local texture_map = undefined  

				-- Collect Bitmap & CoronaBitmaps           
				if isKindOf selected_material CoronaPhysicalMtl then  
				(  
					texture_map = selected_material.baseTexmap  
				)  
				else if isKindOf selected_material CoronaLegacyMtl then  
				(  
					texture_map = selected_material.texmapDiffuse  
				)  
				 
				if texture_map != undefined then  
				(  
					for i in 1 to selected_material.numsubs do  
					(  
						local tex = getSubAnim selected_material i  
						if (tex != undefined) and (tex[1] != undefined) do  
						(  
							if (MatchPattern (tex as string) pattern:"*baseTexmap*" or  
								MatchPattern (tex as string) pattern:"*texmapDiffuse*") then  
							(  
								local new_output = MultiOutputChannelTexmapToTexmap()  -- create for additional outputs        
								local input_count = ccorrect.additionalOutputs += 1 -- add a new output per found node         
								local current_tex = tex.value -- first subanim:value         
								 
								ccorrect.additionalInputTexmap[input_count] = tex.value -- add inputs based on the number of additionalOutputs        
								new_output.outputChannelIndex = (input_count)  
								new_output.sourceMap = ccorrect  
								tex.value = new_output  

								-- if more than 1 node input, reset the order to accept more input/outputs         
								if ccorrect.inputTexmap == undefined then  
								(  
									ccorrect.inputTexmap = current_tex -- put first texture (diffuse) back into 'input' after being moved to 'input1'         
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
				)  
			)  
		)  

		function addColorCorrectTrans selected_materials =  
		(  
			-- This function relies on the addColorCorrect function --      
			-- It adds takes the diffuse and adds it to ColorCorrect then Transluency      

			local ccorrect = CoronaColorCorrect()   
			local input_count = undefined  
			local current_count = 0  
			 
			for selected_material in selected_materials do  
			(  
				local texture_map = undefined  

				-- Collect Bitmap & CoronaBitmaps           
				if isKindOf selected_material CoronaPhysicalMtl then  
				(  
					texture_map = selected_material.baseTexmap  
				)  
				else if isKindOf selected_material CoronaLegacyMtl then  
				(  
					texture_map = selected_material.texmapDiffuse  
				)  
				 
				if texture_map != undefined then  
				(  
					for i in 1 to selected_material.numsubs do  
					(  
						local current_tex = undefined  
						local tex = getSubAnim selected_material i  
						if (tex != undefined) and (tex[1] != undefined) do  
						(  
							if (MatchPattern (tex as string) pattern:"*baseTexmap*" or  
								MatchPattern (tex as string) pattern:"*texmapDiffuse*") then  
							(  
								local diffuse_ccorrect = tex[1] -- diffuse colorcorrect       
								-- Set the count of inputs once        
								if input_count == undefined then input_count = (diffuse_ccorrect.additionalOutputs)  
								ccorrect.additionalOutputs = input_count  
								local new_output = MultiOutputChannelTexmapToTexmap()  -- create for additional outputs      
								 
								for j = 1 to input_count do  
								(  
									current_tex = diffuse_ccorrect.additionalInputTexmap[j]  
									ccorrect.additionalInputTexmap[j] = current_tex  
									new_output.sourceMap = ccorrect  
								)  
								 
								-- if more than 1 node input, reset the order to accept more input/outputs        
								if ccorrect.inputTexmap == undefined then  
								(  
									ccorrect.inputTexmap = diffuse_ccorrect.inputTexmap -- put first texture (diffuse) back into 'input' after being moved to 'input1'        
									-- Reset counter, material input/output for re-wiring first material      
									new_output.outputChannelIndex = 1  
									-- Material is CoronaPhysical      
									try(selected_materials[1].translucencyColorTexmap = new_output)catch()   
									-- Material is CoronaLegacy         
									try(selected_materials[1].texmapTranslucency = new_output)catch()   
									current_count += 1  
								)  
								else  
								(  
									-- re-order input/output based on additional output update      
									new_output.outputChannelIndex = current_count  
									-- Material is CoronaPhysical      
									try(selected_material.translucencyColorTexmap = new_output)catch()   
									-- Material is CoronaLegacy         
									try(selected_material.texmapTranslucency = new_output)catch()   
								)  
								current_count += 1  
							)  
						)  
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
			-- Main Menu UI Rollout --        

			group "Information"  
			(  
				label lbl_ver "Version 4.1" align:#left across:2  
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
				button btn_ccdiffuse "Color Correct Diffuse" align:#left tooltip:("CoronaColorCorrect Diffuse")  
				button btn_ccdiffusetrans "Color Correct Diffuse + Translucency" align:#left tooltip:("CoronaColorCorrect Diffuse + Translucency")  
			)  

			-- Functions and Buttons for rollout --        

			-- Randomizer + Triplanar Button        
			on btn_both pressed do  
			(  
				btn_cmapping.pressed()   
				btn_ctriplanar.pressed()   
			)  

			-- Randomizer Button        
			on btn_cmapping pressed do  
			(  
				undo on  
				(  
					if selection.count == 0 then  
					(  
						all_selected_materials = addSelectedMaterials()   
						if all_selected_materials != undefined then  
						(  
							-- CoronaMappingRandomizer Materials       
							local crandomizer = copy crandomizer_custom  
							addRandomizer all_selected_materials crandomizer  
						)  
					)  
					else  
					(  
						local all_selected_materials = #()  
						for obj in selection do  
						(  
							if classof obj.material == Multimaterial then  
							(  
								-- Convert Multi-Sub    
								for m in obj.material do  
								(  
									if m != undefined then appendIfUnique all_selected_materials m  
								)  
							)  
							else  
							(  
								-- Materials are not Multi-Sub    
								appendIfUnique all_selected_materials obj.material  
							)  
						)  
						if all_selected_materials != undefined then  
						(  
							-- CoronaMappingRandomizer Objects     
							local crandomizer = copy crandomizer_custom  
							addRandomizer all_selected_materials crandomizer  
						)  
					)  
				)  
			)  

			-- Triplanar Button        
			on btn_ctriplanar pressed do  
			(  
				undo on  
				(  
					if selection.count == 0 then  
					(  
						all_selected_materials = addSelectedMaterials()   
						if all_selected_materials != undefined then  
						(  
							-- CoronaTriplanar Materials       
							local ctriplanar = copy ctriplanar_custom  
							addTriplanar all_selected_materials ctriplanar  
						)  
					)  
					else  
					(  
						local all_selected_materials = #()  
						for obj in selection do  
						(  
							if classof obj.material == Multimaterial then  
							(  
								-- Convert Multi-Sub   
								for m in obj.material do  
								(  
									if m != undefined then appendIfUnique all_selected_materials m  
								)  
							)  
							else  
							(  
								-- Materials are not Multi-Sub   
								appendIfUnique all_selected_materials obj.material  
							)  
						)  
						if all_selected_materials != undefined then  
						(  
							-- CoronaTriplanar Objects     
							local ctriplanar = copy ctriplanar_custom  
							addTriplanar all_selected_materials ctriplanar  
						)  
					)  
				)  
			)  

			-- Color Correct Diffuse Button    
			on btn_ccdiffuse pressed do  
			(  
				undo on  
				(  
					if selection.count == 0 then  
					(  
						all_selected_materials = addSelectedMaterials()   
						if all_selected_materials != undefined then  
						(  
							-- Color Correct Diffuse Materials    
							addColorCorrect all_selected_materials  
						)  
					)  
					else  
					(  
						local all_selected_materials = #()  
						for obj in selection do  
						(  
							if classof obj.material == Multimaterial then  
							(  
								-- Convert Multi-Sub  
								for m in obj.material do  
								(  
									if m != undefined then appendIfUnique all_selected_materials m  
								)  
							)  
							else  
							(  
								-- Materials are not Multi-Sub  
								appendIfUnique all_selected_materials obj.material  
							)  
						)  
						if all_selected_materials != undefined then  
						(  
							-- Color Correct Diffuse Objects    
							addColorCorrect all_selected_materials  
						)  
					)  
				)  
			)  
			 
			-- Color Correct Diffuse + Translucency Button    
			on btn_ccdiffusetrans pressed do  
			(  
				undo on  
				(  
					if selection.count == 0 then  
					(  
						all_selected_materials = addSelectedMaterials()   
						if all_selected_materials != undefined then  
						(  
							-- Color Correct Diffuse + Translucency Materials    
							addColorCorrect all_selected_materials  
							addColorCorrectTrans all_selected_materials  
						)  
					)  
					else  
					(  
						local all_selected_materials = #()  
						for obj in selection do  
						(  
							if classof obj.material == Multimaterial then 
							( 
								-- Convert Multi-Sub 
								for m in obj.material do 
								( 
									if m != undefined then appendIfUnique all_selected_materials m 
								) 
							) 
							else 
							( 
								-- Materials are not Multi-Sub 
								appendIfUnique all_selected_materials obj.material  
							)  
						)  
						if all_selected_materials != undefined then  
						(  
							-- Color Correct Diffuse + Translucency Objects    
							addColorCorrect all_selected_materials  
							addColorCorrectTrans all_selected_materials  
						)  
					)  
				)  
			)  
		)  

		rollout settings_rand_rl "Randomizer: Settings" category:2  
		(  
			-- Randomizer: Settings UI Rollout --         

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

			-- Stochastic Mapping Checkbox Settings        
			on chk_stochastic changed state do  
			(  
				if state then  
				(  
					crandomizer_custom.offset_U_from = -1.0  
					crandomizer_custom.offset_U_to = 1.0  
					crandomizer_custom.offset_V_from = -1.0  
					crandomizer_custom.offset_V_to = 1.0  
					crandomizer_custom.rotation_W_to = 360.0  
					crandomizer_custom.tiling_stochastic = on  
				)  
				else  
				(  
					crandomizer_custom.offset_U_from = 0.0  
					crandomizer_custom.offset_U_to = 0.0  
					crandomizer_custom.offset_V_from = 0.0  
					crandomizer_custom.offset_V_to = 0.0  
					crandomizer_custom.rotation_W_to = 0.0  
					crandomizer_custom.tiling_stochastic = off  
				)  
			)  

			-- High Quality Blending Checkbox Settings        
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

			-- Save UI Settings         
			on btn_save pressed do  
			(  
				saveRandomizerSettings crandomizer_custom chk_stochastic chk_hqblending  
			)  

			-- Reset UI Settings         
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

			-- Check for current settings, if exist use those on rollout Open        
			on settings_rand_rl open do  
			(  
				local saved_settings = getDir(#userScripts) + "\\Vella\\CoronaRandomizer_Settings.txt"  
				if doesFileExist saved_settings then  
				(  
					local file_stream = openfile saved_settings  
					while not eof file_stream do  
					(  
						-- Read randomizer settings from text file        
						crandomizer_custom.offset_U_from = readValue file_stream  
						crandomizer_custom.offset_U_to = readValue file_stream  
						crandomizer_custom.offset_V_from = readValue file_stream  
						crandomizer_custom.offset_V_to = readValue file_stream  
						crandomizer_custom.rotation_W_to = readValue file_stream  
						crandomizer_custom.tiling_stochastic = readValue file_stream  
						crandomizer_custom.tiling_high_quality_blending = readValue file_stream  
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
			-- Triplanar Settings UI Rollout --        

			checkbox chk_prim "Primitive" align:#left across:2  
			checkbox chk_instance "Instance"  
		)  

		-- Create Rollouts        
		rf = newRolloutFloater "Corona Randomizer" 280 410  
		addRollout randomizer_rl rf  
		addRollout settings_rand_rl rf rolledUp:true  
		-- addRollout settings_tri_rl rf --rolledUp:true        
		CUI.REGISTERDIALOGBAR rf  
		-- createDialog randomizer_rl escapeEnable:true style:#(#style_titlebar, #style_sysmenu, #style_toolwindow, #style_resizing, #style_border)        
	)
)

