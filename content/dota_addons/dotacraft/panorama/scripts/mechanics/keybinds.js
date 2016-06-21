"use strict";

GameUI.Keybinds = {}

function WrapFunction(name)
{
    return function() { GameUI.Keybinds[name](); };
}

Game.AddCommand("+ToggleShop", WrapFunction("ToggleShop"), "", 0); //unit_shops.js
Game.AddCommand("+IdleBuilderSwap", WrapFunction("IdleBuilderSwap"), "", 0); //idle_workers.js
Game.AddCommand("+SelectHeropanel1", WrapFunction("SelectHeropanel1"), "", 0); //hero_panels_unit.js
Game.AddCommand("+SelectHeropanel2", WrapFunction("SelectHeropanel2"), "", 0);
Game.AddCommand("+SelectHeropanel3", WrapFunction("SelectHeropanel3"), "", 0);
Game.AddCommand("+SelectCreateControlGroup1", WrapFunction("ControlGroup1"), "", 0); //control_group.js
Game.AddCommand("+SelectCreateControlGroup2", WrapFunction("ControlGroup2"), "", 0);
Game.AddCommand("+SelectCreateControlGroup3", WrapFunction("ControlGroup3"), "", 0);
Game.AddCommand("+SelectCreateControlGroup4", WrapFunction("ControlGroup4"), "", 0);
Game.AddCommand("+SelectCreateControlGroup5", WrapFunction("ControlGroup5"), "", 0);
Game.AddCommand("+SelectCreateControlGroup6", WrapFunction("ControlGroup6"), "", 0);
Game.AddCommand("+SelectCreateControlGroup7", WrapFunction("ControlGroup7"), "", 0);

Game.AddCommand("-ToggleShop", function() {}, "", 0);
Game.AddCommand("-IdleBuilderSwap", function() {}, "", 0);
Game.AddCommand("-SelectHeropanel1", function() {}, "", 0);
Game.AddCommand("-SelectHeropanel2", function() {}, "", 0);
Game.AddCommand("-SelectHeropanel3", function() {}, "", 0);
Game.AddCommand("-SelectCreateControlGroup1", function() {}, "", 0);
Game.AddCommand("-SelectCreateControlGroup2", function() {}, "", 0);
Game.AddCommand("-SelectCreateControlGroup3", function() {}, "", 0);
Game.AddCommand("-SelectCreateControlGroup4", function() {}, "", 0);
Game.AddCommand("-SelectCreateControlGroup5", function() {}, "", 0);
Game.AddCommand("-SelectCreateControlGroup6", function() {}, "", 0);
Game.AddCommand("-SelectCreateControlGroup7", function() {}, "", 0);

Game.AddCommand("+RotateLeft", WrapFunction("OnRotateLeft"), "", 0);
Game.AddCommand("+RotateRight", WrapFunction("OnRotateRight"), "", 0);
Game.AddCommand("-RotateLeft", WrapFunction("OnReleaseRotateLeft"), "", 0);
Game.AddCommand("-RotateRight", WrapFunction("OnReleaseRotateRight"), "", 0);