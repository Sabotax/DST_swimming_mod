local assets =
{
    Asset("ANIM", "anim/float_fx.zip"),
	Asset("ANIM", "anim/flotsam_heavy.zip"),
}

local prefabs =
{
}
local function common_fn(is_front)
    local inst = CreateEntity()

    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    inst.entity:AddNetwork()
    inst.entity:AddSoundEmitter()

    -- inst.persists = true

    inst:AddTag("NOBLOCK")
    inst:AddTag("FX")
    inst:AddTag("ignorewalkableplatforms")
    inst.AnimState:SetBuild("float_fx")
    inst.AnimState:SetOceanBlendParams(1)

    if is_front then
        inst.AnimState:SetBank("float_front")
        inst.AnimState:PlayAnimation("idle_front_small", true)
    else
        inst.AnimState:SetBank("float_back")
        inst.AnimState:SetLayer(LAYER_BACKGROUND)
        inst.AnimState:PlayAnimation("idle_back_small", true)
    end

    inst.entity:SetPristine()

    if not TheWorld.ismastersim then
        return inst
    end
       
    return inst
end

local function water_shadow()
	local inst = CreateEntity()

    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    inst.entity:AddNetwork()
    inst.entity:AddSoundEmitter()

    -- inst.persists = true

    inst:AddTag("NOBLOCK")
    inst:AddTag("FX")
    inst:AddTag("ignorewalkableplatforms")
	--local r, g, b = inst.AnimState:GetMultColour()
    inst.AnimState:SetOceanBlendParams(1)
	inst.entity:SetPristine()
	inst.Transform:SetScale(0.4, 0.4, 0.4)
	
	inst.AnimState:SetBank("flotsam_heavy")
    inst.AnimState:SetBuild("flotsam_heavy")
    inst.AnimState:PlayAnimation("idle", true)
    if not TheWorld.ismastersim then
        return inst
    end
       
    return inst
end

local function front_fn()
    return common_fn(true)
end

local function back_fn()
    return common_fn(false)
end

return Prefab("float_fx_front2", front_fn, assets, prefabs),
       Prefab("float_fx_back2", back_fn, assets, prefabs),
	   Prefab("float_fx_shadow", water_shadow, assets, prefabs)
