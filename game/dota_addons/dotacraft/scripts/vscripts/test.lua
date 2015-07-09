function TargetTest( event )
	local EventName = event.EventName
	local Damage = event.Damage

	local caster = event.caster
	local target = event.target
	local unit = event.unit
	local attacker = event.attacker
	local ability = event.ability

	local target_points = event.target_points
	local target_entities = event.target_entities

	print("**"..EventName.."**")
	print("~~~")
	if caster then print("CASTER: "..caster:GetUnitName()) end
	if target then print("TARGET: "..target:GetUnitName()) end
	if unit then print("UNIT: "..unit:GetUnitName()) end
	if attacker then print("ATTACKER: "..attacker:GetUnitName()) end
	if Damage then print("DAMAGE: "..Damage) end

	if target_points then
		for k,v in pairs(target_points) do
			print("POINT",k,v)
		end
	end

	-- Multiple Targets
	if target_entities then
		for k,v in pairs(target_entities) do
			print("TARGET "..k..": "..v:GetUnitName())
		end
	end

	--DeepPrintTable(event)
	print("~~~")
end

function BaseClassTest( event )
	local target = event.target

	local BaseClass = target:GetName()
	local GetUnitName = target:GetUnitName()

	print("BaseClass "..BaseClass)
	print("UnitName: "..GetUnitName)

	local BoundingRadius2D = target:BoundingRadius2D()
	local CollisionPadding = target:GetCollisionPadding()
	local PaddedCollisionRadius = target:GetPaddedCollisionRadius()
	local HullRadius = target:GetHullRadius()

	print("HullRadius:            "..HullRadius)
	print("BoundingRadius2D:      "..BoundingRadius2D)
	print("CollisionPadding:      "..CollisionPadding)
	print("PaddedCollisionRadius: "..PaddedCollisionRadius)

	--<Myll> GetPaddedCollisionRadius() is the exact area around a unit that other units will avoid when pathing around the unit
	--<Myll> GetHullRadius is always less than GetPaddedCollisionRadius()

	local IsAttackImmune = target:IsAttackImmune()
	print("Is AttackImmune",IsAttackImmune)
	local IsControllableByAnyPlayer = target:IsControllableByAnyPlayer()
	print("Is ControllableByAnyPlayer",IsControllableByAnyPlayer)
	local IsCreature = target:IsCreature()
	print("Is Creature",IsCreature)
	local IsMechanical = target:IsMechanical()
	print("Is Mechanical",IsMechanical)
	local IsMagicImmune = target:IsMagicImmune() -- State MODIFIER_STATE_MAGIC_IMMUNE
	print("Is MagicImmune",IsMagicImmune)
	local IsLowAttackPriority = target:IsLowAttackPriority() -- State MODIFIER_STATE_LOW_ATTACK_PRIORITY
	print("Is LowAttackPriority",IsLowAttackPriority)
	local IsInvulnerable = target:IsInvulnerable() -- State MODIFIER_STATE_INVULNERABLE
	print("Is Invulnerable",IsInvulnerable)
	local IsInvisible = target:IsInvisible() -- State MODIFIER_STATE_INVISIBLE
	print("Is Invisible",IsInvisible)
	local IsMuted = target:IsMuted() -- State MODIFIER_STATE_MUTED
	print("Is Muted",IsMuted)
	local IsOutOfGame = target:IsOutOfGame() -- State MODIFIER_STATE_OUT_OF_GAME
	print("Is OutOfGame",IsOutOfGame)
	local NoUnitCollision = target:NoUnitCollision() -- State MODIFIER_STATE_NO_UNIT_COLLISION
	print("No UnitCollision",NoUnitCollision)
	local PassivesDisabled = target:PassivesDisabled() -- State MODIFIER_STATE_PASSIVES_DISABLED
	print("Passives Disabled",PassivesDisabled)

	local GetInvulnCount = target.GetInvulnCount
	if GetInvnCount then 
		print("Is a Building") 
	end

	--[[DOTA_NPC_UNIT_RELATIONSHIP_TYPE_BARRACKS
	DOTA_NPC_UNIT_RELATIONSHIP_TYPE_BUILDING
	DOTA_NPC_UNIT_RELATIONSHIP_TYPE_COURIER
	DOTA_NPC_UNIT_RELATIONSHIP_TYPE_DEFAULT
	DOTA_NPC_UNIT_RELATIONSHIP_TYPE_HERO
	DOTA_NPC_UNIT_RELATIONSHIP_TYPE_SIEGE
	DOTA_NPC_UNIT_RELATIONSHIP_TYPE_WARD]]

	-- Discarded checks because they don't depend on the base class
	--local GetUnitLabel = target:GetUnitLabel() == KeyValue: "UnitLabel"	"healing_ward"
	--local HasInventory = target:HasInventory() == KeyValue: "HasInventory"				"1"
	--local IsAncient = target:IsAncient()  === KeyValue: "IsAncient"	"1"
	--local IsNeutralUnitType = target:IsNeutralUnitType() == KeyValue: "IsNeutralUnitType"			"1"
	--local UnitCanRespawn = target:UnitCanRespawn() == KeyValue: "CanRespawn"	"0" inside a Creature block
	
	-- "AttackCapabilities"		"DOTA_UNIT_CAP_NO_ATTACK"
	--local HasAttackCapability = target:HasAttackCapability() 
	--local AttackCapability = target:GetAttackCapability() 
	-- 0 is NO_ATTACK, 1 is MELEE, 2 is RANGED
	
	-- "MovementCapabilities"		"DOTA_UNIT_CAP_MOVE_GROUND", 
	--local HasMovementCapability = target:HasMovementCapability()
	--local HasGroundMovementCapability = target:HasGroundMovementCapability()
	--local HasFlyMovementCapability = target:HasFlyMovementCapability()
	-- 0 is MOVE_NONE, 1 is _GROUND, 2 is _FLY

	local HasFlyingVision = target:HasFlyingVision() --Does Applying FLY state on a GROUND unit makes it give flying vision?
	

end