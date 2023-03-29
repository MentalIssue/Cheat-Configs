--region GUI
local grenade_helper_tab = gui.Tab(gui.Reference("Misc"), "grenade_helper_tab", "Grenade Helper");


--enable group
local enable_script_group = gui.Groupbox(grenade_helper_tab, "Enable Group", 5, 10, 325, 450);
local enable_script = gui.Checkbox(enable_script_group, "enable_script", "Enable Script", true);


--binds group 
local throw_group = gui.Groupbox(grenade_helper_tab, "Throw Group", 5, 105, 325, 450);

local throw_group_ui =
{
};
throw_group_ui.silent_aiming = gui.Checkbox(throw_group, "silent_aiming", "Silent Aiming", false);
throw_group_ui.smooth_of_aiming = gui.Slider(throw_group, "smooth_of_aiming", "Smooth Of Aiming", 5, 1, 100, 1);
throw_group_ui.fov = gui.Slider(throw_group, "fov", "FOV", 90, 0, 360, 1);

throw_group_ui.magnet_key = gui.Keybox(throw_group, "magnet_key", "Magnet Key", 1);
throw_group_ui.magnet_distance = gui.Slider(throw_group, "magnet_distance", "Distance of Magnet", 50, 0, 300);


--visuals group
local visuals_group = gui.Groupbox(grenade_helper_tab, "Visuals Group", 5, 370, 325, 450);

local visuals_group_ui =
{
};

--settings group
local settings_group = gui.Groupbox(grenade_helper_tab, "Settings Group", 340, 10, 290, 350);

local settings_group_ui =
{
};

--nade recorder group 
local nade_recorder_group = gui.Groupbox(grenade_helper_tab, "Nade Recorder Group", 340, 270, 290, 350);

local nade_recorder_group_ui = 
{
};
--endregion





--region HANDLERS
--this variable has all locations settings
local location_array = {};

--all constants will be here
local constants = {};
constants.TICKRATE = 64;
constants.EYE_STANDING = 64;
constants.EYE_DUCKING = 46;

--local data
local local_entity, local_abs, local_eye, local_viewangles, current_map, weapon_id, current_nade;
local screen_width, screen_height;
local real_time;
local magnet_activated = false;

--variables to help navigate into nades arrays
local nade_indexes = {};
nade_indexes.MAP = 1;
nade_indexes.ABS = 2;
nade_indexes.VIEWANGLES = 5;
nade_indexes.NADE_TYPE = 8;
nade_indexes.SPOT_NAME = 9;
nade_indexes.MOVE_TYPE = 10;
nade_indexes.TIME_TO_MOVE = 11;

--variable, that help to navigate in ABS and VIEWANGLES
local vector_indexes = {};
vector_indexes.X = 0;
vector_indexes.Y = 1;
vector_indexes.Z = 2;

local function handleVariables()

    --getting time
    real_time = globals.RealTime()

    --getting screen size
    screen_width, screen_height = draw.GetScreenSize();

    --checking for magnet 
    magnet_activated = throw_group_ui.magnet_key:GetValue() ~= 0 and input.IsButtonDown(throw_group_ui.magnet_key:GetValue());

    --getting local entity
    local_entity = entities.GetLocalPlayer()

    --colecting data about local_entity
    if local_entity and local_entity:IsAlive() then

        --getting position info
        local_abs = local_entity:GetAbsOrigin()
        local_eye = Vector3(0, 0, local_entity:GetPropFloat("localdata", "m_vecViewOffset[2]"))
        local_viewangles = engine.GetViewAngles()

        --getting map
        current_map = engine.GetMapName()

        --finding current nade
        weapon_id = local_entity:GetWeaponID()
        
        --it's just four nades, no reason to make loop
        --decoy will be flashbang too
        if weapon_id == 44 then
            current_nade = "hegrenade"
        elseif weapon_id == 43 or weapon_id == 47 then
            current_nade = "flashbang"
        elseif weapon_id == 45 then 
            current_nade = "smokegrenade"
        elseif weapon_id == 46 or weapon_id == 48 then
            current_nade = "molotov"
        else 
            current_nade = "weapon"
        end
    end
end





--region NADE_RECORDER
--gui
nade_recorder_group_ui.name = gui.Editbox(nade_recorder_group, "name", "Nade Name");
nade_recorder_group_ui.type = gui.Combobox(nade_recorder_group, "type", "Nade Type", "Standing", "Duck", "Move", "Jump Throw", "Move + Jump Throw", "Half Throw");
nade_recorder_group_ui.time_to_move = gui.Slider(nade_recorder_group, "time_to_move", "Time to Move", 0.35, 0.05, 1, 0.05);

