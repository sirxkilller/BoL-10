if GetMyHero().charName ~= "Veigar" then
return
end

local version = 1.2
local AUTOUPDATE = true
local SCRIPT_NAME = "VeigarOS"

---------------------------------------------------------------------------------------------------------------------------------------------------------------------------
---------------------------------------------------------------------------------------------------------------------------------------------------------------------------
---------------------------------------------------------------------------------------------------------------------------------------------------------------------------

local SOURCELIB_URL = "https://raw.github.com/TheRealSource/public/master/common/SourceLib.lua"
local SOURCELIB_PATH = LIB_PATH.."SourceLib.lua"

if FileExist(SOURCELIB_PATH) then
	require("SourceLib")
else
	DOWNLOADING_SOURCELIB = true
	DownloadFile(SOURCELIB_URL, SOURCELIB_PATH, function() PrintChat("Required libraries downloaded successfully, please reload") end)
end

if DOWNLOADING_SOURCELIB then PrintChat("Downloading required libraries, please wait...") return end

local RequireI = Require("SourceLib")
RequireI:Add("vPrediction", "https://raw.github.com/Hellsing/BoL/master/common/VPrediction.lua")
RequireI:Add("SOW", "https://raw.github.com/Hellsing/BoL/master/common/SOW.lua")
RequireI:Check()

if RequireI.downloadNeeded == true then return end

-----------------
-----SPELLS------
-----------------
qrange = 650

wcastspeed = 1.25
wrange = 900
wradius = 230 --maximum radius of W
AArange = 525

eradius = 375 -- event horizon's radius has bounds from 300 to 400
erange = 600
ecastspeed = 0.25


----------------
-----COLORS-----
----------------
eCircleColor = ARGB(255,255,0,255)--0xB820C3 -- purple by default
wCircleColor = ARGB(255,255,0,0)--0xEA3737 -- orange by default
qCircleColor = ARGB(255,0,255,0)--0x19A712 --green by default

drawKillColor1 = ARGB(255,255,0,0) --red
drawKillColor2 = ARGB(255,0,255,0)--green
  
ts = TargetSelector(TARGET_LESS_CAST_PRIORITY, erange + eradius, DAMAGE_MAGIC)
ts.name = "Veigar"

enemyMinions = minionManager(MINION_ENEMY, qrange, myHero, MINION_SORT_HEALTH_ASC)
jungleMinions = minionManager(MINION_JUNGLE, qrange, myHero, MINION_SORT_HEALTH_ASC)


function OnLoad()
   PrintChat("<font color=\"#eFF99CC\">You are using VeigarOS ["..version.."] by Manzarek.</font>")
   _LoadLib()
   _LoadMenu()
end

function _LoadLib()
    VP = VPrediction(true)
	SOWi = SOW(VP)
end

