--[[
Script written as a 'one button' solution for curling score keeping.
Developped to integrate with how the Okotoks Curling Club had previously handle it's score keeping:with txt files.
At the push of a button the score will be increment or decrement by one, and update the source and the txt file.
The Txt file support is to maintain support for the previous workflow and in snafu situations.
]]

obs = obslua
--Global Varaibles
red_team_score = 0
yellow_team_score = 0
--Holds the OBS source object that the user selects
red_source = nil
yellow_source = nil
--Holds the path to the file that user is using if it's a txt based text object
path_red = ""
path_yellow = ""

double_press_delay = 2
--Holds if each of the sources is txt file based or not, and if that file exists
red_mode = false
yellow_mode = false
red_exist = false
yellow_exist = false
--Defines Hotkeys for use
increase_red_hotkey_id = obs.OBS_INVALID_HOTKEY_ID
decrease_red_hotkey_id = obs.OBS_INVALID_HOTKEY_ID
increase_yellow_hotkey_id = obs.OBS_INVALID_HOTKEY_ID
decrease_yellow_hotkey_id = obs.OBS_INVALID_HOTKEY_ID
reset_hotkey_id = obs.OBS_INVALID_HOTKEY_ID

initial = false
--Adds a check to grab source mode, added this way due to OBS loads scripts before source information
function initial_check()
    initial = true
    check_source_mode()
end
--[[
    Increases red by the amount given as the parameter (hold over from design ideas).
    It will increment red source, and based on source type either write it to the txt file or write to the OBS source

    If it's a txt based source it will check to make sure that it's score is the same as the one in the txt file.
    This is to allow the user to write to the file directly if need be, and then go back to the script when needed.
]]
function increment_red(amount)
    if red_mode == false then
        red_team_score = red_team_score + amount
        update_source_red()
    else 
        local f = io.open(path_red,"r")
        local read_in = f:read("*a")
        f:close()
        if red_team_score ~= tonumber(read_in) then
            print(red_team_score)
            print(read_in)
            red_team_score = tonumber(read_in)
        end
        red_team_score = red_team_score + 1
        update_txt_red()
    end
    return
end
--Same as the red increment but for yellow
function increment_yellow(amount)
    if yellow_mode == false then
        yellow_team_score = yellow_team_score + amount
        update_source_yellow()
    else
        local f = io.open(path_yellow,"r")
        local read_in = f:read("*a")
        f:close()
        if yellow_team_score ~= tonumber(read_in) then
            print(yellow_team_score)
            print(read_in)
            yellow_team_score = tonumber(read_in)
        end
        yellow_team_score = yellow_team_score + 1
        update_txt_yellow()
    end
    return
end
--[[
    Much the same as the red incrment function.
    Additional check to make sure the score never goes below 0
]]
function decrement_red(amount)
    if red_mode == false then
        red_team_score = red_team_score - amount
        if red_team_score < 0 then
            red_team_score = 0
        end
        update_source_red()
    else 
        local f = io.open(path_red,"r")
        local read_in = f:read("*a")
        f:close()
        if red_team_score ~= read_in then
            red_team_score = read_in
        end
        red_team_score = red_team_score - amount
        if red_team_score < 0 then
            red_team_score = 0
        end
        update_txt_red()
    end
    return
end
--Same as the red decrement function, but for the yellow source
function decrement_yellow(amount)
    if yellow_mode == false then
        yellow_team_score = yellow_team_score - amount
        if yellow_team_score < 0 then
            yellow_team_score = 0
        end
        update_source_yellow()
    else
        local f = io.open(path_yellow,"r")
        local read_in = f:read("*a")
        f:close()
        if yellow_team_score ~= read_in then
            yellow_team_score = read_in
        end
        yellow_team_score = yellow_team_score - amount
        if yellow_team_score < 0 then
            yellow_team_score = 0
        end
        update_txt_yellow()
    end
    return
end
--[[
    Resets both scores to zero, generally meant for inbetween games, or if something goes sideways.
    Bypasses the increment and decrement function as to bypass all checks on if the score is the same as the txt file.
]]
function reset()
    yellow_team_score = 0
    red_team_score = 0
    if red_mode == false then
        update_source_red()
    else
        update_txt_red()
    end
    if yellow_mode == false then
        update_source_yellow()
    else
        update_txt_yellow()
    end
    return
end

--[[
Updates the red source if it's an internal OBS source, and not txt file based.
Seperated to decrease size of the increment and decrement functions.
]]
function update_source_red()
    local source = obs.obs_get_source_by_name(red_source)
    if source ~= nil then
        local settings = obs.obs_data_create()
		obs.obs_data_set_string(settings, "text", red_team_score)
		obs.obs_source_update(source,settings)
		obs.obs_data_release(settings)
		obs.obs_source_release(source)
    end