--saving nade by current settings
nade_recorder_group_ui.save = gui.Button(nade_recorder_group, "Save Nade", function()

    --adding nade to locations
    location_array[#location_array + 1] = 
    {
        current_map,   
        local_abs.x, local_abs.y, local_abs.z + (nade_recorder_group_ui.type:GetValue() == 1 and constants.EYE_DUCKING or constants.EYE_STANDING),
        local_viewangles.x, local_viewangles.y, local_viewangles.z,
        current_nade,
        nade_recorder_group_ui.name:GetValue(),
        nade_recorder_group_ui.type:GetValue(), 
        nade_recorder_group_ui.time_to_move:GetValue() * constants.TICKRATE,
    }
end)


--removing last nade
nade_recorder_group_ui.remove = gui.Button(nade_recorder_group, "Remove Nade", function()

    --removing last nade
    table.remove(location_array, #location_array)
end)
nade_recorder_group_ui.remove:SetPosY(160)
nade_recorder_group_ui.remove:SetPosX(130)
--endregion





--region SPOTS
--gui
visuals_group_ui.distance_of_visibility = gui.Slider(visuals_group, "distance_of_visibility", "Distance Of Visibility", 500, 10, 2500, 5);


local is_moving_now = false;
local animation_values_array = {};
local valid_spots_array = {};

--gettting valid spots list
local function getValidSpots()

    local nade_array = {}

    --iterating over all nades
    for nade_index, nade_data in pairs(location_array) do
        
        --checking for animations data
        if  animation_values_array[nade_index] then

            --checking for alpha of text
            if animation_values_array[nade_index].size_x > 0 then

                nade_array[nade_index] = nade_data
            end
        end
    end

    return nade_array
end


--getting closest spot
local function getClosestSpot()

    --closest distance it's giant number
    local closest_distance = math.huge

    --later it will show closest spot index
    local closest_spot = 0

    --iterating over all valid spots
    for nade_index, nade_data in pairs(valid_spots_array) do
        
        --calculating distance to spot
        local distance = vector.Distance(local_abs.x, local_abs.y, local_abs.z, 
                                         nade_data[nade_indexes.ABS + vector_indexes.X], nade_data[nade_indexes.ABS + vector_indexes.Y], nade_data[nade_indexes.ABS + vector_indexes.Z]
                                                                                                                                         - (nade_data[nade_indexes.MOVE_TYPE] == 1 and constants.EYE_DUCKING or constants.EYE_STANDING)
                                        )

        --finding closest
        if closest_distance > distance then

            closest_spot = nade_index
            closest_distance = distance
        end
    end

    return closest_spot
end 


constants.CURRENT_SPOT_MAX_DISTANCE = 1;

--it's so low to be maximaly accurate
constants.MOVE_SPEED = 5;

--moving us to current spot
local function moveToClosestSpot(cmd)

    --checking for closest spot
    if not valid_spots_array[getClosestSpot()] then
        return
    end
    
    --getting data of closest nade
    local nade_data = valid_spots_array[getClosestSpot()]

    --getting distance to spot 
    local distance = vector.Distance(nade_data[nade_indexes.ABS + vector_indexes.X], nade_data[nade_indexes.ABS + vector_indexes.Y], nade_data[nade_indexes.ABS + vector_indexes.Z] 
                                    - (nade_data[nade_indexes.MOVE_TYPE] == 1 and constants.EYE_DUCKING or constants.EYE_STANDING), local_abs.x, local_abs.y, local_abs.z)

    --checking for type of using
    if magnet_activated and distance <= throw_group_ui.magnet_distance:GetValue() and not is_moving_now then

        --checking that we are not on required pos
        if distance > constants.CURRENT_SPOT_MAX_DISTANCE then
                
            --substracting nade abs with our abs(way vector)
            local way_vector = {vector.Subtract({nade_data[nade_indexes.ABS + vector_indexes.X], nade_data[nade_indexes.ABS + vector_indexes.Y], nade_data[nade_indexes.ABS + vector_indexes.Z] 
                                        - (nade_data[nade_indexes.MOVE_TYPE] == 1 and constants.EYE_DUCKING or constants.EYE_STANDING)},  {local_abs.x, local_abs.y, local_abs.z})}
            
            --moving to the point
            cmd.forwardmove = (((math.cos(math.rad(local_viewangles.y)) * way_vector[1]) + (math.sin(math.rad(local_viewangles.y)) * way_vector[2])) * constants.MOVE_SPEED)
            cmd.sidemove = (((math.sin(math.rad(local_viewangles.y)) * way_vector[1]) + (math.cos(math.rad(local_viewangles.y)) * -way_vector[2])) * constants.MOVE_SPEED)
        end
    end
end


--getting current spot
local function getCurrentSpot()

    --iterating over all valid nades
    for nade_index, nade_data in pairs(valid_spots_array) do

        --calculating distance to spot
        local distance = vector.Distance(
            local_abs.x, local_abs.y, local_abs.z, 
            nade_data[nade_indexes.ABS + vector_indexes.X], nade_data[nade_indexes.ABS + vector_indexes.Y], nade_data[nade_indexes.ABS + vector_indexes.Z] - (nade_data[nade_indexes.MOVE_TYPE] == 1 and constants.EYE_DUCKING or constants.EYE_STANDING)
        )

        --checking for distance
        if distance <= constants.CURRENT_SPOT_MAX_DISTANCE then 
            
            return nade_index
        end
    end

    return 0
end
--endregion





--region STAGES_CONTROLLERS
local movement_finshed = false;
local aiming_finished = false;
--endregion





--region MOVEMENT
local nade_data_cache = {};
local static_move_time = 0;

constants.GRENADE_THROW_PRETIME = 0.03;
constants.IS_MOVING_DELAY = 0.35;
constants.MAX_MOVE_SPEED = 450;
constants.MAX_DISTANCE_TO_AIM_POINT = 150;
constants.IN_JUMP = bit.lshift(1, 1);
constants.IN_DUCK = bit.lshift(1, 2);


--all movement required to throw
local function spotMovement(cmd)

    --reseting move time
    if not is_moving_now then

        static_move_time = real_time
    end

    --checking, that we are on spot or moving
    if not valid_spots_array[getCurrentSpot()] and not is_moving_now then

        --reseting flag
        movement_finshed = false

        return 
    end

    local sendpacket = cmd.sendpacket

    --disabling auto +w on grenade
    --gui.SetValue("misc.strafe.disablenade", true)

    --getting current nade data and creating cache, to checking it, when will move out from spot
    local nade_data = is_moving_now and nade_data_cache or valid_spots_array[getCurrentSpot()]
    nade_data_cache = nade_data

    --checking for type of nade
    local nade_type = nade_data[nade_indexes.MOVE_TYPE]

    --substracting nade abs with our abs(way vector)
    local way_vector = EulerAngles(0, local_viewangles.y - nade_data[nade_indexes.VIEWANGLES + vector_indexes.Y], 0):Forward()

    --CREATING MOVES
    --standing or half throw
    if nade_type == 0 or nade_type == 5 then  

        --finishing the movent cuz standing doesn't require anything
        movement_finshed = true
    end

    --ducking
    if nade_type == 1 then

        --checking, for nade is not throw
        if sendpacket then
            
            cmd.buttons = bit.bor(cmd.buttons, constants.IN_DUCK)

            if aiming_finished then

                movement_finshed = true
            end
        end
    end
    
    --moving
    if nade_type == 2 then

        --checking for running time
        if real_time - static_move_time < (nade_data[nade_indexes.TIME_TO_MOVE] / constants.TICKRATE)  - constants.GRENADE_THROW_PRETIME and (aiming_finished or is_moving_now) then

            --setting flag, that we are moving to don't check for current spot
            is_moving_now = true

            --moving to the point
            cmd.forwardmove = way_vector.x * constants.MAX_MOVE_SPEED
            cmd.sidemove = way_vector.y * constants.MAX_MOVE_SPEED
        end

        --predfinishing time, throwing the grenade
        if real_time - static_move_time >= (nade_data[nade_indexes.TIME_TO_MOVE] / constants.TICKRATE) - constants.GRENADE_THROW_PRETIME and real_time - static_move_time < (nade_data[nade_indexes.TIME_TO_MOVE] / constants.TICKRATE) then

            --moving to the point
            cmd.forwardmove = way_vector.x * constants.MAX_MOVE_SPEED
            cmd.sidemove = way_vector.y * constants.MAX_MOVE_SPEED

            --throwing
            movement_finshed = true
            aiming_finished = true
        end

        --ending time, finishing the movement
        if real_time - static_move_time >= (nade_data[nade_indexes.TIME_TO_MOVE] / constants.TICKRATE) + constants.IS_MOVING_DELAY then

            is_moving_now = false
        end
    end

    --jump throw
    if nade_type == 3 then

        --checking, for nade is not throw and we are aimed
        if aiming_finished then 

            is_moving_now = true

            --jumping and finishing the movement
            if sendpacket then
                cmd.buttons = bit.bor(cmd.buttons, constants.IN_JUMP)
                movement_finshed = true
            end

            --reseting with some delay to save viewangles
            if real_time - static_move_time >= constants.GRENADE_THROW_PRETIME then
                
                is_moving_now = false
            end
        end
    end

    --moving + jump throw
    if nade_type == 4 then

        --checking for running time
        if real_time - static_move_time < (nade_data[nade_indexes.TIME_TO_MOVE] / constants.TICKRATE) - constants.GRENADE_THROW_PRETIME and (aiming_finished or is_moving_now) then

            --setting flag, that we are moving to don't check for current spot
            is_moving_now = true

            --moving to the point
            cmd.forwardmove = way_vector.x * constants.MAX_MOVE_SPEED
            cmd.sidemove = way_vector.y * constants.MAX_MOVE_SPEED
        end

        --predfinishing time, throwing the grenade
        if real_time - static_move_time >= (nade_data[nade_indexes.TIME_TO_MOVE] / constants.TICKRATE) - constants.GRENADE_THROW_PRETIME and real_time - static_move_time < (nade_data[nade_indexes.TIME_TO_MOVE] / constants.TICKRATE) then

            --jumping
            if sendpacket then
                cmd.buttons = bit.bor(cmd.buttons, constants.IN_JUMP)

                --throwing
                movement_finshed = true
                aiming_finished = true
            end
        end

        --ending time, finishing the movement
        if real_time - static_move_time >= (nade_data[nade_indexes.TIME_TO_MOVE] / constants.TICKRATE)  + constants.IS_MOVING_DELAY then

            is_moving_now = false
        end
    end
end
--endregion





--region THROW_NADE
--making smooth aiming
local angle_x, angle_y, angle_z = 0, 0, 0;
constants.MAX_INACCURACY = 0.02;

--aiming on nade
local function aimOnNade(cmd)

    --checking, that we are on spot or that our movement is finished
    if not is_moving_now and not (valid_spots_array[getCurrentSpot()] and magnet_activated) then

        --reseting flag for anti-aims on grenade
        gui.SetValue("lbot.antiaim.ongrenade", false)
        gui.SetValue("rbot.antiaim.condition.grenade", false)

        --reseting old angles, to aim from last position of crosshair
        if local_viewangles then
            
            angle_x, angle_y, angle_z = local_viewangles.x, local_viewangles.y, local_viewangles.z
        end

        --reseting flag
        aiming_finished = false

        return 
    end 

    --getting spot data
    local nade_data = is_moving_now and nade_data_cache or valid_spots_array[getCurrentSpot()]

    --getting viewangles for nade
    local viewangles_x = nade_data[nade_indexes.VIEWANGLES + vector_indexes.X]
    local viewangles_y = nade_data[nade_indexes.VIEWANGLES + vector_indexes.Y]
    local viewangles_z = nade_data[nade_indexes.VIEWANGLES + vector_indexes.Z]

    --distance check
    local distance = vector.Distance(local_viewangles.x, local_viewangles.y, local_viewangles.z, viewangles_x, viewangles_y, viewangles_z)
    --print(distance)
    if distance >= throw_group_ui.fov:GetValue() then
        return
    end

    --disabling anti-aims on grenade
    gui.SetValue("lbot.antiaim.ongrenade", true)
    gui.SetValue("rbot.antiaim.condition.grenade", true)

    --smooth animation for viewangles
    angle_x = angle_x + (viewangles_x - angle_x) / throw_group_ui.smooth_of_aiming:GetValue()
    angle_y = angle_y + (viewangles_y - angle_y) / throw_group_ui.smooth_of_aiming:GetValue()
    angle_z = angle_z + (viewangles_z - angle_z) / throw_group_ui.smooth_of_aiming:GetValue()
    
    --installing angles for viewmodel and for model by type of aiming
    if throw_group_ui.silent_aiming:GetValue() then
        cmd.viewangles = EulerAngles(angle_x, angle_y, angle_z)
    else
        engine.SetViewAngles(EulerAngles(angle_x, angle_y, angle_z))
        cmd.viewangles = EulerAngles(angle_x, angle_y, angle_z)
    end

    --checking by viewangles, that we are aimed on point
    if math.abs(angle_x - viewangles_x) <= constants.MAX_INACCURACY and math.abs(angle_y - viewangles_y) <= constants.MAX_INACCURACY and math.abs(angle_z - viewangles_z) <= constants.MAX_INACCURACY then
        
        --installing our flag
        aiming_finished = true
    end
end


--throwing nade
local throw_buttons = 0;
local attack_activated = false;

constants.IN_ATTACK = bit.lshift(1, 0)
constants.IN_ATTACK2 = bit.lshift(1, 11)

local function throwNade(cmd)

    --checking, that all stages are done
    if not movement_finshed or not aiming_finished then

        local attack_activated = false;

        return
    end

    --selecting throw type
    local nade_data = is_moving_now and nade_data_cache or valid_spots_array[getCurrentSpot()]
    local throw_type = nade_data[nade_indexes.MOVE_TYPE] == 5 and 1 or 0;
    throw_buttons = (throw_type == 0) and constants.IN_ATTACK or constants.IN_ATTACK2

    if cmd.sendpacket and not attack_activated then
        cmd.buttons = bit.bor(cmd.buttons, throw_buttons)
        attack_activated = true
    elseif cmd.sendpacket and attack_activated then
        cmd.buttons = not cmd.buttons
        attack_activated = false
    end
end
--endregion





--region VISUALS
--GUI
--spots visuals
visuals_group_ui.enable_spots_visualization = gui.Checkbox(visuals_group, "enable_spots_visualization", "Enable Spots Visualization", true);
visuals_group_ui.background_color = gui.ColorPicker(visuals_group_ui.enable_spots_visualization, "background_color", "Background Color", 30, 30, 30, 255);
visuals_group_ui.border_color = gui.ColorPicker(visuals_group_ui.enable_spots_visualization, "border_color", "Border Color", 145, 180, 245, 255);
visuals_group_ui.text_color = gui.ColorPicker(visuals_group_ui.enable_spots_visualization, "text_color", "Text Color", 245, 245, 245, 255);

--aim point visuals
visuals_group_ui.enable_aim_point_vizualization = gui.Checkbox(visuals_group, "enable_aim_point_vizualization", "Enable Aim Point Visualization", true);
visuals_group_ui.aim_line_color = gui.ColorPicker(visuals_group_ui.enable_aim_point_vizualization, "aim_line_color", "", 180, 180, 180, 205);

--font
local font = draw.CreateFont("Bahnschrift SemiBold", 15);

--emoji
constants.BACKGROUND_SIZE = 10;
constants.MOLOTOV_EMOJI = string.char(240, 159, 148, 165);
constants.GRENADE_EMOJI = string.char(240, 159, 146, 165);
constants.SMOKE_EMOJI = string.char(240, 159, 140, 171);
constants.FLASHBANG_EMOJI = string.char(226, 156, 168);
constants.WEAPON_EMOJI = string.char(240, 159, 148, 171);
local nade_emoji = "";

--animations
constants.SIZE_X_SPEED = 0.75;
constants.TEXT_ALPHA_SPEED = 1.25;
constants.START_ANIMATION_ALPHA = 30

constants.MIDDLE_FPS_ANIMATION_VALUE = 450;

local function createSpotsAnimation()

    --checking for local entity
    if not local_entity then

        animation_values_array = {}
        return
    end

    --getting animation scale 
    local animation_scale = constants.MIDDLE_FPS_ANIMATION_VALUE / (1 / globals.AbsoluteFrameTime())

    --iterating over all nades
    for nade_index, nade_data in pairs(location_array) do

        --creating new element with 0 0 0 sizes
        if not animation_values_array[nade_index] then

            animation_values_array[nade_index] = {}

            animation_values_array[nade_index].size_x = 0
            animation_values_array[nade_index].size_y = 0
            animation_values_array[nade_index].text_alpha = 0
        end
        local nade_animations = animation_values_array[nade_index]

        --calculating distance to spot
        local distance = vector.Distance(
                                            local_abs.x, local_abs.y, local_abs.z, 
                                            nade_data[nade_indexes.ABS + vector_indexes.X], nade_data[nade_indexes.ABS + vector_indexes.Y], nade_data[nade_indexes.ABS + vector_indexes.Z] 
                                                                                                                                            - (nade_data[nade_indexes.MOVE_TYPE] == 1 and constants.EYE_DUCKING or constants.EYE_STANDING)
                                        )

        --getting text sizes
        draw.SetFont(font)
        local nade_text = nade_emoji .. "  " .. nade_data[nade_indexes.SPOT_NAME]
        local nade_text_size = {draw.GetTextSize(nade_text)}

        --calculating size of box
        local x_size = nade_text_size[1] + 2 * constants.BACKGROUND_SIZE
        local y_size = 2 * constants.BACKGROUND_SIZE 
        local y_animation_speed = constants.SIZE_X_SPEED / (x_size / y_size)

        --checking for distance, map and current nade and, checking, that current spot is our
        --show up animation
        if current_map == nade_data[nade_indexes.MAP] and distance <= visuals_group_ui.distance_of_visibility:GetValue() and current_nade == nade_data[nade_indexes.NADE_TYPE] 
            and ((valid_spots_array[getCurrentSpot()] and nade_index == getCurrentSpot()) or not valid_spots_array[getCurrentSpot()]) then

            --making animation
            nade_animations.size_x = nade_animations.size_x + constants.SIZE_X_SPEED * animation_scale
            nade_animations.size_y = nade_animations.size_y + y_animation_speed * animation_scale

            --starting text alpha animation
            if nade_animations.size_x >= x_size - 5 and nade_animations.size_y >= y_size - 2 then
                nade_animations.text_alpha = nade_animations.text_alpha + constants.TEXT_ALPHA_SPEED * animation_scale
            end

            --fixing animation limit
            if nade_animations.size_x > x_size then nade_animations.size_x = x_size end
            if nade_animations.size_y > y_size then nade_animations.size_y = y_size end

            local text_color = {visuals_group_ui.text_color:GetValue()}
            if nade_animations.text_alpha > text_color[4] then nade_animations.text_alpha = text_color[4] end

        --show down animation
        else

            --making animation
            nade_animations.text_alpha = nade_animations.text_alpha - constants.TEXT_ALPHA_SPEED * animation_scale

            --starting x and y animation
            if nade_animations.text_alpha < constants.START_ANIMATION_ALPHA then
                nade_animations.size_x = nade_animations.size_x - constants.SIZE_X_SPEED * animation_scale
                nade_animations.size_y = nade_animations.size_y - y_animation_speed * animation_scale
            end

            --fixing animation limit
            if nade_animations.size_x < 0 then nade_animations.size_x = 0 end
            if nade_animations.size_y < 0 then nade_animations.size_y = 0 end
            if nade_animations.text_alpha < 0 then nade_animations.text_alpha = 0 end
        end

        --print(nade_index .. "   " .. nade_animations.text_alpha)
    end
end


--drawing all spots position
local function drawSpotsPosition()

    --getting valid spots
    valid_spots_array = getValidSpots()

    --checking for enable
    if not visuals_group_ui.enable_spots_visualization:GetValue() or not local_entity then
        return 
    end

    --iterating over all valid spots
    for nade_index, nade_data in pairs(valid_spots_array) do

        --getting 2D pos of nade spot
        local nade_position_x, nade_position_y = client.WorldToScreen(
            Vector3(nade_data[nade_indexes.ABS + vector_indexes.X], nade_data[nade_indexes.ABS + vector_indexes.Y], nade_data[nade_indexes.ABS + vector_indexes.Z] 
                                                                                                                    - (nade_data[nade_indexes.MOVE_TYPE] == 1 and constants.EYE_DUCKING or constants.EYE_STANDING))
        )   

        --getting current emoji 
        local nade_type = nade_data[nade_indexes.NADE_TYPE]
        if nade_type == "smokegrenade" then
            nade_emoji = constants.SMOKE_EMOJI
        elseif nade_type == "hegrenade" then
            nade_emoji = constants.GRENADE_EMOJI
        elseif nade_type == "molotov" then
            nade_emoji = constants.MOLOTOV_EMOJI 
        elseif nade_type == "flashbang" then
            nade_emoji = constants.FLASHBANG_EMOJI     
        elseif nade_type == "weapon" then
            nade_emoji = constants.WEAPON_EMOJI
        end

        local nade_animations = animation_values_array[nade_index]

        --checking for visibility of spot position
        if nade_position_x and nade_position_y and nade_animations then

            --flooring position
            nade_position_x, nade_position_y = math.floor(nade_position_x), math.floor(nade_position_y)

            --getting text
            draw.SetFont(font)
            local nade_text = nade_emoji .. "  " .. nade_data[nade_indexes.SPOT_NAME]
            local nade_text_size = {draw.GetTextSize(nade_text)}

            --drawing background
            draw.Color(visuals_group_ui.background_color:GetValue())
            draw.FilledRect(nade_position_x - nade_animations.size_x / 2, nade_position_y - nade_animations.size_y / 2,
                            nade_position_x + nade_animations.size_x / 2, nade_position_y + nade_animations.size_y / 2)

            --drawing border
            draw.Color(visuals_group_ui.border_color:GetValue())
            draw.OutlinedRect(nade_position_x - nade_animations.size_x / 2, nade_position_y - nade_animations.size_y / 2, 
                              nade_position_x + nade_animations.size_x / 2, nade_position_y + nade_animations.size_y / 2)

            local text_color = {visuals_group_ui.text_color:GetValue()}

            --drawing text
            draw.Color(text_color[1], text_color[2], text_color[3], nade_animations.text_alpha)
            draw.Text(math.floor(nade_position_x - nade_text_size[1] / 2),  math.floor(nade_position_y - nade_text_size[2] / 2), nade_text)
        end
    end
end


constants.CIRLCE_SIZE = 5;
constants.AIMED_POINT_DISTANCE_LIMIT = 10;

constants.DISTANCE_TO_AIM_POINT = 150;

--drawing aim points to nades
local function drawNadeAimPoints()

    --checking for enable 
    if not visuals_group_ui.enable_aim_point_vizualization:GetValue() or not valid_spots_array[getCurrentSpot()] then
        return
    end

    --choosing current nade data
    local nade_data = valid_spots_array[getCurrentSpot()]

    --finding the viewangles vector to draw aim point
    local x_vector = constants.DISTANCE_TO_AIM_POINT * math.cos(math.rad(nade_data[nade_indexes.VIEWANGLES + vector_indexes.Y]))
    local y_vector = constants.DISTANCE_TO_AIM_POINT * math.sin(math.rad(nade_data[nade_indexes.VIEWANGLES + vector_indexes.Y]))
    local z_vector = constants.DISTANCE_TO_AIM_POINT * math.sin(math.rad(-nade_data[nade_indexes.VIEWANGLES + vector_indexes.X]))

    --finding nade spot position 
    local nade_pos = Vector3(nade_data[nade_indexes.ABS + vector_indexes.X], nade_data[nade_indexes.ABS + vector_indexes.Y],  nade_data[nade_indexes.ABS + vector_indexes.Z] - (nade_data[nade_indexes.MOVE_TYPE] == 1 and constants.EYE_DUCKING or constants.EYE_STANDING)) + 
                     Vector3(local_eye.x, local_eye.y, nade_data[nade_indexes.MOVE_TYPE] == 1 and constants.EYE_DUCKING or constants.EYE_STANDING)

    --finding aim point pos 2D
    local aim_point_pos = {client.WorldToScreen(Vector3(nade_pos.x + x_vector, nade_pos.y + y_vector, nade_pos.z + z_vector))}

    --checking for visibility of aim point 
    if aim_point_pos[1] and aim_point_pos[2] then

        --flooring the positions
        aim_point_pos[1], aim_point_pos[2] = math.floor(aim_point_pos[1]), math.floor(aim_point_pos[2])

        --getting text size
        draw.SetFont(font)
        local spot_name = "   " .. nade_data[nade_indexes.SPOT_NAME]
        local spot_text_size = {draw.GetTextSize(spot_name)}

        --background
        draw.Color(visuals_group_ui.background_color:GetValue())
        draw.FilledRect(aim_point_pos[1] - constants.BACKGROUND_SIZE, aim_point_pos[2] + constants.BACKGROUND_SIZE, 
                        aim_point_pos[1] + constants.BACKGROUND_SIZE + spot_text_size[1], aim_point_pos[2] - constants.BACKGROUND_SIZE)

        --border
        draw.Color(visuals_group_ui.border_color:GetValue())
        draw.OutlinedRect(aim_point_pos[1] - constants.BACKGROUND_SIZE, aim_point_pos[2] + constants.BACKGROUND_SIZE, 
                          aim_point_pos[1] + constants.BACKGROUND_SIZE + spot_text_size[1], aim_point_pos[2] - constants.BACKGROUND_SIZE)

        --drawing spot name text
        draw.Color(visuals_group_ui.text_color:GetValue())
        draw.Text(aim_point_pos[1], aim_point_pos[2] - math.floor(spot_text_size[2] / 2) - 1, spot_name)

        --drawing aim circle 
        draw.Color(visuals_group_ui.text_color:GetValue())
        draw.FilledCircle(aim_point_pos[1], aim_point_pos[2], constants.CIRLCE_SIZE)

        --drawing line to aim pos
        draw.Color(visuals_group_ui.aim_line_color:GetValue())
        draw.Line(screen_width / 2, screen_height / 2, aim_point_pos[1], aim_point_pos[2])
    end
end
--endregion





--region SETTINGS_SYSTEM
--gui
settings_group_ui.location_name = gui.Editbox(settings_group, "location_name", "Location Name");
settings_group_ui.location_configs = gui.Multibox(settings_group, "Location Configs");

--this variable has gui of all location configs
local location_configs_gui = {};


--SOME STUFF TO CONTROLE CONFIGS MULTIBOX
--filling multibox with found configs
local function getLocationConfigs()

    --enumerating over all files
    file.Enumerate(function(file)
        
        --checking, that name has location postfix
        if string.find(file, "_grenade_helper_location.txt") then

            --creting config name, to make it shorter
            local config_name = string.gsub(file, "_grenade_helper_location.txt", "")

            --adding checkbox with config to multibox
            location_configs_gui[#location_configs_gui + 1] = gui.Checkbox(settings_group_ui.location_configs, config_name, config_name, false)
        end
    end)
end
--creating first configs by this
getLocationConfigs()


--clearing all configs data location_configs_gui and deleting all checkboxes from multibox
local function clearLocationConfigs()

    --iterating over all configs in multibox
    for gui_element_index, gui_element in pairs(location_configs_gui) do

        --removing it from multibox
        gui_element:Remove()
    end

    configs_gui_array = {}
end


--getting active config from multibox
local function getCurrentLocationConfig()

    --iterating over all configs
    for gui_element_index, gui_element in pairs(location_configs_gui) do

        --find active config
        if gui_element:GetValue() then

            --returning his index
            return gui_element_index
        end
    end

    --returning 0 if its no active configs
    return 0
end


--disabling inactive configs
local function disableInactiveLocationConfigs()

    --iterating over all configs
    for gui_element_index, gui_element in pairs(location_configs_gui) do

        --disabling inactive
        gui_element:SetValue(gui_element_index == getCurrentLocationConfig())
    end
end


--CREATING BUTTONS, THAT HANDLING CONFIGS
--loading locations from the file
local load_locations = gui.Button(settings_group, "Load", function()

    --checking for current location
    if not location_configs_gui[getCurrentLocationConfig()] then

        print("Select config to load.")
        return
    end

    --getting script name
    local config_name = location_configs_gui[getCurrentLocationConfig()]:GetName()

    --opening file and checking data
    local file_open = file.Open(config_name .. "_grenade_helper_location.txt", 'r')
    local file_data = file_open:Read()
    file_open:Close()
 
    --adding callback to it to catch global variable
    file_data = file_data .. "\n\ncallbacks.Register('Draw', function() \n\tlocal a = 5 \nend)"
 
    --writing new script and loading it
    file.Write(config_name .. "_grenade_helper_location.lua", file_data)
    LoadScript(config_name .. "_grenade_helper_location.lua")
 
    --changing anti-aims array to arrays from config
    --location_settings is a global variable from loaded script
    location_array = location_settings
     
    --unloading loaded script and deleting it
    UnloadScript(config_name .. "_grenade_helper_location.lua")
    file.Delete(config_name .. "_grenade_helper_location.lua")

    --updating locations list
    clearLocationConfigs()
    getLocationConfigs()
end);
load_locations:SetPosY(110)
load_locations:SetPosX(0)


--creating text, which will be saved like config
local function getLocationConfigData()

    --config will have locations data
    local location_data_text = "location_settings = \n{"

    --iterating over all created locations data 
    for location_index, location_data in pairs(location_array) do

        --for the first location don't add the ", "
        if location_index == 1 then
            location_data_text = location_data_text .. "\n\t{"
        else
            location_data_text = location_data_text .. ", \n\t{"
        end

        --iterating over all locations 
        for nade_index, nade_data in pairs(location_data) do

            --adding settings 
            --this parametrs must be string
            if nade_index == nade_indexes.MAP or nade_index == nade_indexes.SPOT_NAME or nade_index == nade_indexes.NADE_TYPE then
                location_data_text = location_data_text .. "'" .. nade_data .. "', "

            --last element hasn't ", " and closing the "}"
            elseif nade_index == #location_data then
                location_data_text = location_data_text .. nade_data .. "}"
            
            --all other paramentrs
            else
                location_data_text = location_data_text .. nade_data .. ", "
            end
        end
    end

    return location_data_text .. "\n}"
end

--saving locations in file
local save_locations = gui.Button(settings_group, "Save", function()

    --checking for active config
    if not location_configs_gui[getCurrentLocationConfig()] then

        print("Select config to save.")
        return 
    end

    local config_name = location_configs_gui[getCurrentLocationConfig()]:GetName() .. "_grenade_helper_location.txt"


    --creating new file with required data
    file.Delete(config_name)
    file.Write(config_name, getLocationConfigData())

    --updating locations list
    clearLocationConfigs()
    getLocationConfigs()
end);
save_locations:SetPosY(110)
save_locations:SetPosX(130)


--deleting locations file
local delete_locations = gui.Button(settings_group, "Delete", function()

    --checking for active config
    if not location_configs_gui[getCurrentLocationConfig()] then

        print("Select config to delete.")
        return 
    end

    --deleting file
    file.Delete(location_configs_gui[getCurrentLocationConfig()]:GetName() .. "_grenade_helper_location.txt")

    --updating locations list
    clearLocationConfigs()
    getLocationConfigs()
end);
delete_locations:SetPosY(155)
delete_locations:SetPosX(0)


--creating file with locations
local create_locations = gui.Button(settings_group, "Create", function()

    local config_name = settings_group_ui.location_name:GetValue() .. "_grenade_helper_location.txt"

    --creating new file with required data
    file.Write(config_name, getLocationConfigData())

    --updating locations list
    clearLocationConfigs()
    getLocationConfigs()
end);
create_locations:SetPosY(155)
create_locations:SetPosX(130)
--endregion





--region GUI_EDITING
local function editGui()

    throw_group:SetDisabled(not enable_script:GetValue())
    visuals_group:SetDisabled(not enable_script:GetValue())
    settings_group:SetDisabled(not enable_script:GetValue())
    nade_recorder_group:SetDisabled(not enable_script:GetValue())
end
--endregion





--region CALLBACKS
callbacks.Register("Draw", function()

    --gui
    editGui()

    --hadler
    handleVariables()

    --checking for enable and entity
    if not enable_script:GetValue() or not local_entity or not local_entity:IsAlive() then
        return
    end

    --spots 
    createSpotsAnimation()

    --draw nades info
    drawSpotsPosition()
    drawNadeAimPoints()

    --config system
    disableInactiveLocationConfigs()
end)

callbacks.Register("PreMove", function(cmd)

    --checking for enable and entity
    if not enable_script:GetValue() or not local_entity or not local_entity:IsAlive() then
        return
    end

    --moving 
    moveToClosestSpot(cmd)
    spotMovement(cmd)
end)

callbacks.Register("PostMove", function(cmd)
    
    --checking for enable and entity
    if not enable_script:GetValue() or not local_entity or not local_entity:IsAlive() then
        return
    end

    aimOnNade(cmd)
    throwNade(cmd)
end)
--endregion 