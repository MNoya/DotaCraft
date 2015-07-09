-- This will put a set of predefined undroppable items on the casters inventory
function GiveHumanBuildingItems( event )
	local caster = event.caster
	local owner = caster:GetOwner()

	-- Ordered by most used
	local itemNames = { "item_build_farm",
						"item_build_altar_of_kings",
						"item_build_town_hall",	
						"item_build_scout_tower",					
						"item_build_arcane_vault",						
						"item_build_lumber_mill"
					  }

	-- Add each item in order
	for i=1,#itemNames do
		local item = CreateItem(itemNames[i], owner, caster)
		caster:AddItem(item)
	end
end