require 'maps.hero.秀逗魔导师.龙破斩'
require 'maps.hero.秀逗魔导师.光击阵'
require 'maps.hero.秀逗魔导师.炽魂'
require 'maps.hero.秀逗魔导师.神灭斩'

return ac.hero.create '秀逗魔导师'
{
	--id
	id = 'H014',

	production = 'Dota',

	model_source = 'Dota',

	hero_designer = 'eqd',

	hero_scripter = 'eqd',

	show_animation = { 'spell', 'spell channel' },

	--技能数量
	skill_count = 4,

	skill_names = '龙破斩 光击阵 炽魂 神灭斩',

	attribute = {
		['生命上限'] = 750,
		['魔法上限'] = 700,
		['生命恢复'] = 2.5,
		['魔法恢复'] = 1.5,
		['魔法脱战恢复'] = 0,
		['攻击']    = 40,
		['护甲']    = 8,
		['移动速度'] = 295,
		['攻击间隔'] = 1.5,
		['攻击范围'] = 650,
	},

	upgrade = {
		['生命上限'] = 95,
		['魔法上限'] = 50,
		['生命恢复'] = 0.2,
		['魔法恢复'] = 0.12,
		['攻击']    = 3.2,
		['护甲']    = 1.0,
	},

	weapon = {
		['弹道模型'] = [[Abilities\Weapons\FireBallMissile\FireBallMissile.mdl]],
		['弹道速度'] = 1000,
		['弹道弧度'] = 0.1,
		['弹道出手'] = {15, 0, 80},
	},

	resource_type = '魔法',

	difficulty = 2,

	--选取半径
	selected_radius = 32,

	yuri = true,
}
