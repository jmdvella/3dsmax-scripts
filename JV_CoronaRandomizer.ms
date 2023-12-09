
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
	Version: 4.3
	Software: 3D Studio Max 2024.1
	Engine: Corona 10.0
	Language: Maxscript
	Description-US: Add CoronaMappingRandomizer and/or CoronaTriplanar to all bitmaps in selected objects 
					If no objects are selected in viewport then it will apply to selected materials in the
					slate Editor. Can also apply Color Correct for Diffuse and/or Diffuse + Translucency
					for selected materials. This works different to the CoronaMappingRandomizer & CoronaTriplanar
					as it puts all selected materials Diffuse into one ColorCorrect for changing multiple Diffuse
					colors for all selected materials at once. 
	*/	 

	with animate off  
	(
		----------------------
		-- Common Functions --
		----------------------

		function convertMtls =  
		(  
			-- Returns selected materials (CoronaPhysicalMtl + CoronaLegacyMtl) from slate editor as array --          
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
							if classof node.reference == CoronaPhysicalMtl or 
							   classof node.reference == CoronaLegacyMtl then
							(
								append selected_materials node.reference  
							)
						)  
					)  
					return selected_materials  
				)  
			)  
			return undefined 
		) 
		
		function convertObjMtls =
		(
			-- Returns materials (CoronaPhysicalMtl + CoronaLegacyMtl) from selected objects -- 

			local all_selected_materials = #()

			for obj in selection do
			(
				for m in (getClassInstances CoronaPhysicalMtl target:obj.material) + 
						 (getClassInstances CoronaLegacyMtl target:obj.material) do
				(
					appendIfUnique all_selected_materials m
				) 
			)
			if all_selected_materials != undefined then
			(
				return all_selected_materials
			)
			return undefined 
		)

		function findBitmap material_input = 
		(
			-- Look through all nodes in material to find the bitmap at the start of the chain --
			
			-- format "material_input = %\n" material_input 

			if (classof material_input == MultiOutputChannelTexmapToTexmap) then
			(
				-- Input is Color Correct -> input and index for location of bitmap 
				local cc_input = undefined
				local output_index = material_input.outputChannelIndex
				format "output_index = %\n" output_index 

				if output_index == 1 then
				(
					-- Color Correct source map (input 0)
					cc_input = findBitmap material_input.sourceMap.inputTexmap
					return cc_input
				)
				else
				(
					-- Color Correct (input 1,2,3..)
					cc_input = findBitmap material_input.sourceMap.additionalInputTexmap[output_index-1]
					-- format "cc_input = %\n" cc_input 
					return cc_input
				)
			)
			else
			(
				-- Input is not Color Correct
				for found_bitmap in (getClassInstances Bitmaptexture target:material_input) + 
									(getClassInstances CoronaBitmap target:material_input) do 
				(
					-- format "found_bitmap = %\n" found_bitmap
					return found_bitmap
				) 
			)
			return undefined
		)

		function collectCoronaDiffuse selected_material = 
		(
			-- Collect Diffuse Bitmap from Corona Mtl --
			local diffuse_input = undefined
			
			if isKindOf selected_material CoronaPhysicalMtl then  
			(  
				diffuse_input = selected_material.baseTexmap  
				return diffuse_input
			)  
			else if isKindOf selected_material CoronaLegacyMtl then  
			(  
				diffuse_input = selected_material.texmapDiffuse  
				return diffuse_input
			)
			return undefined
		)

		function collectCoronaTrans selected_material = 
		(
			-- Collect Translucency Bitmap from Corona Mtl --

			local trans_input = undefined
			
			if isKindOf selected_material CoronaPhysicalMtl then  
			(  
				trans_input = selected_material.translucencyColorTexmap  
				return trans_input
			)  
			else if isKindOf selected_material CoronaLegacyMtl then  
			(  
				trans_input = selected_material.texmapTranslucency  
				return trans_input
			)
			return undefined
		)

		----------------------------
		-- Translucency Functions --
		----------------------------

		function deleteTransColorCorrect selected_material = 
		(
			-- If Translucency is Color Correct -> Delete Color Correct --

			print ("Deleting Trans CC")

			for i in 1 to selected_material.numsubs do
			(
				local tex = getSubAnim selected_material i  
				if (tex != undefined) and (tex[1] != undefined) do  
				(  
					-- Translucency is within ColorCorrect
					if (MatchPattern (tex as string) pattern:"*translucencyColorTexmap*" or  
						MatchPattern (tex as string) pattern:"*texmapTranslucency*") then  
					(
						try(local trans_input = selected_material.translucencyColorTexmap)catch() 	-- CoronaPhysicalMtl
						try(local trans_input = selected_material.texmapTranslucency)catch()		-- CoronaLegacyMtl

						if trans_input != undefined then
						(
							if (classof trans_input == CoronaColorCorrect) then
							(
								-- Select Color Correct node in Material Editor -> Delete
								local view = SME.GetView SME.ActiveView
								view.SetSelectedNodes trans_input 	
								view.DeleteSelection()

								print ("Deleted Trans CC: Complete")
							)
						)
					)
				)
			)
		)

		function convertTransIsDiffuse selected_material ccorrect =
		(
			-- # Case 1:
			print("Trans Is Diffuse")

			-- If Translucency is Diffuse and is Color Correct -> Delete Color Correct
			try(deleteTransColorCorrect selected_material)catch()

			for i in 1 to selected_material.numsubs do  
			(  
				local tex = getSubAnim selected_material i  
				if (tex != undefined) and (tex[1] != undefined) do  
				(  
					format "tex: %\n" tex	 
					format "tex.value: %\n" tex.value
					format "tex[1]: %\n" tex[1]
					format "tex[1].value: %\n" tex[1].value		
					
					if (MatchPattern (tex as string) pattern:"*baseTexmap*" or  
						MatchPattern (tex as string) pattern:"*texmapDiffuse*") then  
					(  
						-- Diffuse is within ColorCorrect 
						if (classof tex[1].value == CoronaColorCorrect) then
						(
							local output_index = tex.outputChannelIndex	
							local output_count = tex[1].additionalOutputs

							-- format "output_index: %\n" output_index	
							-- format "output_count: %\n" output_count

							if output_index == 1 then
							(
								-- Color Correct source map (input 0)

								-- Variables for Translucency Color Correct
								local diffuse_ccorrect = tex[1] -- diffuse colorcorrect 
								local new_output = MultiOutputChannelTexmapToTexmap()  -- create for additional outputs
								local new_output_diffuse = MultiOutputChannelTexmapToTexmap()

								-- format "diffuse_ccorrect: %\n" diffuse_ccorrect
								
								new_output.outputChannelIndex = output_index -- set the index of the current input/output
								new_output.sourceMap = ccorrect -- create first or get additional sourceMap node
								ccorrect.additionalOutputs = output_count -- amount of outputs required for Color Correct 
								ccorrect.inputTexmap = tex.value -- UNIQUE for output_index == 1, inputTexmap instead of additionalInputTexmap
								
								-- create last or get additional sourceMap node
								try(selected_material.translucencyColorTexmap = new_output)catch() 	-- CoronaPhysicalMtl
								try(selected_material.texmapTranslucency = new_output)catch() 		-- CoronaLegacyMtl

								-- rewire diffuse to remove additonal source map
								new_output_diffuse.outputChannelIndex = output_index -- set the index of the current input/output
								new_output_diffuse.sourceMap = diffuse_ccorrect -- create first or get additional sourceMap node
								try(selected_material.baseTexmap = new_output_diffuse)catch() 		-- CoronaPhysicalMtl, create last or get additional sourceMap node
								try(selected_material.texmapDiffuse = new_output_diffuse)catch() 	-- CoronaLegacyMtl, create last or get additional sourceMap node
							)
							else
							(
								-- Color Correct (input 1,2,3..)

								-- Variables for Translucency Color Correct
								local diffuse_ccorrect = tex[1] -- diffuse colorcorrect 
								local new_output = MultiOutputChannelTexmapToTexmap()  -- create for additional outputs
								local new_output_diffuse = MultiOutputChannelTexmapToTexmap()

								-- format "diffuse_ccorrect: %\n" diffuse_ccorrect
								
								new_output.outputChannelIndex = output_index -- set the index of the current input/output
								new_output.sourceMap = ccorrect -- create first or get additional sourceMap node
								ccorrect.additionalOutputs = output_count -- amount of outputs required for Color Correct 
								ccorrect.additionalInputTexmap[output_index-1] = tex.value
								
								-- create last or get additional sourceMap node
								try(selected_material.translucencyColorTexmap = new_output)catch() 	-- CoronaPhysicalMtl
								try(selected_material.texmapTranslucency = new_output)catch() 		-- CoronaLegacyMtl

								-- rewire diffuse to remove additonal source map
								new_output_diffuse.outputChannelIndex = output_index -- set the index of the current input/output
								new_output_diffuse.sourceMap = diffuse_ccorrect -- create first or get additional sourceMap node
								try(selected_material.baseTexmap = new_output_diffuse)catch() 		-- CoronaPhysicalMtl, create last or get additional sourceMap node
								try(selected_material.texmapDiffuse = new_output_diffuse)catch() 	-- CoronaLegacyMtl, create last or get additional sourceMap node
							)
						)
					) 
					-- print "Next -- selected_material.numsub\n"
				)
			)
		)

		function convertTransIsBitmap selected_material ccorrect =
		(
			-- # Case 2: 
			print("Trans Is Bitmap")

			for i in 1 to selected_material.numsubs do  
			(  
				local tex = getSubAnim selected_material i  
				if (tex != undefined) and (tex[1] != undefined) do  
				(  
					-- format "tex: %\n" tex	 
					-- format "tex.value: %\n" tex.value
					-- format "tex[1]: %\n" tex[1]
					-- format "tex[1].value: %\n" tex[1].value		

					if (MatchPattern (tex as string) pattern:"*baseTexmap*" or  
						MatchPattern (tex as string) pattern:"*texmapDiffuse*") then  
					(  
						-- Diffuse is within ColorCorrect 
						if (classof tex[1].value == CoronaColorCorrect) then
						(
							local output_index = tex.outputChannelIndex	
							local output_count = tex[1].additionalOutputs

							-- format "output_index: %\n" output_index	
							-- format "output_count: %\n" output_count

							if output_index == 1 then
							(
								-- Color Correct source map (input 0)
								
								-- Variables for Translucency Color Correct
								local diffuse_ccorrect = tex[1] -- diffuse colorcorrect 
								local new_output = MultiOutputChannelTexmapToTexmap()  -- create for additional outputs
								local new_output_diffuse = MultiOutputChannelTexmapToTexmap()

								-- format "diffuse_ccorrect: %\n" diffuse_ccorrect
								
								new_output.outputChannelIndex = output_index -- set the index of the current input/output
								new_output.sourceMap = ccorrect -- create first or get additional sourceMap node
								ccorrect.additionalOutputs = output_count -- amount of outputs required for Color Correct 
								try(ccorrect.inputTexmap = selected_material.translucencyColorTexmap)catch() -- UNIQUE for output_index == 1, inputTexmap instead of additionalInputTexmap
								try(ccorrect.inputTexmap = selected_material.texmapTranslucency)catch() 
								
								-- create last or get additional sourceMap node
								try(selected_material.translucencyColorTexmap = new_output)catch() 	-- CoronaPhysicalMtl
								try(selected_material.texmapTranslucency = new_output)catch() 		-- CoronaLegacyMtl

								-- rewire diffuse to remove additonal source map
								new_output_diffuse.outputChannelIndex = output_index -- set the index of the current input/output
								new_output_diffuse.sourceMap = diffuse_ccorrect -- create first or get additional sourceMap node
								try(selected_material.baseTexmap = new_output_diffuse)catch() 		-- CoronaPhysicalMtl, create last or get additional sourceMap node
								try(selected_material.texmapDiffuse = new_output_diffuse)catch() 	-- CoronaLegacyMtl, create last or get additional sourceMap node
								
							)
							else
							(
								-- Color Correct (input 1,2,3..)

								-- Variables for Translucency Color Correct
								local diffuse_ccorrect = tex[1] -- diffuse colorcorrect 
								local new_output = MultiOutputChannelTexmapToTexmap()  -- create for additional outputs
								local new_output_diffuse = MultiOutputChannelTexmapToTexmap()
								
								-- format "diffuse_ccorrect: %\n" diffuse_ccorrect
								
								new_output.outputChannelIndex = output_index -- set the index of the current input/output
								new_output.sourceMap = ccorrect -- create first or get additional sourceMap node
								ccorrect.additionalOutputs = output_count -- amount of outputs required for Color Correct 
								try(ccorrect.additionalInputTexmap[output_index-1] = selected_material.translucencyColorTexmap)catch() -- UNIQUE for output_index == 1, inputTexmap instead of additionalInputTexmap
								try(ccorrect.additionalInputTexmap[output_index-1] = selected_material.texmapTranslucency)catch() 
								
								-- create last or get additional sourceMap node
								try(selected_material.translucencyColorTexmap = new_output)catch() 	-- CoronaPhysicalMtl
								try(selected_material.texmapTranslucency = new_output)catch() 		-- CoronaLegacyMtl

								-- rewire diffuse to remove additonal source map
								new_output_diffuse.outputChannelIndex = output_index -- set the index of the current input/output
								new_output_diffuse.sourceMap = diffuse_ccorrect -- create first or get additional sourceMap node
								try(selected_material.baseTexmap = new_output_diffuse)catch() 		-- CoronaPhysicalMtl, create last or get additional sourceMap node
								try(selected_material.texmapDiffuse = new_output_diffuse)catch() 	-- CoronaLegacyMtl, create last or get additional sourceMap node
							)
						)
					)
					-- print "Next -- selected_material.numsub\n"
				)
			)
		)

		function addColorCorrectTransExisting selected_materials =  
		(  
			-- Checks if materials are using the same Diffuse & Transluency texture and then runs functions based on the result --

			-- Variables
			local ccorrect = CoronaColorCorrect() 

			-- Variables for Case of
			local trans_is_diffuse = false
			local trans_is_bitmap = false
			
			for selected_material in selected_materials do  
			(  
				local diffuse_input = collectCoronaDiffuse selected_material
				local trans_input = collectCoronaTrans selected_material

				-- Determine Case
				if diffuse_input != undefined and trans_input != undefined then
				(
					local diffuse_bitmap = findBitmap diffuse_input
					local trans_bitmap = findBitmap trans_input
					format "diffuse_bitmap = %\n" diffuse_bitmap
					format "trans_bitmap = %\n" trans_bitmap
					if diffuse_bitmap != undefined and trans_bitmap != undefined then
					(
						-- # Case 1:
						if (diffuse_bitmap == trans_bitmap) then (trans_is_diffuse = true; trans_is_bitmap = false)
						-- # Case 2:
						if (diffuse_bitmap != trans_bitmap) then (trans_is_bitmap = true; trans_is_diffuse = false)
					)
				)

				-- Run Functions / 	# Case 1 = Diffuse & Translucency are the same bitmap
				--					# Case 2 = Diffuse & Translucency are NOT the same bitmap
				case of 
				(
					(trans_is_diffuse == true): convertTransIsDiffuse selected_material ccorrect 	-- # Case 1
					(trans_is_bitmap == true): convertTransIsBitmap selected_material ccorrect 		-- # Case 2
				)
			)
		)

		function addColorCorrectTrans selected_materials =  
		(  
			-- This function relies on the addColorCorrect function --        
			-- It adds takes the diffuse and adds it to ColorCorrect then Transluency 
			
			local ccorrect = CoronaColorCorrect() 
			 
			for selected_material in selected_materials do  
			(  
				local texture_map =  collectCoronaDiffuse selected_material -- Collect Bitmap & CoronaBitmaps
				convertTransIsDiffuse selected_material ccorrect 
			)
		)
		
		function addColorCorrect selected_materials =  
		(  
			-- Takes the diffuse and adds it to ColorCorrect then back to the materials --

			local ccorrect = CoronaColorCorrect()   
			
			for selected_material in selected_materials do  
			(  
				local texture_map =  collectCoronaDiffuse selected_material -- Collect Bitmap & CoronaBitmaps 
				
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

		-----------------------
		-- Randomizer Module --
		-----------------------

		function addRandomizer selected_material crandomizer =  
		(  
			-- Apply CoronaMappingRandomizer node and re-wire all inputs/outputs --  

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
		
		--------------------------
		-- User Settings Module --
		--------------------------

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
		
		---------------
		-- UI Module -- 
		---------------

		-- Variables for Rollout          
		local crandomizer_custom = CoronaMappingRandomizer()   
		local ctriplanar_custom = CoronaTriplanar()   
		local all_selected_materials = undefined  
		 
		rollout randomizer_rl "Main Menu" category:1  
		(  
			-- Main Menu UI Rollout --          

			group "Information"  
			(  
				label lbl_ver "Version 4.3" align:#left across:2  
				HyperLink hyp_tutorial "Contact" align:#right color:(color 0 255 255) hovercolor:(color 0 150 150) visitedcolor:(color 0 200 200) address:"mailto:jmdvella@gmail.com"  
			)  
			group "Instructions"  
			(  
				label lbl_0 "1. Select the objects first" align:#left  
				label lbl_1 "2. If no objects selected then select material(s)" align:#left  
				label lbl_2 "3. Choose your randomizer(s)" align:#left  
				label lbl_3 "4. Undo available if required" align:#left  
			)  
			group "Randomizer Tools"  
			(  
				button btn_cmapping "Randomizer" align:#left width:240 tooltip:("CoronaMappingRandomizer")  
				button btn_ctriplanar "Triplanar" align:#left width:240 tooltip:("CoronaTriplanar")  
				button btn_both "Randomizer + Triplanar" align:#left width:240 tooltip:("CoronaMappingRandomizer + CoronaTriplanar")  
			)
			
			group "Vegetation Tools"
			(
				-- label lbl_4 "Works different to \"Randomizer Tools\"" align:#left
				label lbl_5 "To use \"Translucency\" you must already have" align:#left 
				label lbl_6 "a \"Diffuse - Color Correct\" applied" align:#left 
				button btn_ccdiffuse "Diffuse - Color Correct" align:#left width:240 tooltip:("Adds one CoronaColorCorrect to Diffuse for Multiple Materials")  
				button btn_cctransexisting "Translucency - Color Correct Existing" align:#left width:240 tooltip:("Adds one CoronaColorCorrect to existing Translucency for Multiple Materials") 
				button btn_cctransnew "Translucency - Color Correct New" align:#left width:240 tooltip:("Adds one CoronaColorCorrect to new Translucency for Multiple Materials")  
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
						local all_selected_materials = convertMtls()   
						if all_selected_materials != undefined then  
						(  
							for selected_material in all_selected_materials do  
							(  
								-- CoronaMappingRandomizer Materials    
								local crandomizer = copy crandomizer_custom  
								addRandomizer selected_material crandomizer 
							)  
						)  
					)  
					else  
					(  
						local all_selected_materials = convertObjMtls()   
						if all_selected_materials != undefined then  
						(  
							for selected_material in all_selected_materials do  
							( 
								-- CoronaMappingRandomizer Objects       
								local crandomizer = copy crandomizer_custom  
								addRandomizer selected_material crandomizer  
							) 
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
						local all_selected_materials = convertMtls()   
						if all_selected_materials != undefined then  
						(  
							for selected_material in all_selected_materials do  
							(  
								-- CoronaTriplanar Materials         
								local ctriplanar = copy ctriplanar_custom  
								addTriplanar selected_material ctriplanar  
							) 
						)  
					)  
					else  
					(  
						local all_selected_materials = convertObjMtls()   
						if all_selected_materials != undefined then  
						( 
							for selected_material in all_selected_materials do  
							(  
								-- CoronaTriplanar Objects       
								local ctriplanar = copy ctriplanar_custom  
								addTriplanar selected_material ctriplanar  
							) 
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
						local all_selected_materials = convertMtls()   
						if all_selected_materials != undefined then  
						(  
							-- Color Correct Diffuse Materials      
							addColorCorrect all_selected_materials  
						)  
					)  
					else  
					(  
						local all_selected_materials = convertObjMtls()   
						if all_selected_materials != undefined then  
						(  
							-- Color Correct Diffuse Objects      
							addColorCorrect all_selected_materials  
						)  
					)  
				)  
			) 

			-- Translucency - Color Correct New Button 
			on btn_cctransnew pressed do
			(
				undo on
				(
					if selection.count == 0 then  
					(  
						local all_selected_materials = convertMtls()   
						if all_selected_materials != undefined then  
						(  
							-- Color Correct Translucency New to Materials      
							addColorCorrectTrans all_selected_materials  
						)  
					)  
					else  
					(  
						local all_selected_materials = convertObjMtls()   
						if all_selected_materials != undefined then  
						(  
							-- Color Correct Translucency New to Objects      
							addColorCorrectTrans all_selected_materials  
						)  
					)  
				)
			)
			
			-- Translucency - Color Correct Existing Button 
			on btn_cctransexisting pressed do
			(
				undo on
				(
					if selection.count == 0 then  
					(  
						local all_selected_materials = convertMtls()   
						if all_selected_materials != undefined then  
						(  
							-- Color Correct Translucency Existing to Materials      
							addColorCorrectTransExisting all_selected_materials   
						)  
					)  
					else  
					(  
						local all_selected_materials = convertObjMtls()   
						if all_selected_materials != undefined then  
						(  
							-- Color Correct Translucency Existing to Objects      
							addColorCorrectTransExisting all_selected_materials   
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
		rf = newRolloutFloater "Corona Randomizer" 280 500  
		addRollout randomizer_rl rf  
		addRollout settings_rand_rl rf rolledUp:true  
		-- addRollout settings_tri_rl rf --rolledUp:true          
		CUI.REGISTERDIALOGBAR rf  
		-- createDialog randomizer_rl escapeEnable:true style:#(#style_titlebar, #style_sysmenu, #style_toolwindow, #style_resizing, #style_border)          
	)
)