function _LoadMenu()
	VeigarMenu = scriptConfig("VeigarOS "..version, "VeigarOS "..version)

    VeigarMenu:addTS(ts)

	VeigarMenu:addSubMenu("Drawing", "Drawing")
	VeigarMenu.Drawing:addParam("DrawAA", "Draw AA Range", SCRIPT_PARAM_ONOFF, true)
	VeigarMenu.Drawing:addParam("DrawQ", "Draw Q Range", SCRIPT_PARAM_ONOFF, true)
	VeigarMenu.Drawing:addParam("DrawW", "Draw W Range", SCRIPT_PARAM_ONOFF, true)
	VeigarMenu.Drawing:addParam("DrawE", "Draw E Range", SCRIPT_PARAM_ONOFF, true)
	VeigarMenu.Drawing:addParam("drawKillableMinions","Draw minion killable with Q", SCRIPT_PARAM_ONOFF, true)
	VeigarMenu.Drawing:addParam("drawKillable","Draw champion killable", SCRIPT_PARAM_ONOFF, true)


	VeigarMenu:addSubMenu("Orbwalker", "Orbwalker")
	SOWi:LoadToMenu(VeigarMenu.Orbwalker)
	--SOWi:RegisterAfterAttackCallback(AfterAttack)

	VeigarMenu:addSubMenu("Combo", "Combo")
	VeigarMenu.Combo:addParam("SmartCombo", "SmartCombo", SCRIPT_PARAM_ONKEYDOWN, false, string.byte("C"))
	VeigarMenu.Combo:addParam("Combo1", "Combo1 (E+W+DFG+Q+R)", SCRIPT_PARAM_ONKEYDOWN, false, string.byte("G"))
	VeigarMenu.Combo:addParam("Combo2", "Combo2 (E+W+Q)", SCRIPT_PARAM_ONKEYDOWN, false, string.byte("H"))
    VeigarMenu.Combo:addParam("AutoSeraph", "Auto Seraph", SCRIPT_PARAM_ONOFF, true)
	VeigarMenu.Combo:addParam("AutoSerpahHPct", "Auto Seraph Health Pct", SCRIPT_PARAM_SLICE, 20, 1, 100, 0)
	
	VeigarMenu:addSubMenu("Harass", "Harass")
	VeigarMenu.Harass:addParam("harassActive","Harass Enemy",SCRIPT_PARAM_ONKEYDOWN, false, string.byte("X"))
	VeigarMenu.Harass:addParam("harassConserveMana", "Conserve mana during harass", SCRIPT_PARAM_ONOFF,true)
	VeigarMenu.Harass:addParam("harassConserveManaMax", "Mana % to conserve", SCRIPT_PARAM_SLICE, 1, 1, 100, 0)
	
	VeigarMenu:addSubMenu("Farming","Farming")
	VeigarMenu.Farming:addParam("autoFarmQ", "Auto Farm with Q", SCRIPT_PARAM_ONKEYDOWN, false, string.byte("W"))
	VeigarMenu.Farming:addParam("autoFarmQa", "Auto Farm with Q Alias", SCRIPT_PARAM_ONKEYDOWN, false, string.byte("X"))
	VeigarMenu.Farming:addParam("autoFarmQaa", "Auto Farm with Q Alias2", SCRIPT_PARAM_ONKEYDOWN, false, string.byte("V"))
	VeigarMenu.Farming:addParam("farmConserveMana", "Conserve mana during farm", SCRIPT_PARAM_ONOFF,true)
	VeigarMenu.Farming:addParam("farmConserveManaMax", "Mana % to conserve", SCRIPT_PARAM_SLICE, 1, 1, 100, 0)
	
	VeigarMenu:addParam("ewCombo", "Use E+W Combo", SCRIPT_PARAM_ONKEYDOWN, false, string.byte("E"))
	
	
	VeigarMenu:addParam("packetCast", "Cast spells using packets", SCRIPT_PARAM_ONOFF, true)

end

function OnTick()
  	ts:update()
	
	
	if VeigarMenu.Combo.AutoSeraph and healthPct() < VeigarMenu.Combo.AutoSerpahHPct  then
		autoSeraph()
	end
	
	if VeigarMenu.Combo.SmartCombo and ValidTarget(ts.target) then
		performSmartCombo()
	end
	
	if VeigarMenu.Combo.Combo1 and ValidTarget(ts.target) then
		performCombo1()
	end
	
	if VeigarMenu.Combo.Combo2 and ValidTarget(ts.target) then
		performCombo2()
	end
	
	if VeigarMenu.ewCombo == true and VeigarMenu.Combo.Combo2 == false and VeigarMenu.Combo.Combo1 == false and ValidTarget(ts.target) then
		useStunCombo(ts.target)
	end
	
	if VeigarMenu.Harass.harassActive and not player.dead then
		if (VeigarMenu.Harass.harassConserveMana and manaPct() > VeigarMenu.Harass.harassConserveManaMax) or not VeigarMenu.Harass.harassConserveMana then
			autoHarass()
		end
	end
	
	if (VeigarMenu.Farming.autoFarmQ == true or VeigarMenu.Farming.autoFarmQa == true or VeigarMenu.Farming.autoFarmQaa == true) and not player.dead then
		if (VeigarMenu.Farming.farmConserveMana and manaPct() > VeigarMenu.Farming.farmConserveManaMax) or not VeigarMenu.Farming.farmConserveMana then
		  autoFarm()
		end
	end
	
end