end
--Same as the update red source, but for the yellow source
function update_source_yellow()
    print("update yellow source")
    local source = obs.obs_get_source_by_name(yellow_source)
    if source ~= nil then
        local settings = obs.obs_data_create()
		obs.obs_data_set_string(settings, "text", yellow_team_score)
		obs.obs_source_update(source,settings)
		obs.obs_data_release(settings)
		obs.obs_source_release(source)
    end
end
--[[
Listens for the increment red hotkey.
Seperate for readiablity and allow for initial check.
(as well as design idea hold overs)
]]
function increase_listener_red(pressed)
    if not pressed then
        return
    end
    if not initial then
        initial_check()
    end
    increment_red(1)
end
--Same as the increase listener
function decrease_listener_red(pressed)
    if not pressed then
        return
    end
    if not initial then
        initial_check()
    end

    decrement_red(1)
end
--Same as the increase red listener
function increase_listener_yellow(pressed)
    if not pressed then
        return
    end
    if not initial then
        initial_check()
    end

    increment_yellow(1)
end
--Same as the increase listener
function decrease_listener_yellow(pressed)
    if not pressed then
        return
    end
    if not initial then
        initial_check()
    end
    decrement_yellow(1)
end
--[[
Writes the new score to the txt file of the source. 
Flushes the file of any previously written content.
]]
function update_txt_red()
    local f = io.open(path_red, "w+")
    f:write(red_team_score)
    f:flush()
    f:close()
end
--same as the update txt red function, but for the yellow score
function update_txt_yellow()
    local f = io.open(path_yellow, "w+")
    f:write(yellow_team_score)
    f:flush()
    f:close()
end
--[[
Checks the paths to the files provided by the sources.
If the file does not exist it will not attempt to write to it.

A pop warning should be implement in this case
]]
function check_exist()
    print("check")
    if red_mode == true then
        local fr = io.open(path_red, "a")
        if fr ~= nil then
            print("red exists")
            red_exist = true
        else
            red_exist = false
        end
        fr:close()
    end
    if yellow_mode == true then
        local fy = io.open(path_yellow,"a")
        if fy~= nil then 
            print("yellow exists")
            yellow_exist = true
        else
            yellow_exist =false
        end
        fy:close()
    end
    return
end

--[[
Checks the mode of the sources selected. Then write the outcome to a boolean variable.
This is because writing to the different source types requires a different set of instructions, and would cause errors if one was used in place of them other.
]]
function check_source_mode()
    local r_source = obs.obs_get_source_by_name(red_source)
    if r_source ~= nil then
        local file_red_type = obs.obs_source_get_settings(r_source)
        local read_from = obs.obs_data_get_bool(file_red_type,"read_from_file")
        if read_from == true then
            red_mode = true
            path_red = obs.obs_data_get_string(file_red_type, "file")
        else
            red_mode = false
            path_red = ""
        end
    end
    obs.obs_source_release(r_source)
    local y_source = obs.obs_get_source_by_name(yellow_source)
    if y_source ~= nil then
        print("check yellow mode")
        local file_yellow_type = obs.obs_source_get_settings(y_source)
        local read_from = obs.obs_data_get_bool(file_yellow_type,"read_from_file")
        print(tostring(read_from))
        if read_from == true then
            yellow_mode = true
            path_yellow = obs.obs_data_get_string(file_yellow_type, "file")
        else
            yellow_mode = false
            path_yellow = ""
        end
    end
    obs.obs_source_release(y_source)
    check_exist()
end
--Simple Descritpion of what the script is and does
function script_description()
    return "A script for making managing scoreboard easier! The push of a button... the push of a couple buttons. The reset hotkey will need to double pressed!"
end

--[[
Creates the options that are in the script menu.
Grabs all created text sources that OBS has in memory. 
Refresh button should be implement to allow for these lists to be current
]]
function script_properties()
    local props = obs.obs_properties_create()
    
    local p_sources_r = obs.obs_properties_add_list(props, "june_score.sources_red", "Red Source", obs.OBS_COMBO_TYPE_EDITABLE, obs.OBS_COMBO_FORMAT_STRING)
    local r_sources = obs.obs_enum_sources()
	if r_sources ~= nil then
		for _, source in ipairs(r_sources) do
			source_id = obs.obs_source_get_unversioned_id(source)
			if source_id == "text_gdiplus" or source_id == "text_ft2_source" then
				local name = obs.obs_source_get_name(source)
				obs.obs_property_list_add_string(p_sources_r,name,name)
			end
		end
	end
	obs.source_list_release(r_sources)

    local p_sources_y = obs.obs_properties_add_list(props, "june_score.sources_yellow", "Yellow Source", obs.OBS_COMBO_TYPE_EDITABLE, obs.OBS_COMBO_FORMAT_STRING)
    local y_sources = obs.obs_enum_sources()
	if y_sources ~= nil then
		for _, source in ipairs(y_sources) do
			source_id = obs.obs_source_get_unversioned_id(source)
			if source_id == "text_gdiplus" or source_id == "text_ft2_source" then
				local name = obs.obs_source_get_name(source)
				obs.obs_property_list_add_string(p_sources_y,name,name)
			end
		end
	end
	obs.source_list_release(y_sources)

    return props
