local mt = ac.skill['神灭斩']

mt{
	--初始等级
	level = 0,

	--最大等级
	max_level = 3,

	--需要的英雄等级
	requirement = {6, 11, 16},

	--技能图标
	art = [[ReplaceableTextures\CommandButtons\BTNMonsoon.blp]],

	--技能说明
	title = '神灭斩',

	tip = [[
向一个目标射出闪电，造成%damage%点致命伤害。
施法到伤害生效有0.25秒延迟。
	]],

	--施法距离
	range = 600,

	--耗蓝
	cost = {280, 420, 680},

	--冷却
	cool = {70, 60, 50},

	--施法前摇
	cast_start_time = 0.45,

	--目标类型
	target_type = ac.skill.TARGET_TYPE_UNIT,

	--伤害
	damage = {450, 650, 850},

	--延迟时间(毫秒)
	delay = 250,

	--施法动画
	cast_animation = 'spell',
}

function mt:on_cast_shot()
	local hero = self.owner
	local target = self.target
	local damage = self.damage
	local skill = self

	--创建闪电链特效(从施法者到目标)
	local ln = ac.lightning('CLPB', hero, target, 0, 0)

	--延迟0.25秒后造成伤害
	hero:wait(self.delay, function()
		--移除闪电特效
		if ln then
			ln:remove()
		end

		--检查目标是否仍然存活且有效
		if not target:is_alive() then
			return
		end

		--创建命中特效
		target:add_effect('origin', [[Abilities\Spells\Other\Monsoon\MonsoonBoltTarget.mdl]]):remove()
		target:add_effect('chest', [[Abilities\Spells\Human\Thunderclap\ThunderClapCaster.mdl]]):remove()

		--造成伤害
		target:damage
		{
			source = hero,
			damage = damage,
			skill = skill,
		}
	end)
end