function OnDraw()
	if not player.dead then

		drawKilable()
		
		if VeigarMenu.Drawing.DrawAA == true then
			DrawCircle(myHero.x, myHero.y, myHero.z, qrange, 0xFF80FF)
		end
		if VeigarMenu.Drawing.DrawQ == true then
			DrawCircle(myHero.x, myHero.y, myHero.z, qrange, qCircleColor)
		end
		if VeigarMenu.Drawing.DrawW == true then
			DrawCircle(myHero.x, myHero.y, myHero.z, wrange, wCircleColor)
		end
		if VeigarMenu.Drawing.DrawE == true then
			DrawCircle(myHero.x, myHero.y, myHero.z, erange + eradius, eCircleColor)
		end

		if VeigarMenu.Drawing.drawKillableMinions then
			enemyMinions:update()
			if enemyMinions.objects[1] then
				local targetMinion = enemyMinions.objects[1]

				if ValidTarget(targetMinion, erange+eradius) and string.find(targetMinion.name, "Minion_") then
					if targetMinion.health < player:CalcMagicDamage(targetMinion, 45 * (player:GetSpellData(_Q).level - 1) + 80 + (.6 * player.ap)) then
						DrawCircle(targetMinion.x,targetMinion.y,targetMinion.z, 150, qCircleColor)
					end
				end
			end
			
			jungleMinions:update()
			if jungleMinions.objects[1] then
				local targetMinion = jungleMinions.objects[1]

				if ValidTarget(targetMinion, erange+eradius) then
					if targetMinion.health < player:CalcMagicDamage(targetMinion, 45 * (player:GetSpellData(_Q).level - 1) + 80 + (.6 * player.ap)) then
						DrawCircle(targetMinion.x,targetMinion.y,targetMinion.z, 150, qCircleColor)
					end
				end
			end
		end
    end
end

function autoSeraph()
	if GetInventoryHaveItem(3040, player) then
        SERAPH = GetInventorySlotItem(3040)
		if SERAPH ~= nil and myHero:CanUseSpell(SERAPH) == READY then 
			CastSpell(SERAPH)
		end
	end
end

function autoFarm()
	enemyMinions:update()
	if enemyMinions.objects[1] then
	  local targetMinion = enemyMinions.objects[1]
	  if ValidTarget(targetMinion, qrange) and string.find(targetMinion.name, "Minion_") then
		if targetMinion.health < player:CalcMagicDamage(targetMinion, 45 * (player:GetSpellData(_Q).level - 1) + 80 + (.6 * player.ap)) then
		  UseSpell(_Q, targetMinion)
		end
	  end
	end
	
	jungleMinions:update()
	if jungleMinions.objects[1] then
	  targetMinion = jungleMinions.objects[1]
	  if ValidTarget(targetMinion, qrange) then
		if targetMinion.health < player:CalcMagicDamage(targetMinion, 45 * (player:GetSpellData(_Q).level - 1) + 80 + (.6 * player.ap)) then
		  UseSpell(_Q, targetMinion)
		end
	  end
	end
end

function autoHarass()
	if myHero:CanUseSpell(_Q) == READY and ts.target and ValidTarget(ts.target) and GetDistance(ts.target) <= qrange then
		UseSpell(_Q, ts.target)
	end
end


function manaPct()
  return math.round((myHero.mana / myHero.maxMana)*100)
end

function healthPct()
  return math.round((myHero.health / myHero.maxHealth)*100)
end
  
function ValidTarget(target)
  return target ~= nil and target.team ~= player.team and target.visible and not target.dead and GetDistanceTo(player, target) <= (erange + eradius)
end

function performCombo1()
	targ = ts.target
	useStunCombo(targ)
	if CanUseSpell(_E) == COOLDOWN or CanUseSpell(_E) == NOTLEARNED then
		useItems(targ)
		local DFG = GetInventorySlotItem(3128)
		if DFG == nil or myHero:CanUseSpell(DFG) == COOLDOWN then
			UseSpell(_Q, targ)
			UseSpell(_R, targ)
		end
	end
end

function performCombo2()
	targ = ts.target
	useStunCombo(targ)
	if CanUseSpell(_E) == COOLDOWN or CanUseSpell(_E) == NOTLEARNED then
			UseSpell(_Q, targ)
	end
end

function performSmartCombo()
	
	targ = ts.target
	combo = dmgCalc(targ, false)
	if aLock[targ.name] == 0 or aTime[targ.name] == nil then
		aLock[targ.name] = 1
		aTime[targ.name] = GetTickCount()
	end
	if combo == 1 then
		performCombo1()
	else
		performCombo2()
	end
end

function useItems(target)
        local DFG = GetInventorySlotItem(3128)
        if DFG ~= nil and myHero:CanUseSpell(DFG) == READY then CastSpell(DFG, target) end
end

