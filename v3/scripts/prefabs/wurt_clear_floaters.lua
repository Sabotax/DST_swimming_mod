local function ClearFloaters(inst)
	if inst.floater1 or inst.floater2 then
		inst.floater1:Hide()
		inst.floater2:Hide()
		inst.AnimState:ShowSymbol("leg") 
		inst.AnimState:ShowSymbol("foot")
		inst.AnimState:ShowSymbol("tail")
	end
end
return ClearFloaters