local Areas = {
	StarterArea = {
		CharacterSpawnPositions = {
			Vector3.new(-42, 0, 76),
			Vector3.new(42, 0, 76),
			Vector3.new(0, 0, 48),
			Vector3.new(0, 0, 94),
		},
		Enemies = {
			{
				name = "Training Dummy",
				position = Vector3.new(0, 2, 108),
				health = 30,
			},
			{
				name = "Training Dummy",
				position = Vector3.new(-16, 2, 108),
				health = 30,
			},
			{
				name = "Training Dummy",
				position = Vector3.new(16, 2, 108),
				health = 30,
			},
		},
		EnemyRespawnSeconds = 8,
		AttackRange = 16,
		AttackCooldownSeconds = 0.8,
		BaseAttackDamage = 8,
		EnemyLoveReward = 5,
	},
}

return Areas
