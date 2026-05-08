local FRAMES = GLOBAL.FRAMES
local COLLISION = GLOBAL.COLLISION
local jumpdur = 20

local drop_handitem_wurt = GetModConfigData("drop_handitem_wurt")
local drop_handitem_not_wurt = GetModConfigData("drop_handitem_not_wurt")

local function GetSwimString(inst, key)
    local char = inst.prefab

    local t = GLOBAL.STRINGS.CHARACTERS[char]
    if t and t[key] then
        return t[key]
    end

    return GLOBAL.STRINGS.CHARACTERS.GENERIC[key]
end

--Remove tools from hands when swimming
local function drop(inst)
    local should_drop =
            (inst.prefab == "wurt" and drop_handitem_wurt)
            or
            (inst.prefab ~= "wurt" and drop_handitem_not_wurt)

        if not should_drop then
            return
        end

	local hand = inst.components.inventory:GetEquippedItem(GLOBAL.EQUIPSLOTS.HANDS)
	if hand then
        print("Dropping item swim")
		local item = inst.components.inventory:Unequip(GLOBAL.EQUIPSLOTS.HANDS)
		inst.components.inventory:DropItem(item)
		inst.SoundEmitter:PlaySound("dontstarve/common/tool_slip")
		inst.components.talker:Say(GetSwimString(inst, "ANNOUNCE_SWIMTOOL"))
		inst.AnimState:ClearOverrideSymbol("swap_object")
	end
end

-- Floaters aka Ripple effects
local function AddFloaters(inst)
    if not inst.floater1 and not inst.floater2 then
        inst.floater1 = inst:SpawnChild("float_fx_front2")
        inst.floater2 = inst:SpawnChild("float_fx_back2")
		
        inst.floater1.Transform:SetPosition(0,0.6,0)
        inst.floater2.Transform:SetPosition(0,0.6,0)
		
    else
        inst.floater1:Show()
        inst.floater2:Show()
    end
	inst.AnimState:HideSymbol("leg") inst.AnimState:HideSymbol("foot") inst.AnimState:HideSymbol("tail")
end

-- Adds things to the player after initialization
AddPlayerPostInit(function(inst)
    inst:ListenForEvent("addRippleFx",AddFloaters)
end)

AddModRPCHandler(TUNING.WURT_MODNAME,"WurtHop",function(inst,_x,_z)
    if not inst.sg:HasStateTag("jumping") then
        inst:PushEvent("onhop",{x=_x,z=_z})
    end
end)


local function UpdateEmbarkingPos(inst,dt)
    if inst.last_embark_x and inst.last_embark_z then
        inst.components.locomotor:SetAllowPlatformHopping(true)
        local embark_x, embark_z = inst.last_embark_x, inst.last_embark_z

        local my_x, my_y, my_z = inst.Transform:GetWorldPosition()
        local delta_x, delta_z = embark_x - my_x, embark_z - my_z
        local delta_dist = math.max(GLOBAL.VecUtil_Length(delta_x, delta_z), 0.0001)
        local travel_dist = inst.components.embarker.embark_speed * dt

        delta_x, delta_z = travel_dist * delta_x / delta_dist, travel_dist * delta_z / delta_dist
        -- inst.Physics:TeleportRespectingInterpolation(my_x + delta_x, my_y, my_z + delta_z)
        inst.Transform:SetPosition((my_x + delta_x),my_y,(my_z + delta_z))
        if delta_dist <= travel_dist then
            inst:PushEvent("done_wurt_movement")
        end
        if not GLOBAL.TheWorld.ismastersim then
            SendModRPCToServer(MOD_RPC[TUNING.WURT_MODNAME]["WurtHop"],inst.last_embark_x,inst.last_embark_z)
        end
    end
end

local function OnWater(inst)
    return inst:HasTag("swimming") and inst._wurt_swimmer:value() and inst:HasTag("jump_swim")
end

-- Clear Floaters
local ClearFloaters = require "prefabs/wurt_clear_floaters"

