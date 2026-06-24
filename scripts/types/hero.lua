
local jass = require 'jass.common'
local japi = require 'jass.japi'
local dbg = require 'jass.debug'
local unit = require 'types.unit'
local player = require 'ac.player'
local damage = require 'types.damage'
local slk = require 'jass.slk'
local math = math

local hero = {}
setmetatable(hero, hero)

--结构
local mt = {}
hero.__index = mt

--hero继承unit
setmetatable(mt, unit)

--类型
mt.unit_type = '英雄'

--当前经验值
mt.xp = 0

--下句英雄回应的最早时间
mt.response_idle_time = -99999

--复活英雄
function mt:revive(where)
	if self:is_alive() then
		return
	end
	if not where then
		where = self:getBornPoint()
	end
	local origin = self:get_point()
	--print('正在复活', self:get_name())
	jass.ReviveHero(self.handle, where:get_point():get())
	self:set('生命', self:get '生命上限')
	self._is_alive = true
	self:get_owner():selectUnit(self)
	if self.wait_to_transform_id then
		local target = self.wait_to_transform_id
		self.wait_to_transform_id = nil
		self:transform(target)
	end
	for it in self:each_skill '物品' do
		if it._wait_fresh_item then
			it._wait_fresh_item = nil
			it:fresh_item()
		end
	end
	self:event_notify('单位-复活', self)
	self:event_notify('单位-传送完成', self, origin, where)
end

--获得经验值
function mt:addXp(xp)
	jass.SetHeroXP(self.handle, jass.GetHeroXP(self.handle) + xp, true);
	self.xp = jass.GetHeroXP(self.handle);
end

-- 变身
local dummy
function mt:transform(target_id)
	if not self:is_alive() then
		--死亡状态无法变身
		self.wait_to_transform_id = target_id
		return
	end

	--获取攻击间隔
	local attack_cool = self:get '攻击间隔'
	if not dummy then
		dummy = ac.dummy
		dummy:add_ability 'AEme'
	end
	--变身
	japi.EXSetAbilityDataInteger(japi.EXGetUnitAbility(dummy.handle, base.string2id 'AEme'), 1, 117, base.string2id(self:get_type_id()))
	self:add_ability 'AEme'
	japi.EXSetAbilityAEmeDataA(japi.EXGetUnitAbility(self.handle, base.string2id 'AEme'), base.string2id(target_id))
	self:remove_ability 'AEme'

	--修改ID
	self.id = target_id

	--恢复攻击距离
	self.default_attack_range = nil
	self:add('攻击范围', 0)

	--恢复攻击力
	self:add('攻击', 0)

	--恢复移动速度
	self:add('移动速度', 0)

	--恢复攻击间隔
	self:add('攻击间隔', 0)

	--可以飞行
	self:add_ability 'Arav'
	self:remove_ability 'Arav'
	self:set_high(self:get_high())

	--动画混合时间
	jass.SetUnitBlendTime(self.handle, self:get_slk('blend', 0))

    -- 恢复特效
    if self._effect_list then
        for _, eff in ipairs(self._effect_list) do
            if eff.handle then
                jass.DestroyEffect(eff.handle)
                dbg.handle_unref(eff.handle)
                eff.handle = jass.AddSpecialEffectTarget(eff.model, self.handle, eff.socket or 'origin')
                dbg.handle_ref(eff.handle)
            end
        end
    end
end

--获得属性
function mt:getStr()
	return jass.GetHeroStr(self.handle, true)
end

function mt:getAgi()
	return jass.GetHeroAgi(self.handle, true)
end

function mt:getInt(self)
	return jass.GetHeroInt(self.handle, true)
end

--设置属性
function mt:setStr(n)
	jass.SetHeroStr(self.handle, n, true)
end

function mt:setAgi(n)
	jass.SetHeroAgi(self.handle, n, true)
end

function mt:setInt(n)
	jass.SetHeroInt(self.handle, n, true)
end

--创建单位
--	id:单位id(字符串)
--	where:创建位置(type:point;type:circle;type:rect;type:unit)
--	face:面向角度
function player.__index.createHero(p, name, where, face)
	local hero_data = hero.hero_list[name].data
	local u = p:create_unit(hero_data.id, where, face)
	setmetatable(u, hero_data)

	u:add_ability 'AInv'
	u.hero_data = hero_data

	for k, v in pairs(hero_data.attribute) do
		u:set(k, v)
	end
	return u
end

