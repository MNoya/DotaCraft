var Root = $.GetContextPanel();

Root.UpdatePanel = function(unit, abilityIndex, inLearnMode){
	//$.Msg("ability #"+Root.abilityIndex+" is updating");

	var newAbility = Entities.GetAbility(unit, abilityIndex);
	
	if ( Root.ability !== newAbility || Root.unit !== unit ){
		Root.unit = unit;
		Root.abilityIndex = abilityIndex; 
		Root.ability = newAbility
		Root.inLevelUp = inLearnMode;
		
		var canUpgradeRet = Abilities.CanAbilityBeUpgraded( Root.ability );
		var canUpgrade = ( canUpgradeRet == AbilityLearnResult_t.ABILITY_CAN_BE_UPGRADED );
		
		$.GetContextPanel().SetHasClass( "no_ability", ( Root.ability == -1 ) );
		$.GetContextPanel().SetHasClass( "learnable_ability", Root.inLevelUp && canUpgrade );

		RebuildAbilityUI();
		UpdateAbility();
	}
}

function UpdateAbility(){	
	if( Abilities.IsDisplayedAbility(Root.ability) ){ // valid ability to display
		Root.visible = true;
		
		var abilityButton = $( "#AbilityButton" );
		var abilityName = Abilities.GetAbilityName( Root.ability );

		var noLevel =( 0 == Abilities.GetLevel( Root.ability  ) );
		var isCastable = !Abilities.IsPassive( Root.ability  ) && !noLevel;
		var manaCost = Abilities.GetManaCost(Root.ability  );
		var hotkey = Abilities.GetKeybind( Root.ability , Root.unit );
		var unitMana = Entities.GetMana( Root.unit );

		$.GetContextPanel().SetHasClass( "no_level", noLevel );
		$.GetContextPanel().SetHasClass( "is_passive", Abilities.IsPassive(Root.ability ) );
		$.GetContextPanel().SetHasClass( "no_mana_cost", ( 0 == manaCost ) );
		$.GetContextPanel().SetHasClass( "insufficient_mana", ( manaCost > unitMana ) );
		$.GetContextPanel().SetHasClass( "auto_cast_enabled", Abilities.GetAutoCastState(Root.ability ) );
		$.GetContextPanel().SetHasClass( "toggle_enabled", Abilities.GetToggleState(Root.ability ) );
		$.GetContextPanel().SetHasClass( "is_active", ( Root.ability  == Abilities.GetLocalPlayerActiveAbility() ) );

		abilityButton.enabled = ( isCastable || Root.inLevelUp );
		
		$( "#HotkeyText" ).text = hotkey;
		
		$( "#AbilityImage" ).abilityname = abilityName;
		$( "#AbilityImage" ).contextEntityIndex = Root.ability ;
		
		$( "#ManaCost" ).text = manaCost;
		
		if ( Abilities.IsCooldownReady( Root.ability  ) )
		{
			$.GetContextPanel().SetHasClass( "cooldown_ready", true );
			$.GetContextPanel().SetHasClass( "in_cooldown", false );
		}
		else
		{
			$.GetContextPanel().SetHasClass( "cooldown_ready", false );
			$.GetContextPanel().SetHasClass( "in_cooldown", true );
			var cooldownLength = Abilities.GetCooldownLength( Root.ability  );
			var cooldownRemaining = Abilities.GetCooldownTimeRemaining( Root.ability  );
			var cooldownPercent = Math.ceil( 100 * cooldownRemaining / cooldownLength );
			$( "#CooldownTimer" ).text = Math.ceil( cooldownRemaining );
			$( "#CooldownOverlay" ).style.width = cooldownPercent+"%";
		}
			
	}else // hidden ability
		Root.visible = false;	
};

function Update(){
	if( Root.unit != null && Root.ability != null )
		UpdateAbility();
	
	$.Schedule( 0.1, Update);
};

function AbilityShowTooltip()
{
	var abilityButton = $( "#AbilityButton" );
	var abilityName = Abilities.GetAbilityName( Root.ability );
	// If you don't have an entity, you can still show a tooltip that doesn't account for the entity
	//$.DispatchEvent( "DOTAShowAbilityTooltip", abilityButton, abilityName );
	
	// If you have an entity index, this will let the tooltip show the correct level / upgrade information
	$.DispatchEvent( "DOTAShowAbilityTooltipForEntityIndex", abilityButton, abilityName, Root.unit );
}

function AbilityHideTooltip()
{
	var abilityButton = $( "#AbilityButton" );
	$.DispatchEvent( "DOTAHideAbilityTooltip", abilityButton );
}

function ActivateAbility()
{
	if ( Root.inLevelUp )
	{
		Abilities.AttemptToUpgrade( Root.ability );
		return;
	}
	Abilities.ExecuteAbility( Root.ability, Root.unit, false );
}

function DoubleClickAbility()
{
	// Handle double-click like a normal click - ExecuteAbility will either double-tap (self cast) or normal toggle as appropriate
	ActivateAbility();
}

function RightClickAbility()
{
	if( Root.inLevelUp )
		return;

	if ( Abilities.IsAutocast( Root.ability ) )
	{
		Game.PrepareUnitOrders( { OrderType: dotaunitorder_t.DOTA_UNIT_ORDER_CAST_TOGGLE_AUTO, AbilityIndex: Root.ability } );
	}
}

function RebuildAbilityUI()
{
	var abilityLevelContainer = $( "#AbilityLevelContainer" );
	abilityLevelContainer.RemoveAndDeleteChildren();
	var currentLevel = Abilities.GetLevel( Root.ability );
	for ( var lvl = 0; lvl < Abilities.GetMaxLevel( Root.ability  ); lvl++ )
	{
		var levelPanel = $.CreatePanel( "Panel", abilityLevelContainer, "" );
		levelPanel.AddClass( "LevelPanel" );
		levelPanel.SetHasClass( "active_level", ( lvl < currentLevel ) );
		levelPanel.SetHasClass( "next_level", ( lvl == currentLevel ) );
	}
}

(function(){
	Update();
})()