local function AddRipple(inst)
    if OnWater(inst) and GLOBAL.TheWorld.ismastersim then
        local wake = GLOBAL.SpawnPrefab("wake_small")
        local rotation = inst.Transform:GetRotation()

        local theta = rotation * GLOBAL.DEGREES
        local offset = GLOBAL.Vector3(math.cos( theta ), 0, -math.sin( theta ))
        local pos = GLOBAL.Vector3(inst.Transform:GetWorldPosition()) + offset
        wake.Transform:SetPosition(pos.x,pos.y + 0.6,pos.z)
        wake.Transform:SetScale(1.2,1.2,1.2)

        wake.Transform:SetRotation(rotation - 90)
        inst.SoundEmitter:PlaySound("turnoftides/common/together/water/splash/jump_small",nil,.25)
    end
end

local function SpawnFX(inst,fx)
    local x,y,z = inst.Transform:GetWorldPosition()
    GLOBAL.SpawnPrefab(fx).Transform:SetPosition(x,y + 0.6 - 0.1,z)
end

--Wurt states, Changes wurt's animation on water
local function WurtStates(sg)
    
    local mount = sg.states["mount"]
    if mount then
        local old_mount_onenter = mount.onenter
        mount.onenter = function(inst,...)
            if inst:HasTag("wurt") then
                inst:PushEvent("wurtMount")
                old_mount_onenter(inst,...)
            else
                old_mount_onenter(inst,...)
            end
        end
    end
	local dismount = sg.states["dismount"]
    if dismount then
        local old_dismount_onenter = dismount.onenter
        dismount.onenter = function(inst,...)
            if inst:HasTag("wurt") then
                inst:PushEvent("wurtDismount")
                old_dismount_onenter(inst,...)
            else
                old_dismount_onenter(inst,...)
            end
        end
    end
	local bucked = sg.states["bucked"]
    if bucked then
        local old_bucked_onenter = bucked.onenter
        bucked.onenter = function(inst,...)
            if inst:HasTag("wurt") then
                inst:PushEvent("wurtBucked")
                old_bucked_onenter(inst,...)
            else
                old_bucked_onenter(inst,...)
            end
        end
    end
    local mine = sg.states["mine"]
    if mine then
        local old_mine_onenter = mine.onenter
        mine.onenter = function(inst,...)
            if inst:HasTag("wurt") and OnWater(inst) then
                ClearFloaters(inst)
                old_mine_onenter(inst,...)
            else
                old_mine_onenter(inst,...)
            end
        end
    end
    local idle = sg.states["idle"]
    if idle then
        local old_idle_onenter = idle.onenter
        idle.onenter = function(inst,...)
            if inst:HasTag("wurt") and OnWater(inst) then
				if GLOBAL.TheWorld.ismastersim then 
					inst.components.moisture:DoDelta(100)
				end
                inst:PushEvent("addRippleFx")
                inst.DynamicShadow:Enable(false)
                old_idle_onenter(inst,...)
            else
                old_idle_onenter(inst,...)
                -- ClearFloaters(inst)
            end
        end
    end

    local run_start = sg.states["run_start"]
    if run_start then
        local old_run_start_onenter = run_start.onenter
        run_start.onenter = function(inst,...)
            if inst:HasTag("wurt") and OnWater(inst) then
				if GLOBAL.TheWorld.ismastersim then 
					inst.components.moisture:DoDelta(100)
					drop(inst)
				end
                inst.components.locomotor:RunForward()
                inst.AnimState:PlayAnimation("careful_walk_pre")
                inst.sg.mem.footsteps = 0
                inst:PushEvent("addRippleFx")
            else
                old_run_start_onenter(inst,...)
                ClearFloaters(inst)
            end
        end
    end

    local run = sg.states["run"]
    if run then
        local old_run_onenter = run.onenter

        run.onenter = function(inst,...)
            if inst:HasTag("wurt") and OnWater(inst)  then
				if GLOBAL.TheWorld.ismastersim then 
					inst.components.moisture:DoDelta(100)
					drop(inst)
				end
                inst.components.locomotor:RunForward()
                if not inst.AnimState:IsCurrentAnimation("customanim") then
                    inst.AnimState:PlayAnimation("customanim", true)
                end
                inst.sg:SetTimeout(inst.AnimState:GetCurrentAnimationLength())
                AddRipple(inst)
                inst:PushEvent("addRippleFx")
            else
                old_run_onenter(inst,...)
            end
        end
    end

    local run_stop = sg.states["run_stop"]
    if run_stop then
        local old_run_stop_onenter = run_stop.onenter
        run_stop.onenter = function(inst,...)
            if inst:HasTag("wurt") and OnWater(inst) then
                inst.components.locomotor:Stop()
                inst.AnimState:PlayAnimation("careful_walk_pst")
                inst:PushEvent("addRippleFx")
            else
                old_run_stop_onenter(inst,...)
            end
        end
    end

    local onhop = sg.events["onhop"]
    if onhop then
        local old_onhop_fn = onhop.fn
        onhop.fn = function(inst,data,...)
            if inst:HasTag("wurt") and inst._wurt_swimmer:value() and (inst._wurt_tryingswim:value() or OnWater(inst) or not inst:HasTag("buttonSwim"))  then
                if GLOBAL.TheWorld:HasTag("cave") then
                    return
                end
                if (inst.components.health == nil or not inst.components.health:IsDead()) and (inst.sg:HasStateTag("moving") or inst.sg:HasStateTag("idle")) then
                    if not inst.sg:HasStateTag("jumping") then
                        inst.sg:GoToState("wurt_hop_pre", data)
                    end
                elseif inst.components.embarker then
                    inst.components.embarker:Cancel()
                end
            else
                return old_onhop_fn(inst,data,...)
            end
        end
    end