function hero.create(name)
	return function(data)
		hero.hero_datas[name] = data
		--继承英雄属性
		setmetatable(data, hero)
		data.__index = data

        function data:__tostring()
            local player = self:get_owner()
            return ('%s|%s|%s'):format('hero', self:get_name(), player.base_name)
        end
		
		--注册技能
		data.skill_datas = {}
		if type(data.skill_names) == 'string' then
			for name in data.skill_names:gmatch '%S+' do
				table.insert(data.skill_datas, ac.skill[name])
			end
		elseif type(data.skill_names) == 'table' then
			for _, name in ipairs(data.skill_names) do
				table.insert(data.skill_datas, ac.skill[name])
			end
		end
		return data
	end
end

function hero.getAllHeros()
	return hero.all_heros
end

function hero.registerJassTriggers()
	--英雄升级事件
	local j_trg = war3.CreateTrigger(function()
		local hero = unit.j_unit(jass.GetTriggerUnit())
		local new_lv = jass.GetHeroLevel(hero.handle)
		local old_lv = hero.level
		for i = hero.level + 1, new_lv do
			hero.level = i
			hero:event_notify('单位-英雄升级', hero)
		end

	end)
	for i = 1, 12 do
		jass.TriggerRegisterPlayerUnitEvent(j_trg, player[i].handle, jass.EVENT_PLAYER_HERO_LEVEL, nil)
	end
end

--刷新伤害属性信息
function mt:freshDamageInfo()
	local atk = self:get '攻击'
	local pene, pener = self:get '破甲', self:get '穿透'
	local crit, critr = self:get '暴击', self:get '暴击伤害'
	local crit_up = crit * (critr/100 - 1) / 100 + 1
	local damage = atk * crit_up * (self:getDamageRate() / 100.0) * 60
	self:setStr(damage)
	return damage
end

--刷新坚韧属性信息
function mt:freshDefenceInfo()
	local life = self:get '生命上限'
	local def = self:get '护甲'
	local damaged_rate = self:getDamagedRate()
	local block_chance, block_rate = self:get '格挡', self:get '格挡伤害'
	if block_chance > 100 then block_chance = 100 end
	if block_rate > 100 then block_rate = 100 end
	local def_up = 1
	if def > 0 then
		def_up = 1 + def * damage.DEF_SUB
	else
		def_up = 1 / (1 - def * damage.DEF_ADD)
	end
	local block_up = 1 / (1.0 - block_chance * block_rate / 10000.0)
	local defence = life * def_up * block_up
	if damaged_rate > 5 then
		defence = defence * 100.0 / damaged_rate
	end
	self:setAgi(defence)
	return defence
end

--刷新移动速度信息
function mt:freshMoveSpeedInfo()
	self:setInt(math.max(0, self:get('移动速度')))
end

function hero.init()
	--注册英雄
	hero.hero_datas = {}
	
	hero.registerJassTriggers()

	--记录英雄
	local heros = {}
	hero.all_heros = heros
	ac.game:event '玩家-注册英雄' (function(_, _, hero)
		heros[hero] = true
		local resource = ac.resource[hero.resource_type]
		if not resource then
			hero:set('魔法', hero:get '魔法上限')
			return
		end
		if resource.on_add then
			resource.on_add(hero)
		end
		if resource.reborn_type == 0 then
			hero:set('魔法', 0)
			hero:event '单位-复活' (function ()
				hero:set('魔法', 0)
			end)
		elseif resource.reborn_type == 1 then
			hero:set('魔法', hero:get '魔法上限')
			local mana = 0
			hero:event '单位-死亡' (function ()
				mana = hero:get('魔法')
			end)
			hero:event '单位-复活' (function ()
				hero:set('魔法', mana)
			end)
		elseif resource.reborn_type == 2 then
			hero:set('魔法', hero:get '魔法上限')
			hero:event '单位-复活' (function ()
				hero:set('魔法', hero:get '魔法上限')
			end)
		end
		hero:loop(100, function()
			hero:updateActive()
		end)
	end)
end

--修改英雄技能点数
function mt:addSkillPoint(points)
	self.skill_points = self.skill_points + points
	local skl = self:find_skill('技能升级', nil, true)
	if not skl then
		return
	end
	skl:call_updateSkillPoint()
end


