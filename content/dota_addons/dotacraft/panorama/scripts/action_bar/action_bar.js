(function() {
    var SILENCE_NONE = 0,
        SILENCE_ABILITIES = 1,
        SILENCE_PASSIVES = 2,
        SILENCE_ALL = 3;

    var ItemDB = {
        587   : "default",
        10150 : "dire",
        10324 : "portal",
        10346 : "mana_pool"
    }
    
    var units = {};
    var currentUnit = -1;
    var abilities = {};
    var learnMode = false;
    var silenceState = SILENCE_NONE;

    /* Set actionpanel for a specified unit. */
    function SetActionPanel(unit) {
        var abilityContainer = $("#AbilityList");

        // Get rid of the old abilities first.
        for (var ab in abilities) {
            abilities[ab].style.visibility = "collapse";
        }

        //Set the new current unit
        currentUnit = unit;

        // Retrieve panels we made previously to avoid deletion or excessive panels.
        if (units[unit] !== undefined) {
            abilities = units[unit];
        }
        else {
            units[unit] = {};
            abilities = units[unit];
        }

        // Update abilities on the action bar (can be swapped on invoker/rubick).
        updateVisibleAbilities();

        // Can not enter a unit in learn mode
        learnMode = false;
        for (var ab in abilities) {
            abilities[ab].setLearnMode(learnMode);
        }

        // Set silence state only for allies
        if (!Entities.IsEnemy(unit)){
            silenceState = getSilenceState(unit);
            for (var ab in abilities) {
                abilities[ab].setSilenceState(silenceState);				
            }
        }
    }
	
	function RemoveAndAddLayout(panel, unit){
		var visibleAbilityCount = countAbilityLayout(unit);
		for(var i = 4; i <= 6; i++) // remove possible layouts
			panel.RemoveClass("ability_layout_"+i);		
		panel.RemoveClass("ability_layout_6_2");
		
		if( visibleAbilityCount > 6 )
			panel.AddClass("ability_layout_6_2");
		else if( visibleAbilityCount <= 6 && visibleAbilityCount >= 4) // determine neccesary layout
			panel.AddClass("ability_layout_"+ visibleAbilityCount);
		else
			panel.AddClass("ability_layout_4");		
	};

    /* Selection changed to a unit the player controls. */
    function onUpdateSelectedUnit(event) {
        var unit = Players.GetLocalPlayerPortraitUnit();
        SetActionPanel(unit);
    }

    /* Selection changed to a unit the player does not control. */
    function onUpdateQueryUnit(event) {
        var unit = Players.GetQueryUnit(Players.GetLocalPlayer());
        
        // Filter out invalid units (happens when switching back to the hero from a query unit.)
        // This also fires an update_selected_unit event so should be handled fine.
        if (unit != -1) {
            SetActionPanel(unit);
        }
    }

    function onStatsChanged(event) {
        //Ability points changed - reinit all abilities
        for (var ab in abilities) {
            abilities[ab].reinit();
        }

        //Update stats?
    }

    function onAbilityChanged(event) {
        updateVisibleAbilities();
    }

    function updateVisibleAbilities() {
        var abilityContainer = $("#AbilityList");

        //Hide all abilities
        for (var ab in abilities) {
            abilities[ab].style.visibility = "collapse";
        }

        //Show only the visible abilities
        var slot = 0;
		var createdAbilities = 0;
        var abilityCount = Entities.GetAbilityCount(currentUnit) - 1;
		
		var visibleAbilityCount = countAbilityLayout(currentUnit)
		if( visibleAbilityCount <= 6 )
			$("#AbilityTopRow").style["height"] = 100+"%";
		else
			$("#AbilityTopRow").style["height"] = 50+"%";
		
        while (slot < abilityCount) {
            // Get ability.
            var ability = Entities.GetAbility(currentUnit, slot);

            // Stop once an invalid ability is found (or just continue and ignore?)
            if (ability === -1) {
                break;
            }  
            if (!Abilities.IsAttributeBonus(ability) && !Abilities.IsHidden(ability)) {				
				var abilityContainerRow;
				if( createdAbilities < 6 )
					abilityContainerRow = $("#AbilityTopRow");
				else
					abilityContainerRow = $("#AbilityBottomRow");
				
                if (abilities[ability] !== undefined) {
                    abilities[ability].style.visibility = "visible";
                    
                    //Reinit the ability to check for changes
                    abilities[ability].reinit();
                } 
                else {
                    // Create new panel and load the layout
                    var abilityPanel = $.CreatePanel( "Panel", abilityContainerRow, "" );
                    abilityPanel.LoadLayoutAsync( "file://{resources}/layout/custom_game/action_bar_ability.xml", false, false );
                    
                    // Initialise the ability panel.
                    abilityPanel.init(ability, currentUnit);
					RemoveAndAddLayout(abilityPanel, abilityPanel.ownerUnit);
					
                    // Keep ability for later
                    abilities[ability] = abilityPanel;
                }

                if (slot > 0) {
                    var previousAbility = Entities.GetAbility(currentUnit, slot - 1);
                    if (abilities[previousAbility] !== undefined) {
                        abilityContainerRow.MoveChildAfter(abilities[ability], abilities[previousAbility]);
                    }
                }
				createdAbilities++;
            }
			
            slot++;
        }
    }

    /* Count the abilities to show up in the ability layout. */
    function countAbilityLayout(unit) {
        var count = 0;
        for (var slot = 0; slot < Entities.GetAbilityCount(currentUnit); slot++) {
            var ability = Entities.GetAbility(unit, slot);

            if (ability == -1) {
                break;
            }

             if (!Abilities.IsAttributeBonus(ability) && !Abilities.IsHidden(ability)) {
                count++;
             }
        }
        return count;
    }

    /* Get the silence state (abilities, passives or both) */
    function getSilenceState(unit) {
        var state = SILENCE_NONE;
        if (Entities.IsSilenced(unit) || Entities.IsHexed(unit)) state += SILENCE_ABILITIES;
        if (Entities.PassivesDisabled(unit)) state += SILENCE_PASSIVES;
        return state
    }

    /* Update loop */
    function onUpdate() {
        //Check if we are in ability learn mode
        if (Game.IsInAbilityLearnMode() !== learnMode) {
            learnMode = Game.IsInAbilityLearnMode();
            for (var ab in abilities) {
                abilities[ab].setLearnMode(learnMode);
            }
        }

        //Make ability state only visible to allies (this can be commented out to see enemy ability states!)
        if (!Entities.IsEnemy(currentUnit)) {
            //Check silence state
            var silenceS = getSilenceState(currentUnit);
            if (silenceS !== silenceState) {
                silenceState = silenceS;
                for (var ab in abilities) {
                    abilities[ab].setSilenceState(silenceState);
                }
            }

            // Update all abilities.
            for (var ab in abilities) {
                abilities[ab].update();
            }
        }

        $.Schedule(0.05, onUpdate);
    }

    // Bind query unit update event
    GameEvents.Subscribe("dota_player_update_selected_unit", onUpdateSelectedUnit);
    GameEvents.Subscribe("dota_player_update_query_unit", onUpdateQueryUnit);

    GameEvents.Subscribe("dota_portrait_unit_stats_changed", onStatsChanged);
    GameEvents.Subscribe("dota_ability_changed", onAbilityChanged);
    //Listen for hacky inventory updates

    //Set default unit
    var unit = Players.GetQueryUnit(Players.GetLocalPlayer());
    if (unit === -1 ) {
        unit = Players.GetLocalPlayerPortraitUnit();
    }
    SetActionPanel(unit);

    //Listen to dota_action_success to determine cast state
    onUpdate();

    //Listen for level up event - dota_ability_changed

    //Listen for casts (cooldown starts)
})();