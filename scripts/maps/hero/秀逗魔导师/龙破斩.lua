local mt = ac.skill['龙破斩']

mt{
	--初始等级
	level = 0,

	--技能图标
	art = [[ReplaceableTextures\CommandButtons\BTNBreathOfFire.blp]],

	--技能说明
	title = '龙破斩',

	tip = [[
释放一道火焰，对一条直线上的敌方单位造成%damage%点伤害。
	]],

	--施法距离
	range = 600,

	--耗蓝
	cost = {100, 115, 130, 145},

	--冷却
	cool = 8.5,

	--施法前摇
	cast_start_time = 0.45,

	--目标类型
	target_type = ac.skill.TARGET_TYPE_POINT,

	--最大飞行距离
	distance = 1225,

	--碰撞半径(火焰宽度)
	hit_area = 275,

	--弹道速度
	speed = 1200,

	--伤害
	damage = {110, 180, 250, 320},

	--施法动画
	cast_animation = 'spell',
}

function mt:on_cast_shot()
	local hero = self.owner
	local target = self.target
	local angle = hero:get_point() / target
	local damage = self.damage

	--创建火焰弹道
	local mvr = ac.mover.line
	{
		source = hero,
		model = [[Abilities\Spells\Other\BreathOfFire\BreathOfFireMissile.mdl]],
		angle = angle,
		distance = self.distance,
		speed = self.speed,
		skill = self,
		hit_area = self.hit_area,
		hit_type = ac.mover.HIT_TYPE_ENEMY,
		size = 1.5,
	}

	if not mvr then
		return
	end

	function mvr:on_hit(dest)
		dest:damage
		{
			source = hero,
			damage = damage,
			skill = self.skill,
			aoe = true,
		}
		dest:add_effect('chest', [[Abilities\Spells\Other\BreathOfFire\BreathOfFireDamage.mdl]]):remove()
	end
end
