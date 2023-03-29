print("Tema2021 + Verieth lua loaded ")

local clyde_script_tab = gui.Tab(gui.Reference("Settings"), "clyde_script_tab", "Clyde Script");

local keybinds = gui.Checkbox(clyde_script_tab, "keybinds", "Enable Keybinds", false);
local watermark = gui.Checkbox(clyde_script_tab, "watermark", "Enable Watermark", false);

local ui_color = gui.ColorPicker(clyde_script_tab, "ui_color", "UI color", 125, 125, 230)

local aspect_ratio = gui.Slider(clyde_script_tab, "aspect_ratio", "Aspect Ratio", 0, 0, 3, 0.05)

gui.Text(clyde_script_tab, "\n\n")
local checkbox_buybot = gui.Checkbox(clyde_script_tab, "Checkbox", "BuyBot Active",  false)
local primary_guns = gui.Combobox(clyde_script_tab, "primary", "Primary", "Off", "Scar-20 | G3SG1","AK47 | M4A1", "SSG-08", "AWP", "SG553 | AUG")
local secondary_guns = gui.Combobox(clyde_script_tab, "Secondary", "Secondary",  "Off", "Dual Berettas", "Deagle | Revolver", "P250","TEC-9 | CZ75-Auto" )
local k_armor = gui.Checkbox(clyde_script_tab, "k_armor", "Buy Kevlar + Armor", false)
local armor = gui.Checkbox(clyde_script_tab, "armor", "Buy Armor", false)
local nades = gui.Checkbox(clyde_script_tab, "nades", "Buy Nades", false)
local buybot_zeus = gui.Checkbox(clyde_script_tab, "zeus", "Buy Zeus",  false)
local defuser = gui.Checkbox(clyde_script_tab, "defuser", "Buy Defuser",  false)
local weapons_ = {"pistol", "revolver", "smg", "rifle", "shotgun", "scout", "autosniper", "sniper", "lmg"}
local hitboxes_ = {"head", "neck", "chest", "stomach", "pelvis", "arms", "legs"}
local primary_w = {"buy scar20", "buy m4a1", "buy ssg08", "buy awp", "buy aug"}
local secondary_w = {"buy elite", "buy deagle", "buy p250", "buy tec9"}

--render
rect = function( x, y, w, h, col )
    draw.Color( col[1], col[2], col[3], col[4] );
    draw.FilledRect(x, y, x + w, y + h)
end

gradient = function( x, y, w, h, col1, col2, is_vertical )
    rect( x, y, w, h, col1 );

    local r, g, b = col2[1], col2[2], col2[3];

    if is_vertical then
        for i = 1, h do
            local a = i / h * 255;
            rect( x, y + i, w, 1, { r, g, b, a } );
        end
    else
        for i = 1, w do
            local a = i / w * 255;
            rect( x + i, y, 1, h, { r, g, b, a } );
        end
    end
end

local handler_variables = 
{
    weapon_group =  {pistol = {2, 3, 4, 30, 32, 36, 61, 63}, 
                     sniper = {9}, 
                     scout = {40}, 
                     hpistol = {1, 64}, 
                     smg = {17, 19, 23, 24, 26, 33, 34}, 
                     rifle = {60, 7, 8, 10, 13, 16, 39}, 
                     shotgun = {25, 27, 29, 35}, 
                     asniper = {38, 11}, 
                     lmg = {28, 14},
                     zeus = {31}
                    }, 
    fps = 0,
    ping = 0,
    server_ip = 0,
    tickrate_updated = false,
    tickrate = client.GetConVar("sv_maxcmdrate"),
    server = "",
    user_name = cheat.GetUserName(),
    local_entity,
}

--script variable 
local color_r, color_g, color_b, color_a;
local mouseX, mouseY, x, y, dx, dy, w, h = 0, 0, 128, 290, 0, 0, 60, 60;
local shouldDrag = false;
local font = draw.CreateFont("Verdana", 12, 12);
local topbarSize = 23;
local imgRGBA, imgWidth, imgHeight = common.DecodePNG( svgData );
local texture = draw.CreateTexture( imgRGBA, imgWidth, imgHeight );

