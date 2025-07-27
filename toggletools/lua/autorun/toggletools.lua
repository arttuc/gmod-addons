if CLIENT then
	CreateClientConVar("toggletools_cmenuicon", "1", true, false, "Should an icon be added to the context menu in sandbox? Requires reload/reconnect.", 0, 1)

	if GetConVar("toggletools_cmenuicon"):GetInt() > 0 then
		list.Set("DesktopWindows", "physgun-toggle", {
			title = "Toggle Tools",
			icon = "icon64/toggletools.png",
			init = function()
				surface.PlaySound("garrysmod/ui_click.wav")
				LocalPlayer():ConCommand("toggletools")
			end
		})
	end

elseif SERVER then
	-- List of tools to check for.
	local tools = {"weapon_physgun", "gmod_camera", "gmod_tool"}
	-- List of players who have disabled tools.
	---@type table<number, boolean>
	local disabledToolsPlayerTable = {}

	---@param plr Player
	local function hasTools(plr)
		for _, toolName in ipairs(tools) do
			if plr:HasWeapon(toolName) then
				return true
			end
		end
		return false
	end

	---@param plr Player
	local function stripTools(plr)
		local uid = plr:UserID()
		disabledToolsPlayerTable[uid] = true

		for _, toolName in ipairs(tools) do
			plr:StripWeapon(toolName)
		end
	end

	---@param plr Player
	local function giveTools(plr)
		local uid = plr:UserID()
		disabledToolsPlayerTable[uid] = false

		for _, toolName in ipairs(tools) do
			plr:Give(toolName, true)
		end
		plr:SelectWeapon(tools[1])
	end

	concommand.Add("toggletools", function(plr)
		if plr == NULL then -- prevent running from dedicated server console
			print("toggletools can only be executed as a player!")
			return
		end

		if not GAMEMODE.IsSandboxDerived then
			plr:ChatPrint("Cannot use toggletools on non-sandbox gamemodes!")
			return
		end

		if hasTools(plr) then
			stripTools(plr)
		else
			giveTools(plr)
		end
	end, nil, "Toggle tools.")

	gameevent.Listen("player_spawn")
	hook.Add("player_spawn", "toggletools_memory", function(data)
		local uid = data.userid
		if disabledToolsPlayerTable[uid] then
			timer.Simple(0.065, function()
				local plr = Player(uid)
				stripTools(plr)
			end)
		end
	end)

	gameevent.Listen("disconnect")
	hook.Add("disconnect", "toggletools_disconnect", function(_, _, _, uid)
		-- unset dtpt value for disconnected uid
		disabledToolsPlayerTable[uid] = nil
	end)

end
