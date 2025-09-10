obs = obslua
--Global Variables
--Array that holds all possible end iterations. Goes up to 10th end just incase.
endString = {"1st","2nd","3rd","4th", "5th","6th","7th","8th","9th","10th"}
endNumber = 1
--Holds text source that user selects
source_name = ""
source_path = ""
souce_exists = false
source_mode = false
intialized = false
--Holds the hotkeys
increment_hotkey_id = obs.OBS_INVALID_HOTKEY_ID
decrement_hotkey_id = obs.OBS_INVALID_HOTKEY_ID
reset_hotkey_id = obs.OBS_INVALID_HOTKEY_ID

--[[
Increase the end number when pressed and writes that to the source.
Check to make sure that ends doesn't surpass the ends on the array.
]]
intialized = false

function initial_check()
	intialized = true
    check_source_mode()
end

function check_exist()
    if source_mode == true then
        local fr = io.open(source_path, "a")
        if fr ~= nil then
            source_exist = true
        else
            source_exist = false
        end
        fr:close()
    end
    return
end


function update_txt()
	print("Writing to TXT:",endString[endNumber])
	local f = io.open(source_path, "w+")
	f:write(endString[endNumber])
	f:flush()
	f:close()
end

function increment_source(pressed)
	if not pressed then
        return
    end
	if not initial then
        initial_check()
    end
	local source = obs.obs_get_source_by_name(source_name)
	if source ~= nil then
		if endNumber >=10 then
			endNumber = 1
		else
			endNumber= endNumber + 1
		end
		if source_mode then
			update_txt()
		else
			update_source()
		end
	end
	obs.obs_source_release(source)
end
--[[
Same as the increment function, though it will decrease the end instead.
Has a check to make sure the ends don't go below 1, and will then set it to the 8th end
]]
function decrement_source(pressed)
	if not pressed then
        return
    end
	if not intialized then
        initial_check()
    end

	if endNumber <= 1 then
		endNumber = 8
	else
		endNumber = endNumber - 1
	end

	if source_mode then
		update_txt()
	else
		update_source()
	end
end
--[[
Resets ends back to the 1st end
]]
function reset_source(pressed)
	print("resetting")
	if not pressed then
        return
    end
	if not intialized then
        initial_check()
    end
	
	endNumber = 1
	if source_mode then
		update_txt()
	else
		update_source()
	end
end

--[[
Function to reset the source list in the script settings
]]
function reset_source_button()
	print("Reset Button")
	local source = obs.obs_get_source_by_name(source_name)
	if not initialized then
		initial_check()
	end
	endNumber = 1
	if source_mode then
		update_txt()
	else
		update_source()
	end
end

function check_source_mode()
    local r_source = obs.obs_get_source_by_name(source_name)
    if r_source ~= nil then
        local file_red_type = obs.obs_source_get_settings(r_source)
        local read_from = obs.obs_data_get_bool(file_red_type,"read_from_file")
        if read_from == true then
        	source_mode = true
            source_path = obs.obs_data_get_string(file_red_type, "file")
        else
        	source_mode = false
    		source_path = ""
        end
    end
    obs.obs_source_release(r_source)
    check_exist()
end


function update_source()
	local source = obs.obs_get_source_by_name(source_name)
	if source ~= nil then
		local settings = obs.obs_data_create()
		obs.obs_data_set_string(settings, "text", endString[endNumber])
		obs.obs_source_update(source,settings)
		obs.obs_data_release(settings)
		obs.obs_source_release(source)
	end
end
--[[
Creates the options that are in the script menu.
Grabs all created text sources that OBS has in memory. 
]]
function script_properties()
	local props = obs.obs_properties_create()

	local p = obs.obs_properties_add_list(props, "june_ends.source_ends", "End Source", obs.OBS_COMBO_TYPE_EDITABLE, obs.OBS_COMBO_FORMAT_STRING)
	local sources = obs.obs_enum_sources()
	if sources ~= nil then
		for _, source in ipairs(sources) do
			source_id = obs.obs_source_get_unversioned_id(source)
			if source_id == "text_gdiplus" or source_id == "text_ft2_source" then
				local name = obs.obs_source_get_name(source)
				obs.obs_property_list_add_string(p,name,name)
			end
		end
	end
	obs.source_list_release(sources)


	obs.obs_properties_add_button(props, "reset_button", "Reset Ends", reset_source_button)

	return props
end



--Simple Descritpion of what the script is and does
function script_description()
	return "A Simply script to increase or decrease the end at the press of a button"
end
--[[
Stores and retrieves the assigned hotkeys 
]]
function script_save(settings)
	local hotkey_save_array = obs.obs_hotkey_save(increment_hotkey_id)
	obs.obs_data_set_array(settings, "june_ends.increment_hotkey", hotkey_save_array)
	obs.obs_data_array_release(hotkey_save_array)

	local hotkey_save_array2 = obs.obs_hotkey_save(decrement_hotkey_id)
	obs.obs_data_set_array(settings, "june_ends.decrement_hotkey", hotkey_save_array2)
	obs.obs_data_array_release(hotkey_save_array2)

	local hotkey_save_array3 = obs.obs_hotkey_save(reset_hotkey_id)
	obs.obs_data_set_array(settings, "june_ends.reset_hotkey", hotkey_array_save3)
	obs.obs_data_array_release(hotkey_save_array3)
end

--Function to update internal variables to the users settings when updated or when OBS is loaded
function script_load(settings)
	increment_hotkey_id = obs.obs_hotkey_register_frontend("june_ends.increment_hotkey","Increment Ends", increment_source)
	if increment_hotkey_id == nil then
		increment_hotkey_id = obs.OBS_INVALID_HOTKEY_ID
	end
	local hotkey_save_array = obs.obs_data_get_array(settings, "june_ends.increment_hotkey")
	obs.obs_hotkey_load(increment_hotkey_id, hotkey_save_array)
	obs.obs_data_array_release(hotkey_save_array)

	decrement_hotkey_id = obs.obs_hotkey_register_frontend("june_ends.decrement_hotkey","Decrement Ends", decrement_source)
	if decrement_hotkey_id == nil then
		decrement_hotkey_id = obs.OBS_INVALID_HOTKEY_ID
	end
	local hotkey_save_array2 = obs.obs_data_get_array(settings, "june_ends.decrement_hotkey")
	obs.obs_hotkey_load(decrement_hotkey_id, hotkey_save_array2)
	obs.obs_data_array_release(hotkey_save_array2)

	reset_hotkey_id = obs.obs_hotkey_register_frontend("june_ends.reset_hotkey","Reset Ends", reset_source)
	if reset_hotkey_id == nil then
		reset_hotkey_id = obs.OBS_INVALID_HOTKEY_ID
	end
	local hotkey_save_array3 = obs.obs_data_get_array(settings, "june_ends.reset_hotkey")
	obs.obs_hotkey_load(reset_hotkey_id, hotkey_save_array3)
	obs.obs_data_array_release(hotkey_save_array3)
	initial_check()
end

--Addition call to close any open txt files. All files should be closed anyway, but as an extra procaution this is here.
function script_unload()
    io.close()
end

function script_update(settings)
	source_name = obs.obs_data_get_string(settings, "june_ends.source_ends")
	initial = false
end