local function handlers()
    --visuals
    color_r, color_g, color_b, color_a = ui_color:GetValue()
    handler_variables.fps = 1 / globals.AbsoluteFrameTime()

    --entities
    handler_variables.local_entity = entities.GetLocalPlayer()

    --local info
    if handler_variables.local_entity then
        handler_variables.is_scoped = handler_variables.local_entity:GetPropBool("m_bIsScoped")

        handler_variables.ping = entities:GetPlayerResources():GetPropInt("m_iPing", client.GetLocalPlayerIndex())
        
        handler_variables.server_ip = engine.GetServerIP()

        if handler_variables.server_ip == "loopback" then
            handler_variables.server = "localhost"
        elseif string.find(handler_variables.server_ip, "A") then
            handler_variables.server = "valve"    
        else
            handler_variables.server = handler_variables.server_ip
        end

        if not handler_variables.tickrate_updated then
            handler_variables.tickrate = client.GetConVar("sv_maxcmdrate")
            handler_variables.tickrate_updated = true
        end
    else
        handler_variables.tickrate_updated = false
    end
end

local function getWeaponGroup()
    if not handler_variables.local_entity or not not handler_variables.local_entity:IsAlive() then
        return "shared"
    end

    --get current weapon group
    local current_weapon_group = "shared"

    for group_name, group_weapons in pairs(weapon_group) do
        for weapon_id = 1, #group_weapons, 1 do

            local local_weapon_id = handler_variables.local_entity:GetWeaponID()

            if local_weapon_id == group_weapons[weapon_id] then
                current_weapon_group = group_name

                break
            end
        end
    end

    return current_weapon_group
end

local function getKeybinds()
    local keybinds_array = {};
    local i = 1;

    if  gui.GetValue("rbot.master") and getWeaponGroup() ~= "zeus" and 
        (gui.GetValue("rbot.accuracy.attack.shared.fire") == '"Shift Fire"' or  gui.GetValue("rbot.accuracy.attack." .. getWeaponGroup() .. ".fire") == "Shift Fire") then

        keybinds_array[i] = '   On shot AA';
        i = i + 1;
    end


	
        
    if gui.GetValue("rbot.master") and cheat.IsFakeDucking() then

        keybinds_array[i] = '   Fake Duck';
        i = i + 1;
    end
            
    if gui.GetValue("rbot.master") and gui.GetValue("rbot.accuracy.movement.slowkey") ~= 0 and input.IsButtonDown(gui.GetValue("rbot.accuracy.movement.slowkey")) then

        keybinds_array[i] = '   Slowwalk';
        i = i + 1;
    end

        
    if gui.GetValue("esp.master") and gui.GetValue("esp.world.thirdperson") then

        keybinds_array[i] = '   Thirdperson';
        i = i + 1;
    end
        
    if gui.GetValue("rbot.master") and getWeaponGroup() ~= "zeus" and 
        (gui.GetValue("rbot.accuracy.attack.shared.fire") == '"Defensive Warp Fire"' or  gui.GetValue("rbot.accuracy.attack." .. getWeaponGroup() .. ".fire") == '"Defensive Warp Fire"') then

        keybinds_array[i] = '   Double shot';
        i = i + 1;
    end
        

    return keybinds_array;
end

local function drawKeybinds(keybinds_array)
    local temp = false;

    for index in pairs(keybinds_array) do

        draw.SetFont(font);
        draw.Color(0, 0, 0, 200);
        draw.Text(x + 13, (y + topbarSize + 5) + (index * 15), keybinds_array[index])
        draw.Text(x + 89, (y + topbarSize + 5) + (index * 15), " [ 👍 ] ")

        draw.SetFont(font);
        draw.Color(255, 255, 255, 255);
        draw.Text(x + 88, (y + topbarSize + 4) + (index * 15), " [ 👍 ] " )
        draw.Text(x + 12, (y + topbarSize + 4) + (index * 15), keybinds_array[index])
    end
end

local function drawRectFill(r, g, b, a, x, y, w, h, texture)
    if (texture ~= nil) then
        draw.SetTexture(texture);
    else
        draw.SetTexture(texture);
    end
    draw.Color(r, g, b, a);
    draw.FilledRect(x, y, x + w, y + h);
end

local function dragFeature()
    if input.IsButtonDown(1) then
        mouseX, mouseY = input.GetMousePos();

        if shouldDrag then
            x = mouseX - dx;
            y = mouseY - dy;
        end

        if mouseX >= x and mouseX <= x + w and mouseY >= y and mouseY <= y + h then
            shouldDrag = true;
            dx = mouseX - x;
            dy = mouseY - y;
        end
    else
        shouldDrag = false;
    end
end

