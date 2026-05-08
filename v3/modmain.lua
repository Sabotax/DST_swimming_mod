PrefabFiles = {
    "wurt_ripple",
}

Assets = {
	Asset("ANIM", "anim/customanim.zip"),
}

modimport("scripts/util/wurt_settings.lua")

modimport("scripts/util/wurt_swim.lua")

require "modutil"
require "prefabutil"

--SETTINGS
local toggle_swim_keybind = GetModConfigData("enable_swim_keybind")
local swim_only_for_wurt = GetModConfigData("swim_only_for_wurt")
local swim_blocked_for_wx78 = GetModConfigData("swim_blocked_for_wx78")
local swim_speed_multiplier_wurt = GetModConfigData("swim_speed_multiplier_wurt")
local swim_speed_multiplier_not_wurt = GetModConfigData("swim_speed_multiplier_not_wurt")
-- used in wurt_swim.lua
--local drop_handitem_wurt = GetModConfigData("drop_handitem_wurt")
--local drop_handitem_not_wurt = GetModConfigData("drop_handitem_not_wurt")


local MakePlayerCharacter = require "prefabs/player_common"
local ClearFloaters = require "prefabs/wurt_clear_floaters"
local MakeWurtSwimmer = require "modifications/wurt_swimmer"
local WurtSwimmer = MakeWurtSwimmer({
    swim_speed_multiplier_wurt = swim_speed_multiplier_wurt,
    swim_speed_multiplier_not_wurt = swim_speed_multiplier_not_wurt,
})

modimport("scripts/wurt_quotes.lua")


-- many of functions and variables name refer to wurt, because that's how they were called in wurt only version of mode
-- before I started changing it
-- I dont feel need to change names, I dont want to break anything and waste time fixing it
-- maybe I can change variable names in later versions
local function SetSwimmingTags(inst)
	if inst.components.rider and inst.components.rider:IsRiding() then
		inst._wurt_swimmer:set(false)
	else
		inst._wurt_swimmer:set(true)
	end
end 


local function OnMount(inst)
	inst._wurt_swimmer:set(false)
end

local function OnDismount(inst)
	inst._wurt_swimmer:set(true)
end

local function OnBucked(inst)
	inst._wurt_swimmer:set(true)
end

-- When the character is revived from human
local function onbecamehuman(inst)
	if inst._wurt_swimmer then
		inst._wurt_swimmer:set(true)
	end
end

local function onbecameghost(inst)
	if inst._wurt_swimmer then
		inst._wurt_swimmer:set(false)
	end
end

local function OnWater(inst)
    return inst:HasTag("swimming") and inst._wurt_swimmer:value() and inst:HasTag("jump_swim")
end

AddModRPCHandler("swimmod", "toggle_swim", function(player)
	if player._wurt_tryingswim:value() == false then
		player.components.talker:Say(GLOBAL.GetString(player, "ANNOUNCE_PRESWIM"))
		player._wurt_tryingswim:set(true)
		player:DoTaskInTime(3,function(player)
				
				--Repeats this function until the user isn't above the water when exiting "the trying to swim" state (prevents walking on water)
				local function ensureNoLand()
					local x, y, z = player.Transform:GetWorldPosition()
					local land_in_water = (GLOBAL.TheWorld.Map:IsOceanAtPoint(x, y, z) and GLOBAL.TheWorld.Map:GetPlatformAtPoint(x, z) == nil)
					if(land_in_water == false) then 
						player.components.talker:Say(GLOBAL.GetString(player, "ANNOUNCE_DONESWIM"))
						player._wurt_tryingswim:set(false)
					else
						player:DoTaskInTime(1,function(player)
							ensureNoLand()
						end)
					end
				end

				-- if we start swim mode on land and then it end without swimming, we dont want to tell quote as we ended swimming
				-- instead we say that character changed mind etc
				local function ensureNoLandFirstExecution()
					local x, y, z = player.Transform:GetWorldPosition()
					local land_in_water = (GLOBAL.TheWorld.Map:IsOceanAtPoint(x, y, z) and GLOBAL.TheWorld.Map:GetPlatformAtPoint(x, z) == nil)
					if(land_in_water == false) then 
						player.components.talker:Say(GLOBAL.GetString(player, "ANNOUNCE_NOSWIM"))
						player._wurt_tryingswim:set(false)
					else
						player:DoTaskInTime(1,function(player)
							ensureNoLand()
						end)
					end
				end
				
				ensureNoLandFirstExecution()
			end)
	end
end)

AddPlayerPostInit(function(inst)
	inst:ListenForEvent("ms_respawnedfromghost", onbecamehuman)
	inst:ListenForEvent("ms_becameghost", onbecameghost)
	inst.floater1 = nil
	inst.floater2 = nil
	inst.water_shadow = nil
	if inst:HasTag("playerghost") then
		onbecameghost(inst)
	else
		onbecamehuman(inst)
	end
	inst:AddTag("jump_swim")
	
	inst._wurt_swimmer = GLOBAL.net_bool(inst.GUID,"wurt._wurt_swimmer","_wurt_swimmer_dirty")
	inst._wurt_tryingswim = GLOBAL.net_bool(inst.GUID,"wurt._wurt_tryingswim","_wurt_tryingswim_dirty")
    inst:AddTag("wurt")
	inst._wurt_swimmer:set(true)
	
	local x, y, z = inst.Transform:GetWorldPosition()
	local in_water = (GLOBAL.TheWorld.Map:IsOceanAtPoint(x, y, z) and GLOBAL.TheWorld.Map:GetPlatformAtPoint(x, z) == nil)
	
	if in_water then
		inst._wurt_tryingswim:set(true)
	else
		inst._wurt_tryingswim:set(false)
	end
	
	WurtSwimmer(inst)
	
	inst:ListenForEvent("playeractivated", WurtSwimmer)
	inst:ListenForEvent("wurtMount",OnMount)
	inst:ListenForEvent("wurtDismount",OnDismount)
	inst:ListenForEvent("wurtBucked",OnBucked)
	
	inst:ListenForEvent("_wurt_swimmer_dirty", 
		function (inst)
			if not inst._wurt_swimmer:value() then
				ClearFloaters(inst)
			end
			
			WurtSwimmer(inst)
		end
	)
	
	inst:ListenForEvent("_wurt_tryingswim_dirty", WurtSwimmer)
	

	if not GLOBAL.TheWorld.ismastersim then
		inst:DoTaskInTime(0, function()
			if inst ~= GLOBAL.ThePlayer then return end

			-- wurt can swim always
			if inst.prefab == "wurt" then
				GLOBAL.TheInput:AddKeyDownHandler(toggle_swim_keybind, function()
					GLOBAL.SendModRPCToServer(
						GLOBAL.MOD_RPC["swimmod"]["toggle_swim"]
					)
				end)
			else
				-- everyone else can swim only if toggled
				if not swim_only_for_wurt then
					-- wx can swim only if not blocked
					if inst.prefab == "wx78" and not swim_blocked_for_wx78 then 
						GLOBAL.TheInput:AddKeyDownHandler(toggle_swim_keybind, function()
							GLOBAL.SendModRPCToServer(
								GLOBAL.MOD_RPC["swimmod"]["toggle_swim"]
							)
						end)
					end
					-- other can always swim (if allowed higher)
					if inst.prefab ~= "wx78" then
						GLOBAL.TheInput:AddKeyDownHandler(toggle_swim_keybind, function()
							GLOBAL.SendModRPCToServer(
								GLOBAL.MOD_RPC["swimmod"]["toggle_swim"]
							)
						end)
					end
				end
			end
			
			
		end)
	end

end)
