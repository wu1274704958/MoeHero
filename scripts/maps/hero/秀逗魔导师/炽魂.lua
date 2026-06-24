local mt = ac.skill['炽魂']

mt{
	--初始等级
	level = 0,

	--技能图标
	art = [[ReplaceableTextures\CommandButtons\BTNFireBolt.blp]],

	--技能说明
	title = '炽魂',

	tip = [[
被动技能。每当秀逗魔导师释放技能时，提升自身%attack_speed%点攻击速度和%move_speed_rate%%移动速度。
效果可以叠加，最大叠加%max_stack%层。每次施放技能都会刷新持续时间。
当前层数：%current_stack%

持续时间：%duration%秒
	]],

	--被动
	passive = true,

	--攻击速度加成(每层)
	attack_speed = {40, 55, 70, 85},

	--移动速度加成%(每层)
	move_speed_rate = {5, 6, 7, 8},

	--最大叠加数
	max_stack = 3,

	--持续时间
	duration = 10,

	--当前层数(显示用)
	current_stack = function(self, hero)
		if self.fiery_buff then
			return self.fiery_buff.stack or 0
		end
		return 0
	end,

	--显示数字
	show_stack = 1,
}

function mt:on_add()
	local hero = self.owner
	local skill = self

	--监听技能施法出手事件
	self.trg = hero:event '技能-施法出手' (function(_, _, cast_skill)
		--不触发自身(被动技能)
		if not cast_skill then
			return
		end
		--忽略物品使用
		if cast_skill:get_type() == '物品' then
			return
		end
		--忽略自身
		if cast_skill.name == '炽魂' then
			return
		end
		--叠加炽魂效果
		skill:add_fiery_stack()
	end)
end

function mt:on_remove()
	if self.trg then
		self.trg:remove()
		self.trg = nil
	end
	if self.fiery_buff then
		self.fiery_buff:remove()
		self.fiery_buff = nil
	end
end

function mt:add_fiery_stack()
	local hero = self.owner
	local max_stack = self.max_stack
	local attack_speed = self.attack_speed
	local move_speed_rate = self.move_speed_rate
	local duration = self.duration

	if self.fiery_buff and not self.fiery_buff.removed then
		--已有buff，刷新时间并尝试叠加
		local buff = self.fiery_buff
		local old_stack = buff.stack

		if old_stack < max_stack then
			--增加一层
			buff.stack = old_stack + 1
			--增加属性
			hero:add('攻击速度', attack_speed)
			hero:add('移动速度%', move_speed_rate)
		end

		--刷新持续时间
		buff:set_remaining(duration)
	else
		--创建新buff
		self.fiery_buff = hero:add_buff '炽魂'
		{
			source = hero,
			time = duration,
			skill = self,
			stack = 1,
			attack_speed = attack_speed,
			move_speed_rate = move_speed_rate,
		}
	end

	--更新显示层数
	self:set_stack(self.fiery_buff and self.fiery_buff.stack or 0)
	self:fresh_tip()
end

--炽魂buff定义
local buff_mt = ac.buff['炽魂']

buff_mt.cover_type = 0
buff_mt.cover_max = 1

function buff_mt:on_add()
	--第一层属性加成
	self.target:add('攻击速度', self.attack_speed)
	self.target:add('移动速度%', self.move_speed_rate)
	--添加特效
	self.eff = self.target:add_effect('origin', [[Abilities\Spells\Other\ImmolationRed\ImmolationRedDamage.mdl]])
end

function buff_mt:on_remove()
	--移除所有层的属性加成
	local stack = self.stack or 1
	self.target:add('攻击速度', -self.attack_speed * stack)
	self.target:add('移动速度%', -self.move_speed_rate * stack)
	--移除特效
	if self.eff then
		self.eff:remove()
	end
	--清除技能引用
	if self.skill then
		self.skill.fiery_buff = nil
		self.skill:set_stack(0)
		self.skill:fresh_tip()
	end
end