end


--[[
Stores and retrieves the assigned hotkeys 
]]
function script_save(settings) 
    local hotkey_save_array = obs.obs_hotkey_save(increase_red_hotkey_id)
    obs.obs_data_set_array(settings, "june_score.increase_red",hotkey_save_array)
    obs.obs_data_array_release(hotkey_save_array)

    hotkey_save_array = obs.obs_hotkey_save(decrease_red_hotkey_id)
    obs.obs_data_set_array(settings, "june_score.decrease_red",hotkey_save_array)
    obs.obs_data_array_release(hotkey_save_array)

    hotkey_save_array = obs.obs_hotkey_save(increase_yellow_hotkey_id)
    obs.obs_data_set_array(settings, "june_score.increase_yellow",hotkey_save_array)
    obs.obs_data_array_release(hotkey_save_array)

    hotkey_save_array = obs.obs_hotkey_save(decrease_yellow_hotkey_id)
    obs.obs_data_set_array(settings, "june_score.decrease_yellow",hotkey_save_array)
    obs.obs_data_array_release(hotkey_save_array)

    hotkey_save_array = obs.obs_hotkey_save(reset_hotkey_id)
    obs.obs_data_set_array(settings, "june_score.reset_score",hotkey_save_array)
    obs.obs_data_array_release(hotkey_save_array)

end

--Function to update internal variables to the users settings when updated or when OBS is loaded
function script_load(settings)
    
    increase_red_hotkey_id = obs.obs_hotkey_register_frontend("june_score.increase_red","Increase Red Score",increase_listener_red)
    if increase_red_hotkey_id == nil then
        increase_red_hotkey_id = obs.OBS_INVALID_HOTKEY_ID
    end
    local hotkey_save_array = obs.obs_data_get_array(settings, "june_score.increase_red")
    obs.obs_hotkey_load(increase_red_hotkey_id, hotkey_save_array)
    obs.obs_data_array_release(hotkey_save_array)

    decrease_red_hotkey_id = obs.obs_hotkey_register_frontend("june_score.decrease_red","Decrease Red Score",decrease_listener_red)
    if decrease_red_hotkey_id == nil then
        decrease_red_hotkey_id = obs.OBS_INVALID_HOTKEY_ID
    end
    local hotkey_save_array1 = obs.obs_data_get_array(settings, "june_score.decrease_red")
    obs.obs_hotkey_load(decrease_red_hotkey_id, hotkey_save_array1)
    obs.obs_data_array_release(hotkey_save_array1)

    increase_yellow_hotkey_id = obs.obs_hotkey_register_frontend("june_score.increase_yellow","Increase Yellow Score", increase_listener_yellow)
    if increase_yellow_hotkey_id == nil then
        increase_yellow_hotkey_id = obs.OBS_INVALID_HOTKEY_ID
    end
    local hotkey_save_array2 = obs.obs_data_get_array(settings, "june_score.increase_yellow")
    obs.obs_hotkey_load(increase_yellow_hotkey_id, hotkey_save_array2)
    obs.obs_data_array_release(hotkey_save_array2)

    decrease_yellow_hotkey_id = obs.obs_hotkey_register_frontend("june_score.decrease_yellow","Decrease Yellow Score", decrease_listener_yellow)
    if decrease_yellow_hotkey_id == nil then
        decrease_yellow_hotkey_id = obs.OBS_INVALID_HOTKEY_ID
    end
    local hotkey_save_array3 = obs.obs_data_get_array(settings, "june_score.decrease_yellow")
    obs.obs_hotkey_load(decrease_yellow_hotkey_id, hotkey_save_array3)
    obs.obs_data_array_release(hotkey_save_array3)

    reset_hotkey_id = obs.obs_hotkey_register_frontend("june_score.reset_score","Reset Score",reset)
    if reset_hotkey_id == nil then
        reset_hotkey_id = obs.OBS_INVALID_HOTKEY_ID
    end
    local hotkey_save_array4 = obs.obs_data_get_array(settings, "june_score.reset_score")
    obs.obs_hotkey_load(reset_hotkey_id, hotkey_save_array4)
    obs.obs_data_array_release(hotkey_save_array4)

end
--Addition call to close any open txt files. All files should be closed anyway, but as an extra procaution this is here.
function script_unload()
    io.close()
end

--Sets the variables to the users selection, resets initial variable to check source type.
function script_update(settings) 
    red_source = obs.obs_data_get_string(settings, "june_score.sources_red")
    yellow_source = obs.obs_data_get_string(settings,"june_score.sources_yellow")

    initial = false
end