function mt:circle(n, threshold)
    threshold = threshold or 20  -- WAR3 单位移动的合理误差阈值

    if not self:is_alive() then
        return
    end

    if self._is_circling then
        self:stop_circle()
    end

    -- 圆心
    local center = self:get_point()

    -- 预计算 24 个圆上的点, 也可参数传入（如果需要）
    local point_count = 24
    local points = {}
    for i = 0, point_count - 1 do
        local angle = i * (360 / point_count)
		local p = ac.point(math.cos(angle) * n,math.sin(angle) * n)
		print('i',i,'angle', angle, 'point', p)
        table.insert(points, center + p)
    end

    -- 血量配置
    local init_hp = self:get('生命')
    local target_hp = init_hp * 0.5
    local total_damage = init_hp - target_hp
    local damage_per_point = total_damage / point_count  -- 每点到扣一次

    -- 状态初始化
    self._is_circling = true
    self._circle_points = points
    self._circle_threshold = threshold
    self._circle_target_hp = target_hp
    self._circle_damage_per_point = damage_per_point
    self._circle_cur_idx = 0          -- 当前目标点索引（0~23）
    self._circle_same_point_frame = 0 -- 同一个点的停留帧数（防卡死）
    self._circle_max_frame_per_point = math.ceil(20000 / 30) -- 单点最多等 2 秒
	self._circle_real_idx = 0

    -- 先发第一个点的移动命令
    local first_pt = points[1] -- Lua 数组从 1 开始，对应上面的 0 号点
    jass.IssuePointOrder(self.handle, "move", first_pt:get())

    -- 30ms 固定帧率检测
    self._circle_timer = ac.loop(30, function(timer)
        if not self:is_alive() or not self._is_circling then
            timer:remove()
            self:_clear_circle_state()
            return
        end

        -- 当前目标点（Lua 数组索引 = 原索引 + 1）
        local cur_pt = self._circle_points[self._circle_cur_idx + 1]
        if not cur_pt then
            timer:remove()
            self:_clear_circle_state()
            return
        end

		local dist = cur_pt:distance(self)
		print('当前点索引', self._circle_cur_idx, '距离', dist .. ',self pos ' .. tostring(self:get_point()) .. ',target pos ' .. tostring(cur_pt))

        -- 到达目标点判定
        if self._circle_real_idx <= point_count and dist <= self._circle_threshold then
			print('arrive target '..tostring(self._circle_cur_idx))
            -- 扣血（只在到达点时扣）
            local new_hp = self:get('生命') - self._circle_damage_per_point
            self:set('生命', math.max(self._circle_target_hp, new_hp))

            -- 切换到下一个点
            self._circle_cur_idx = self._circle_cur_idx + 1
            self._circle_same_point_frame = 0
			self._circle_real_idx = self._circle_real_idx + 1

            -- 走完 23 个点，回到第 0 个点
            if self._circle_cur_idx >= point_count then
                self._circle_cur_idx = 0 -- 回到第 0 个点
                local back_pt = self._circle_points[1]
                jass.IssuePointOrder(self.handle, "move", back_pt:get())
                return
            end

            -- 发下一个点的移动命令
            local next_pt = self._circle_points[self._circle_cur_idx + 1]
            jass.IssuePointOrder(self.handle, "move", next_pt:get())
			print('move to '..tostring(self._circle_cur_idx))

        else
            -- 没到点，累计停留帧数
            self._circle_same_point_frame = self._circle_same_point_frame + 1

            -- 防卡死：同一个点超过 一定时间没到，强行跳下一个
            if self._circle_same_point_frame >= self._circle_max_frame_per_point then
                self._circle_cur_idx = self._circle_cur_idx + 1
                self._circle_same_point_frame = 0

                -- 回到第 0 点的情况
                if self._circle_cur_idx >= point_count then
                    self._circle_cur_idx = 0
                    local back_pt = self._circle_points[1]
                    jass.IssuePointOrder(self.handle, "move", back_pt:get())
                    return
                end

                local next_pt = self._circle_points[self._circle_cur_idx + 1]
                jass.IssuePointOrder(self.handle, "move", next_pt:get())
            end
        end

        -- 完成闭环（回到第 0 点且到达）
        if self._circle_real_idx == point_count and self._circle_cur_idx == 0 and dist <= self._circle_threshold then
            timer:remove()
            self:_clear_circle_state()
            self:set('生命', self._circle_target_hp) -- 最终血量校准
            self:event_notify('单位-完成圆形移动', self, n, 30 * point_count * 2)
        end
    end)

    return self._circle_timer
end

-- 清理状态
function mt:_clear_circle_state()
    self._is_circling = false
    self._circle_points = nil
    self._circle_cur_idx = nil
    self._circle_same_point_frame = nil
    if self._circle_timer then
        self._circle_timer:remove()
        self._circle_timer = nil
    end
end

-- 主动停止
function mt:stop_circle()
    if self._is_circling then
        jass.IssueImmediateOrder(self.handle, "stop")
        self:_clear_circle_state()
    end
end

ac.hero = hero

return hero