function useStunCombo(object)
  local spellPos, hitchance
  if object and ValidTarget(object) then
	  if player:CanUseSpell(_E) == READY and not object.dead then
		castESpellOnTarget(object)
	  end
  end

  if object and ValidTarget(object) then
	if (CanUseSpell(_E) == COOLDOWN and not object.canMove) or CanUseSpell(_E) == NOTLEARNED and CanUseSpell(_W) == READY and not object.dead then
      --spellPos, hitchance = VP:GetCircularCastPosition(object, wcastspeed, wradius, wrange)
      --if spellPos and (hitchance >= 2) then
        --UseSpell(_W, spellPos.x, spellPos.z)
		--we dont use vprecdiction for w
		UseSpell(_W, object)
      --end
    end
  end
end

function castESpellOnTarget(object)

  if player:CanUseSpell(_E) then

    local target1 = object
    local CircX, CircZ, returnTarget
    local players = heroManager.iCount
    for j = 1, players, 1 do

      local target2 = heroManager:getHero(j)
      if ValidTarget(target1) and ValidTarget(target2) and target1.name ~= target2.name then --make sure both targets are valid enemies and in spell range
        if targetsinradius(target1, target2) and CircX == nil and CircZ == nil then --true if a double stun is possible

          CircX, CircZ = calcdoublestun(target1, target2) --calculates coords for stun
          if CircX and CircZ then
            break
          end
      end
      end
    end

    if CircX == nil or CircZ == nil then --true if double stun coords were not found
      if ValidTarget(object) then
        CircX, CircZ = calcsinglestun() --calculate stun coords for a single target
    end
    end
    if CircX and CircZ then --true if any coords were found
      UseSpell(_E, CircX, CircZ)
    end
  end
end

function targetsinradius(target1, target2)
  local dis, dis1, dis2, predicted1, predicted2, hitchance1, hitchance2

  predicted1, hitchance1 = VP:GetPredictedPos(target1, ecastspeed)
  predicted2, hitchance2  = VP:GetPredictedPos(target2, ecastspeed)

  if predicted1 and predicted2 then
    dis = math.sqrt((predicted2.x - predicted1.x) ^ 2 + (predicted2.z - predicted1.z) ^ 2) --find the distance between the two targets

    dis1 = math.sqrt((predicted1.x - player.x) ^ 2 + (predicted1.z - player.z) ^ 2) --distance from player to predicted target 1
    dis2 = math.sqrt((predicted2.x - player.x) ^ 2 + (predicted2.z - player.z) ^ 2) --distance from player to predicted target 2
  end

  return dis ~= nil and dis <= (eradius * 2) and dis1 <= (eradius + erange) and dis2 <= (eradius + erange)
end

function calcdoublestun(target1, target2)

  local CircX, CircZ, predicted1, predicted2, hitchance1, hitchance2

  predicted1, hitchance1 = VP:GetPredictedPos(target1, ecastspeed)
  predicted2, hitchance2  = VP:GetPredictedPos(target2, ecastspeed)

  if predicted1 and predicted2 and (hitchance1 >=2) and (hitchance2 >=2) then

    local h1 = predicted1.x
    local k1 = predicted1.z
    local h2 = predicted2.x
    local k2 = predicted2.z

    local u = (h1) ^ 2 + (h2) ^ 2 - 2 * (h1) * (h2) - (k1) ^ 2 + (k2) ^ 2
    local w = k1 - k2
    local v = h2 - h1

    local a = 4 * (w ^ 2 + v ^ 2)
    local b = 4 * (u * w - 2 * ((v) ^ 2) * (k1))
    local c = (u) ^ 2 - 4 * ((v ^ 2)) * (eradius ^ 2 - k1 ^ 2)

    local Z1 = ((-b) + math.sqrt((b) ^ 2 - 4 * a * c)) / (2 * a) --Z coord for first solution
    local Z2 = ((-b) - math.sqrt((b) ^ 2 - 4 * a * c)) / (2 * a) --Z coord for second solution

    local d = (Z1 - k1) ^ 2 - (eradius) ^ 2
    local e = (Z1 - k2) ^ 2 - (eradius) ^ 2

    local X1 = ((h2) ^ 2 - (h1) ^ 2 - d + e) / (2 * v) -- X Coord for first solution

    local p = (Z2 - k1) ^ 2 - (eradius) ^ 2
    local q = (Z2 - k2) ^ 2 - (eradius) ^ 2

    local X2 = ((h2) ^ 2 - (h1) ^ 2 - p + q) / (2 * v) --X Coord for second solution


    --determine if these 2 points are within range, and which is closest

    local dis1 = math.sqrt((X1 - player.x) ^ 2 + (Z1 - player.z) ^ 2)
    local dis2 = math.sqrt((X2 - player.x) ^ 2 + (Z2 - player.z) ^ 2)

    if dis1 <= (eradius + erange) and dis1 <= dis2 then
      CircX = X1
      CircZ = Z1
    end
    if dis2 <= (eradius + erange) and dis2 < dis1 then
      CircX = X2
      CircZ = Z2
    end
  end
  return CircX, CircZ