end

local function WurtPreHop()
    local hopState =
    GLOBAL.State{
        name = "wurt_hop_pre",
        tags = { "doing", "nointerrupt", "busy", "jumping", "nomorph", "nosleep"},

        onenter = function(inst, data)
            if inst.components.drownable then
                inst.components.drownable.enabled = false
            end
            inst:AddTag("jump_swim")
            if data then
                inst.last_embark_x, inst.last_embark_z = data.x, data.z
            else
                inst.last_embark_x, inst.last_embark_z = nil, nil
            end
            ClearFloaters(inst)
            inst.components.locomotor:Stop()
            inst.sg.statemem.swimming = inst:HasTag("swimming")
            inst.AnimState:PlayAnimation("jump", false)
            inst.AnimState:PushAnimation("jump_loop", false)
            inst.DynamicShadow:Enable(true)
            inst.sg.statemem.collisionmask = inst.Physics:GetCollisionMask()
            inst.Physics:SetCollisionMask(COLLISION.GROUND)
            if not GLOBAL.TheWorld.ismastersim then
                inst.Physics:SetLocalCollisionMask(COLLISION.GROUND)
            end

            inst.sg:SetTimeout(jumpdur * FRAMES)

            if inst.components.embarker:HasDestination() then
                inst.components.embarker:StartMoving()
            end
        end,

        onupdate = function(inst,dt)
            if not inst.components.embarker:HasDestination() then
                UpdateEmbarkingPos(inst,dt)
            end
            if inst.components.embarker:HasDestination() then
                if inst.sg.statemem.embarked then
                    inst.components.embarker:Embark()
                    inst.sg:GoToState("wurt_hop_post", {land_in_water = false, collisionmask = inst.sg.statemem.collisionmask})
                elseif inst.sg.statemem.timeout then
                    inst.components.embarker:Cancel()
                    local x, y, z = inst.Transform:GetWorldPosition()
                    inst.sg:GoToState("wurt_hop_post", {land_in_water = (GLOBAL.TheWorld.Map:IsOceanAtPoint(x, y, z) and GLOBAL.TheWorld.Map:GetPlatformAtPoint(x, z) == nil), collisionmask = inst.sg.statemem.collisionmask})
                end
            elseif inst.sg.statemem.swimming == GLOBAL.TheWorld.Map:IsVisualGroundAtPoint(inst.Transform:GetWorldPosition()) then
                if inst.sg.statemem.wurt_jump or inst.sg.statemem.timeout then
                    inst.components.locomotor:FinishHopping()
                    local x, y, z = inst.Transform:GetWorldPosition()
                    inst.sg:GoToState("wurt_hop_post", {land_in_water = (GLOBAL.TheWorld.Map:IsOceanAtPoint(x, y, z) and GLOBAL.TheWorld.Map:GetPlatformAtPoint(x, z) == nil), collisionmask = inst.sg.statemem.collisionmask})
                end
            end
        end,
        
        timeline =
        {
            GLOBAL.TimeEvent(0, function(inst)
                if inst:HasTag("swimming") and GLOBAL.TheWorld.ismastersim then
                    SpawnFX(inst,"splash_green")
                    ClearFloaters(inst)
                end
            end),
        },

        ontimeout = function(inst)
            inst.sg.statemem.timeout = true
        end,

        events =
        {
            GLOBAL.EventHandler("done_embark_movement", function(inst)
                inst.sg.statemem.embarked = true
            end),
            GLOBAL.EventHandler("done_wurt_movement", function(inst)
                inst.sg.statemem.wurt_jump = true
            end),
        },

        onexit = function(inst)
            if not (inst.sg.statemem.embarked or inst.sg.statemem.wurt_jump) then
                inst.components.embarker:Cancel()
                inst.components.locomotor:FinishHopping()
            end
            inst.Physics:ClearLocalCollisionMask()
            if inst.sg.statemem.collisionmask ~= nil then
                inst.Physics:SetCollisionMask(inst.sg.statemem.collisionmask)
            end
            if inst.components.locomotor.isrunning then
                inst:PushEvent("locomote")
			end
        end,
    }
    return hopState
