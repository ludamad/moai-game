import weapon_define from require "statsystem"

-- Piercing weapons
weapon_define {
    name: "Dagger"
    avatar_sprite: 'sw-dagger'
    description: "A small but sharp blade; great for stabbing ."
    category: "piercing"

    gold_worth: 15
    difficulty: 0
    effectiveness: 6
    damage: 8
    power: 1
    delay: 1
    cooldown: 0.75
}

weapon_define {
    name: "Short Sword"
    avatar_sprite: 'sw-dagger'
    description: "A small, light sword."
    category: "piercing"

    gold_worth: 35
    difficulty: 1
    effectiveness: 4
    damage: 6
    delay: 1.1
}

weapon_define {
    name: "Long Sword"
    avatar_sprite: 'sw-sword1'
    description: "A large trusty sword."
    category: "piercing"

    gold_worth: 80
    difficulty: 3
    effectiveness: 1
    damage: 10
    delay: 1.4
}

weapon_define {
    name: "Great Sword"
    avatar_sprite: 'sw-sword2'
    description: "An oversized brutish sword."
    category: "piercing"

    gold_worth: 120
    difficulty: 5
    effectiveness: -3
    damage: 16
    delay: 1.6
}

-- Slashing weapons
weapon_define {
    name: "Hand Axe"
    avatar_sprite: 'sw-hand-axe'
    description: "A light, small and sturdy axe."
    category: "slashing"

    gold_worth: 20
    difficulty: 0
    effectiveness: 3
    damage: 7
    delay: 1.3
}

-- Ranged weapons
weapon_define {
    name: "Short Bow"
    avatar_sprite: 'sw-blue-bow'
    description: "A small bow."
    category: "bow"

    gold_worth: 20
    difficulty: 0
    effectiveness: 5
    damage: 4
    delay: 1.0
}