end

function calcsinglestun()
  if (ts.target ~= nil) and player:CanUseSpell(SPELL_3) == READY then
    local predicted, hitchance1

    predicted, hitchance1 = VP:GetPredictedPos(ts.target, ecastspeed)

    if predicted and (hitchance1 >=2) then
      local CircX, CircZ
      local dis = math.sqrt((player.x - predicted.x) ^ 2 + (player.z - predicted.z) ^ 2)
      CircX = predicted.x + eradius * ((player.x - predicted.x) / dis)
      CircZ = predicted.z + eradius * ((player.z - predicted.z) / dis)
      return CircX, CircZ
    end
  end
end

function GetDistanceTo(target1, target2)
  local dis
  if target2 ~= nil and target1 ~= nil then
    dis = math.sqrt((target2.x - target1.x) ^ 2 + (target2.z - target1.z) ^ 2)
  end
  return dis
end

function UseSpell(Spell,param1,param2)
  if VeigarMenu.packetCast and VIP_USER then
    if param1 and param2 then
      Packet("S_CAST", {spellId = Spell, fromX = param1, fromY = param2, toX = param1, toY = param2}):send()
    elseif param1 then
      Packet("S_CAST", {spellId = Spell, targetNetworkId = param1.networkID}):send()
    else
      Packet("S_CAST", {spellID = Spell, targetNetworkID = myHero.networkID}):send()
    end
  else
    if param1 and param2 then
      CastSpell(Spell,param1,param2)
    elseif param1 then
      CastSpell(Spell,param1)
    else
      CastSpell(Spell)
    end
  end
end

function drawKilable()
	if VeigarMenu.Drawing.drawKillable then
		players = heroManager.iCount
		for i = 1, players, 1 do
			drawtarget = heroManager:getHero(i)
			combo = dmgCalc(drawtarget, true)
			if combo == 2 then 
				--PrintFloatText(drawtarget,0, "Finish him Combo2!!!")
				DrawCircle(drawtarget.x, drawtarget.y, drawtarget.z, 100, drawKillColor2)
			elseif combo == 1 then
				--PrintFloatText(drawtarget,0, "Finish him Combo1!!!")
				for j = 0, 10 do
					DrawCircle(drawtarget.x, drawtarget.y, drawtarget.z, 100 + j * 1.5, drawKillColor1)
				end
			end
		end
	end
end

aCombo = {}
aTime = {}
aLock = {}
function dmgCalc(drawtarget)
	if drawtarget ~= nil and drawtarget.team ~= player.team and drawtarget.visible and not drawtarget.dead then
		if aTime[drawtarget.name]~= nil and GetTickCount() - aTime[drawtarget.name] < 2000 then
			return aCombo[drawtarget.name]
		end
		aLock[drawtarget.name] = 0
		local qDamage = getDmg("Q",drawtarget,myHero)
		local wDamage = getDmg("W",drawtarget,myHero)
		local rDamage = getDmg("R",drawtarget,myHero)
		local dfgDamage = (GetInventorySlotItem(3128) and getDmg("DFG",drawtarget,myHero) or 0)
		local combo1 = 0
		local combo2 = 0
		if CanUseSpell(_Q) == READY then combo1 = combo1 + qDamage end
		if CanUseSpell(_W) == READY and (CanUseSpell(_E) == READY or not drawtarget.canMove) then combo1 = combo1 + wDamage end
		combo2 = combo1
		if CanUseSpell(_R) == READY then combo1 = combo1 + rDamage end
		local DFG = GetInventorySlotItem(3128)
		if dfgDamage ~= 0 and DFG ~= nil and myHero:CanUseSpell(DFG) == READY then
			combo1 = combo1 * 1.2
			combo1 = combo1 + dfgDamage
		end
		if drawtarget.health <= combo2 then
			aCombo[drawtarget.name] = 2
			return 2
		elseif drawtarget.health <= combo1 then
			aCombo[drawtarget.name] = 1
			return 1
		end
		aCombo[drawtarget.name] = 0
		return 0
	end
end