end

local function WurtPostHop()
    local state =
    GLOBAL.State{
        name = "wurt_hop_post",
        tags = { "busy", "jumping","nopredict"},

        onenter = function(inst, data)
		
			--Make sure the player is "trying to swim" if they land in the water
			if data.land_in_water  and not inst._wurt_tryingswim:value() then
				inst._wurt_tryingswim:set(true) 
			--Make sure the player is not "trying to swim" if they exit the water
			elseif not data.land_in_water and inst._wurt_tryingswim:value() then
				inst._wurt_tryingswim:set(false)
			end
            inst.sg.statemem.collisionmask = data.collisionmask and data.collisionmask or nil
            if data.land_in_water and  inst.components.amphibiouscreature then
                inst.components.amphibiouscreature:OnEnterOcean()
                inst:AddTag("insomniac")
                inst.DynamicShadow:Enable(false)
            elseif inst.components.amphibiouscreature then
                inst.components.amphibiouscreature:OnExitOcean()
                inst:RemoveTag("insomniac")
                inst:RemoveTag("jump_swim")
                ClearFloaters(inst)
                inst.DynamicShadow:Enable(true)
            end
            inst.AnimState:PlayAnimation("boat_jump_pst", false)
            inst.sg:SetTimeout(4 * FRAMES)
        end,

        timeline =
        {
            GLOBAL.TimeEvent(5 * FRAMES, function(inst)
                if inst:HasTag("swimming") and GLOBAL.TheWorld.ismastersim then
                    SpawnFX(inst,"splash_green")
                    inst:PushEvent("addRippleFx")
                end
            end),
        },

        ontimeout = function(inst)
            inst.sg.statemem.timeout = true
        end,
        
        events =
        {
            GLOBAL.EventHandler("animover", function(inst)
                if inst.AnimState:AnimDone() then
                    inst.sg:GoToState("hop_pst_complete")
                end
            end),
        },
        onexit = function(inst)

        end,
    }
    return state
end

-- Server
AddStategraphPostInit("wilson", function(sg)
    WurtStates(sg)
end)

AddStategraphState("wilson",WurtPreHop())

AddStategraphState("wilson",WurtPostHop())

-- Client
AddStategraphPostInit("wilson_client", function(sg)
    WurtStates(sg)
end)

AddStategraphState("wilson_client",WurtPreHop())

AddStategraphState("wilson_client",WurtPostHop())