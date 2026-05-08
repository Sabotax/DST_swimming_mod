local ClearFloaters = require "prefabs/wurt_clear_floaters"

return function(config)

    local swim_speed_multiplier_wurt = config.swim_speed_multiplier_wurt
    local swim_speed_multiplier_not_wurt = config.swim_speed_multiplier_not_wurt

    local function WurtSwimmer(inst)
        if inst._wurt_swimmer:value() and (inst._wurt_tryingswim:value() or inst:HasTag("swimming")) then
            if inst.components.drownable then
                inst.components.drownable.enabled = false
            end
            if not inst.components.amphibiouscreature then
                inst:AddComponent("amphibiouscreature")
                inst.components.amphibiouscreature:SetBanks("wilson", "wilson")
                inst.components.amphibiouscreature:SetEnterWaterFn(
                    function()
                        if inst.components.locomotor then
                            if inst.prefab == "wurt" then
                                print("Setting speed to Wurt",inst.prefab,swim_speed_multiplier_wurt)
                                inst.components.locomotor:SetExternalSpeedMultiplier(
                                    inst,
                                    "wurt_swim",
                                    swim_speed_multiplier_wurt
                                )
                            else 
                                print("Setting speed to not Wurt",inst.prefab,swim_speed_multiplier_not_wurt)
                                inst.components.locomotor:SetExternalSpeedMultiplier(
                                    inst,
                                    "wurt_swim",
                                    swim_speed_multiplier_not_wurt
                                )
                            end
                        end
                        if inst:HasTag("playerghost") then
                            ClearFloaters(inst)
                        end
                    end)
                inst.components.amphibiouscreature:SetExitWaterFn(
                    function()
                        if inst.components.locomotor then
                            inst.components.locomotor:RemoveExternalSpeedMultiplier(
                                inst,
                                "wurt_swim"
                            )
                        end
                        if inst:HasTag("playerghost") then
                            ClearFloaters(inst)
                        end
                    end)
            end
        else
            if inst.components.drownable and inst:HasTag("swimming") and inst:HasTag("jump_swim") then
                inst.components.drownable.enabled = true
            end
            if inst.components.amphibiouscreature then
                inst:RemoveComponent("amphibiouscreature")
            end
            ClearFloaters(inst)
            inst:RemoveTag("swimming")
            if inst.components.locomotor then
                inst.components.locomotor:RemoveExternalSpeedMultiplier(
                    inst,
                    "wurt_swim"
                )
            end
        end
    end

    return WurtSwimmer
end