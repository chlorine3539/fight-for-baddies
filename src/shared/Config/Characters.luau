local Characters = {
	TalkReward = 3,
	TalkCooldownSeconds = 4,
	RespawnDelaySeconds = 15,
	Order = { "Mira", "Kaito", "Nyx" },
	ById = {
		Mira = {
			displayName = "Mira",
			rarity = "Common",
			requiredLove = 6,
			companionDamage = 2,
			color = Color3.fromRGB(238, 145, 176),
			dialogue = {
				"Hey! It's nice to meet you.",
				"You seem friendly. Come back and tell me about yourself.",
				"Maybe we could explore together sometime.",
			},
		},
		Kaito = {
			displayName = "Kaito",
			rarity = "Uncommon",
			requiredLove = 12,
			companionDamage = 4,
			color = Color3.fromRGB(100, 170, 230),
			dialogue = {
				"Got a minute? I know a few places worth exploring.",
				"Getting stronger takes practice. Keep at it.",
				"You're starting to grow on me.",
			},
		},
		Nyx = {
			displayName = "Nyx",
			rarity = "Rare",
			requiredLove = 18,
			companionDamage = 6,
			color = Color3.fromRGB(165, 135, 220),
			dialogue = {
				"Not many people make it this far. Interesting.",
				"Trust is earned, not given. Let's see what you're made of.",
				"Perhaps our paths should stay together.",
			},
		},
	},
}

return Characters