local function drawOutline(r, g, b, a, x, y, w, h, howMany)
    for i = 1, howMany do
        draw.Color(r, g, b, a);
        draw.OutlinedRect(x - i, y - i, x + w + i, y + h + i);
    end
end

local function drawWindow(keybinds_array)
    local h2 = 5 + (#keybinds_array * 15);
    local h = h + (#keybinds_array * 15);
   
    drawRectFill(color_r, color_g, color_b, color_a, x + 7, y + 21, 121, 1); 
    drawRectFill(color_r, color_g, color_b, color_a, x + 7, y + 20, 121, 1);
    drawRectFill(0, 0, 0, 150, x + 7, y + 22, 121, 17);

    draw.Color(0, 0, 0, 255);
    draw.SetFont(font);
    local keytext = "⚔❤ keybinds ❤⚔";
    local tW, _ = draw.GetTextSize(keytext);
   
    draw.Text(x + 20, y + 26, keytext)

    draw.Color(255, 255, 255, 255);
    draw.SetFont(font);
   
    draw.Text(x + 20, y + 26, keytext)
   
    draw.Color(255, 255, 255);
    draw.SetTexture( texture );
end

local function drawWatermark()
    if not watermark:GetValue()  then
        return
    end
 
    local divider = ' | ';
    local cheatName = '❤aimware.net❤ [ v5.1 ]';
 
 
    local watermarkText = cheatName .. divider .. handler_variables.user_name .. divider .. "delay: " ..  handler_variables.ping .. "ms" .. divider .. 
                          "fps: " .. string.format("%0.1f", handler_variables.fps)


    draw.SetFont(font);
    local w, h = draw.GetTextSize(watermarkText);
    local weightPadding, heightPadding = 20, 13;
    local watermarkWidth = weightPadding + w;
    local start_x, start_y = draw.GetScreenSize();
    start_x, start_y = start_x - watermarkWidth - 0, start_y * 0.0125;

    draw.Color(0, 0, 0, 150);
    draw.FilledRect(start_x - 10, start_y, start_x + watermarkWidth - 20, start_y -2 + h + heightPadding );
 
    draw.Color(0, 0, 0, 255)
    draw.Text(start_x + weightPadding /2+4 - 20, start_y + heightPadding / 2 - 1, watermarkText );
 
    draw.Color(255,255,255,255);
    draw.Text(start_x + weightPadding / 2+4 - 20, start_y + heightPadding / 2 - 1, watermarkText );
 
 
    draw.Color(color_r, color_g, color_b, color_a, 255);
    draw.FilledRect(start_x - 10, start_y, start_x + watermarkWidth - 20, start_y +2);
end

local aspect_ration_cache = client.GetConVar("r_aspectratio");

local function setAspectRatio()
    if aspect_ration_cache ~= aspect_ratio:GetValue() then
        client.SetConVar("r_aspectratio", aspect_ratio:GetValue())
        aspect_ration_cache = aspect_ratio:GetValue()
    end
end

local function Events( event )
    if event:GetName() == "round_start" and checkbox_buybot:GetValue() then

        local needtobuy = ""
        local primary = primary_guns:GetValue()
        local secondary = secondary_guns:GetValue()
 
        if k_armor:GetValue() then needtobuy = "buy vesthelm;"  
        end

        if armor:GetValue() then needtobuy = "buy vest;"  
        end
        
        if nades:GetValue() then needtobuy = needtobuy.."buy hegrenade;buy molotov;buy smokegrenade;buy flashbang;buy flashbang;"
        end

        if buybot_zeus:GetValue() then needtobuy = needtobuy.."buy taser;"
        end   

        if defuser:GetValue() then needtobuy = needtobuy.."buy defuser;"
        end

        if primary > 0 then needtobuy = needtobuy..primary_w[primary]..";"  
        end   

        if secondary > 0 then needtobuy = needtobuy..secondary_w[secondary]..";"
        end
 
        client.Command(needtobuy, false)
    end
end
callbacks.Register( "FireGameEvent", Events)

callbacks.Register("Draw", function()
    handlers()

    if not handler_variables.local_entity or not handler_variables.local_entity:IsAlive() then return end

    if keybinds:GetValue() and #getKeybinds() > 0 then
        draw.SetTexture( texture );

        drawWindow(getKeybinds());

        drawKeybinds(getKeybinds());
        dragFeature();
    end

    drawWatermark()

    setAspectRatio()
end)