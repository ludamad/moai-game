import monster_define from require "statsystem"

monster_define {
  name: "Giant Rat"
  monster_kind: "animal"
  description: "A giant, aggressive vermin."
  appear_message: "A hostile large rat approaches!"
  defeat_message: "Blood splatters as the large rat is destroyed."

  radius: 5

  level: 1
  move_speed: 2
  hp: 10, hp_regen: 0.03
  power: 1, damage: 10
  delay: 1.00
}