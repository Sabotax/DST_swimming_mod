-- I'm not doing chinese translation, but if any one wants to push merge request with it I will be obliged to merge it.
-- I was following instructions from "Configs Extended" mod.
local function en_zh(en, zh)
    return locale ~= "zh" and locale ~= "zhr" and locale ~= "zht" and en or zh
end


name = "Swimming"
description = [[
Allows characters to swim, highly customizable.
            ]]
author = "ProrokDX"
version = "1.0.0"


api_version = 10

dst_compatible = true

dont_starve_compatible = false
reign_of_giants_compatible = false
shipwrecked_compatible = false

all_clients_require_mod = true 

icon_atlas = "modicon.xml"
icon = "modicon.tex"

server_filter_tags = {
"swimming"
}


local Keys = {
    {description = "T", data = 116},
    {description = "Y", data = 121},
    {description = "U", data = 117},
    {description = "P", data = 112},
    {description = "G", data = 103},
    {description = "H", data = 104},
    {description = "J", data = 106},
    {description = "K", data = 107},
    {description = "L", data = 108},
    {description = "Z", data = 122},
    {description = "X", data = 120},
    {description = "C", data = 99},
    {description = "V", data = 118},
    {description = "B", data = 98},
    {description = "N", data = 110},
    {description = "M", data = 109},
}

local en_configuration_options = {
	{
		name = "enable_swim_keybind",
		label = "Key for swimmming mode",
		options = Keys,
		default = 120,
		hover = "Select keybind for swimming mode.",
		is_keybind = true
	},
    {
        name = "swim_only_for_wurt",
        label = "Only Wurt can swim",
        options = {
            {description = "Yes", data = true},
            {description = "No", data = false},
        },
        default = false,
        hover = "Decide if only Wurt can swim or everyone can swim. Wx gets his own setting in case everyone can swim."
    },
    {
        name = "swim_blocked_for_wx78",
        label = "Allow WX-78 to swim",
        options = {
            {description = "Yes", data = false},
            {description = "No", data = true},
        },
        default = true,
        hover = "Allows WX-78 to swim (even tho he won't last long). 'Only Wurt can swim' setting has bigger priority."
    },
    {
        name = "swim_speed_multiplier_wurt",
        label = "Swim speed Wurt",
        options = {
            {description = "0.1", data = 0.1},
            {description = "0.25", data = 0.25},
            {description = "0.5", data = 0.5},
            {description = "0.75", data = 0.75},
            {description = "1.0", data = 1.0},
        },
        default = 0.5,
        hover = "Swim speed multiplier for Wurt"
    },
    {
        name = "swim_speed_multiplier_not_wurt",
        label = "Swim speed not Wurt",
        options = {
            {description = "0.1", data = 0.1},
            {description = "0.25", data = 0.25},
            {description = "0.5", data = 0.5},
            {description = "0.75", data = 0.75},
            {description = "1.0", data = 1.0},
        },
        default = 0.25,
        hover = "Swim speed multiplier for everyone except Wurt"
    },
    {
        name = "drop_handitem_wurt",
        label = "Wurt item drop",
        options = {
            {description = "Yes", data = true},
            {description = "No", data = false},
        },
        default = false,
        hover = "Does Wurt drop equipped item in hand while swimming"
    },
    {
        name = "drop_handitem_not_wurt",
        label = "Not Wurt item drop",
        options = {
            {description = "Yes", data = true},
            {description = "No", data = false},
        },
        default = true,
        hover = "Does everyone except Wurt drop equipped item in hand while swimming"
    }
}
configuration_options = en_configuration_options