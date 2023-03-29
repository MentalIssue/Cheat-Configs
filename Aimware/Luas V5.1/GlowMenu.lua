local Menu = gui.Reference("MENU")

local Glow = gui.ColorPicker(gui.Reference("Settings","Theme","UI"), "Glow", "Glow", 117, 147, 255, 255);
local S_Glow = gui.ColorPicker(gui.Reference("Settings","Theme","UI"), "Glow", "Second layer Glow", 117, 147, 255, 0);--Second layer
local X = gui.Slider(gui.Reference("Settings","Theme","UI"), "X", "X", 0, -50, 50, 0.5);
local Y = gui.Slider(gui.Reference("Settings","Theme","UI"), "Y", "Y", 0, -50, 50, 0.5);
local Shadows = gui.Slider(gui.Reference("Settings","Theme","UI"), "Shadows", "Shadows", 100, 0, 1000, 10);

local x = X:GetValue();
local y = Y:GetValue();
local s = Shadows:GetValue();

callbacks.Register("Draw", function()
    if x ~= X:GetValue() then
        x = X:GetValue();
    end
end);

callbacks.Register("Draw", function()
    if y ~= Y:GetValue() then
        y = Y:GetValue();
    end
end);

callbacks.Register("Draw", function()
    if s ~= Shadows:GetValue() then
        s = Shadows:GetValue();
    end
end);

callbacks.Register("Draw", function()
	local gr,gg,gb,ga = Glow:GetValue()
	local sgr,sgg,sgb,sga = S_Glow:GetValue()
		if Menu:IsActive() then
		local Menux,Menuy = Menu:GetValue()
		draw.Color(gr,gg,gb,ga);
		draw.ShadowRect(x+Menux-8, y+Menuy-8, x+Menux+800, y+Menuy+565, s);
		draw.Color(sgr,sgg,sgb,sga);
		draw.ShadowRect(x+Menux-8, y+Menuy-8, x+Menux+800, y+Menuy+565, s);
	end
end)
