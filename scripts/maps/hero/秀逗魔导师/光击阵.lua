local mt = ac.skill['光击阵']

mt{
	--初始等级
	level = 0,

	--技能图标
	art = [[ReplaceableTextures\CommandButtons\BTNWallOfFire.blp]],

	--技能说明
	title = '光击阵',

	tip = [[
召唤一道火柱对区域内的目标造成%damage%点伤害，并晕眩%stun_time%秒。
法术延迟0.5秒。
	]],

	--施法距离
	range = 600,

	--耗蓝
	cost = {100, 110, 120, 130},

	--冷却
	cool = 7,

	--施法前摇
	cast_start_time = 0.45,

	--目标类型
	target_type = ac.skill.TARGET_TYPE_POINT,

	--作用范围
	area = 225,

	--伤害
	damage = {80, 120, 160, 200},

	--晕眩时间
	stun_time = {1.6, 1.9, 2.2, 2.5},

	--延迟时间(毫秒)
	delay = 500,

	--施法动画
	cast_animation = 'spell',
}

function mt:on_cast_shot()
	local hero = self.owner
	local target = self.target
	local area = self.area
	local damage = self.damage
	local stun_time = self.stun_time
	local skill = self

	--延迟0.5秒后生效
	hero:wait(self.delay, function()
		--在目标地点创建特效
		target:add_effect([[Abilities\Spells\Human\Resurrection\ResurrectTarget.mdl]]):remove()
		target:add_effect([[Abilities\Spells\Human\Thunderclap\ThunderClapCaster.mdl]]):remove()

		--搜寻区域内的敌方单位
		for _, u in ac.selector()
			: in_range(target, area)
			: is_enemy(hero)
			: ipairs()
		do
			--造成伤害
			u:damage
			{
				source = hero,
				damage = damage,
				skill = skill,
				aoe = true,
			}

			--施加晕眩
			u:add_buff '晕眩'
			{
				source = hero,
				skill = skill,
				time = stun_time,
			}
		end
	end)
end
