//void

Squad sq;
Unit sqLeader;
Hero sqLeaderHero;
GAIKA sqGkIn, sqGkAiDest;
Settlement setGkIn, setGkAiDest;
Building setGkInCentralBuilding;
point sqPos, setGkAiDestCentralBuildingPos;
int aiPlayer, nSleepSquadMonitor, nMagePerc, nSqState, min, own, ally, enemy, enemy_hidden, i;
bool bUseRuins, bSynchApproach, bCoward, bGoAround, bTakeItems, bValidSetGkIn, bSqLeaderIsHero;
StrArray items;  // All items in the game
IntArray itemStatValue, itemEffectValue;
Sleep(500 + rand(1001));

aiPlayer = AIGetPlayer();
nSleepSquadMonitor = AIVar(aiPlayer, AIV_Sleep_SquadMonitor);
nMagePerc = AIVar(aiPlayer, AIV_MageAttach);

bUseRuins = AIVar(aiPlayer, AIV_UseRuins) != 0;
bSynchApproach = AIVar(aiPlayer, AIV_SynchApproach) != 0;
bCoward = AIVar(aiPlayer, AIV_Coward) != 0;
bGoAround = AIVar(aiPlayer, AIV_GoAround) != 0;
bTakeItems = AIVar(aiPlayer, AIV_TakeItems) != 0;

// items[ItemIdx] = ItemName	| The idea is to convert from name to int.
items.resize(40);

// --- CONSUMABLE ITEMS (indices 0-8) ---
items[0] = "Healing water";             // Heals 2000 HP
items[1] = "Bag of healing water";      // Heals 4000 HP
items[2] = "Rye spikes";               // 1000 food
items[3] = "Healing herbs";            // Full heal + stamina
items[4] = "Poison Mushroom";          // +1 level (needs 90% HP)
items[5] = "Ash of druid heart";       // Heals owner + 8 allies
items[6] = "Battle Drums of Rage";     // +30 dmg 10s
items[7] = "Horn of victory";          // 75 dmg to 15 enemies
items[8] = "Finger of death";          // Kills 4 enemies

// --- ACTIVABLE ITEMS (indices 9-12) ---
items[9] = "Skull of Pain";            // 250 HP + activable dmg
items[10] = "Fur gloves of health";    // 1200 HP + activable heal
items[11] = "Concentration stone";     // 60 dmg + activable
items[12] = "Bloodstone";              // 50 exp + activable

// --- BASIC ITEMS (indices 13-19) ---
items[13] = "Snake skin";              // 10 dmg (combinable)
items[14] = "Belt of snakes";          // 30 dmg
items[15] = "Eagle feather";           // 200 HP (combinable)
items[16] = "Feather amulet";          // 600 HP
items[17] = "Boar tooth";              // 2 lvl (combinable)
items[18] = "Boar teeth";              // 6 lvl
items[19] = "King's Belt";             // 600 HP + 10 armor

// --- PASSIVE ITEMS (indices 20-31) ---
items[20] = "Elephant Tusk";           // Regen 25/s
items[21] = "Amulet of Triumph";       // Heal 100 per kill
items[22] = "Ring of Power";           // 20 dmg + regen
items[23] = "Golden Ankh";             // 500 HP + 8 armor + regen
items[24] = "Silver Ankh";             // 4 armor to troops
items[25] = "Amulet of Courage";       // 4 dmg to troops
items[26] = "Stamina Diamond";         // 1 sta/15s to troops
items[27] = "Invigorating dark harp";  // 300 HP + 6 armor + sta
items[28] = "Travel boots";            // 4 armor + 2lvl + regen
items[29] = "Gem of Wisdom";           // 33% exp on unit death
items[30] = "Scroll of Death";         // Ghoul on death
items[31] = "Scroll of Life";          // Ghoul on kill

// --- USEFUL SPECIAL ITEMS (indices 32-35) ---
items[32] = "Spoils of War";           // 100 gold
items[33] = "Gold";                    // Variable gold
items[34] = "Gold bag";                // 1000 gold

// itemStatValue[ItemIdx] = StatValue
// Non defined are 0 by default
itemStatValue.resize(40);
itemStatValue[9] = 25;
itemStatValue[10] = 120;
itemStatValue[11] = 180;
itemStatValue[12] = 50;
itemStatValue[13] = 30;
itemStatValue[14] = 90;
itemStatValue[15] = 20;
itemStatValue[16] = 60;
itemStatValue[17] = 10;
itemStatValue[18] = 30;
itemStatValue[19] = 160;

itemStatValue[22] = 60;
itemStatValue[23] = 130;

itemStatValue[27] = 90;
itemStatValue[28] = 50;


// itemEffectValue[ItemIdx] = EffectValue
itemEffectValue.resize(40);
itemEffectValue[0] = 20;
itemEffectValue[1] = 20;
itemEffectValue[2] = 5;
itemEffectValue[3] = 10;
itemEffectValue[4] = 200;
itemEffectValue[5] = 20;
itemEffectValue[6] = 200;
itemEffectValue[7] = 10;
itemEffectValue[8] = 80;
itemEffectValue[9] = 135;
itemEffectValue[10] = 0;
itemEffectValue[11] = 0;
itemEffectValue[12] = 0;
itemEffectValue[20] = 25;
itemEffectValue[21] = 20;
itemEffectValue[22] = 23;
itemEffectValue[23] = 5;
itemEffectValue[24] = 165;
itemEffectValue[25] = 165;
itemEffectValue[26] = 100;
itemEffectValue[27] = 40;
itemEffectValue[28] = 100;
itemEffectValue[29] = 300;
itemEffectValue[30] = 120;
itemEffectValue[31] = 140;
itemEffectValue[32] = 0;
itemEffectValue[33] = 100;
itemEffectValue[34] = 100;

while (true) {
	i = GetTime() / 60000;
	if (i >= 60)
		min = 50;
	else if (i >= 45)
		min = MIN(50, MAX(41, MilUnits(aiPlayer) / 4));
	else if (i >= 30)
		min = MIN(50, MAX(31, MilUnits(aiPlayer) / 4));
	else if (i >= 15)
		min = MIN(50, MAX(20, MilUnits(aiPlayer) / 4));
	else
		min = MIN(50, MAX(15, MilUnits(aiPlayer) / 4));

	for (i = NumSquads(aiPlayer) - 1; i >= 1; i -= 1) {
		sq = GetSquad(aiPlayer, i);
		if (sq.Size <= 0) 
			continue;
		sqLeader = sq.Leader;
		if (sqLeader.IsAlive && !sqLeader.AsShip().IsValid && !sqLeader.GetFlags(UNITFLAG_NOAI) && !sq.TestFlags(SF_NOAI)) {
			sqGkIn = sq.GAIKAIn;
			if (IsWaterLsa(sqGkIn.LSA))//units in ships are not monitored
				if (sq.InHolder) {
					Sleep(5);
					continue;
				}

			nSqState = sq.State;
			sqPos = sq.pos;

			setGkIn = sqGkIn.settlement;
			if (setGkIn.IsValid) {
				bValidSetGkIn = true;
				setGkInCentralBuilding = setGkIn.GetCentralBuilding();
			}
			else
				bValidSetGkIn = false;

			sqGkAiDest = sq.AIDest;
			setGkAiDest = sqGkAiDest.settlement;
			if (setGkAiDest.IsValid)
				setGkAiDestCentralBuildingPos = setGkAiDest.GetCentralBuilding().pos;

			if (nSqState == SS_Approach || nSqState == SS_IDLE)
				if (bValidSetGkIn) {
					if (setGkIn.IsIndependent) {//approach to capture a settlement when moving around it
						bool bCheck = false;
						if (setGkIn.IsVillage)
							bCheck = true;
						else if (setGkIn.IsShipyard)
							bCheck = true;
						else if (setGkIn.IsOutpost)
							if (!setGkIn.IsIndependentGuarded)
								bCheck = true;
						if (bCheck) {
							point ptBld;
							int nDist, nSight;
							sqLeader.SetLastAttackTime();
							sqLeader.SetVisible(true);
							ptBld = setGkInCentralBuilding.pos;
							nDist = sqLeader.DistTo(ptBld);
							nSight = setGkInCentralBuilding.sight * 2 / 3;
							if (nDist > nSight) {
								sq.Units.SetCommand("advance", ptBld + (sqLeader.pos - ptBld) * nSight / nDist);
								if (sqGkAiDest > 0)
									sq.Units.AddCommand(false, "advance", sqGkAiDest.Center);
								Sleep(100);
								continue;
							}
						}
					}
					//gather staying army together
					if ((sqLeader.command == "idle" || sqLeader.command == "stand_position") && sqGkIn != sqGkAiDest && setGkAiDest.IsValid && setGkAiDest.IsEnemy(aiPlayer)) {
						bool bCheck = false;
						if (setGkIn.IsOutpost)
							bCheck = true;
						else if (setGkIn.IsVillage)
							bCheck = true;
						else if (setGkIn.IsShipyard)
							bCheck = true;
						if (bCheck)
							if (setGkAiDestCentralBuildingPos.Dist(sqPos) < 2000) {
								sqGkAiDest.Eval(AI_ALL, aiPlayer, own, ally, enemy, enemy_hidden);
								if (own + ally + sq.Eval > enemy * 2) {
									sq.SetCmd(SS_KillAll, 0, SF_ADVCHOOSER, "advance", setGkAiDestCentralBuildingPos);
									Sleep(100);
									continue;
								}
							}
					}
				}
			if (nSqState != SS_IDLE && nSqState != SS_ApproachWait && nSqState != SS_Siege && nSqState != SS_Catapult && 
				!sqLeader.InHolder && 
				(sqLeader.command == "idle" || sqLeader.command == "stand_position")) {

				sq.DelOrder();
				sq.SetState(SS_IDLE);
			}

			if (nSqState == SS_KillAll) {
				// Verificar dispersion de squad y reagrupar
				if (sq.Size > 1) {
					{
						ObjList units;
						point squadCenter;
						int nCounted, ui, nScatter;

						units = sq.Units;
						for (ui = 0; ui < units.count; ui += 1) {
							Unit u;
							u = units[ui].AsUnit();
							if (u.IsAlive && u != sqLeader) {
								if (nCounted == 0)
									squadCenter = u.pos;
								else
									squadCenter = squadCenter + u.pos;
								nCounted += 1;
							}
						}
						if (nCounted > 0) {
							squadCenter = squadCenter / nCounted;

							nScatter = sqLeader.pos.Dist(squadCenter);
							if (nScatter > 400) {
								sq.SetCmd(SS_IDLE, 0, SF_ADVCHOOSER, "move", squadCenter);
								Sleep(100);
								continue;
							}
						}
					}
				}


				if (sqLeader.command == "ai_killall" || sqLeader.command == "idle" || sqLeader.command == "stand_position") {
					if (setGkAiDest.IsValid)
						if (!sqLeader.IsVisible) {
							sqLeader.SetLastAttackTime();
							sqLeader.SetVisible(true);
						}
					if (sq.StateTime > 20000)
						if (setGkAiDest.IsValid) {
							if (setGkAiDestCentralBuildingPos.Dist(sqPos) > 500)
								sq.SetCmd(SS_KillAll, 0, SF_ADVCHOOSER, "advance", setGkAiDestCentralBuildingPos);
							else if (bValidSetGkIn)
								if (setGkIn.IsAlly(aiPlayer))
									sq.SetCmd(SS_Enter, 0, SF_ADVCHOOSER, "enter", setGkInCentralBuilding);
						}
						else
							sq.SetCmd(SS_KillAll, 0, SF_ADVCHOOSER, "ai_killall");
				}
			}
			else if (nSqState == SS_Catapult) {
				if (!sqLeader.InHolder)
					if (sqLeader.command != "build_catapult")
						sq.SetState(SS_IDLE);
			}
			else if (nSqState == SS_IDLE)
				if (sqLeader.command == "idle" || sqLeader.command == "stand_position")
					if (!sq.InHolder)
						if (sqGkIn == sqGkAiDest)
							if (sqGkIn.StratRunning(aiPlayer) == GS_EnterSettlement)
								if (!sq.TestFlags(SF_PEACEFUL))
									if (!sq.TestFlags(SF_NOAI))
										if (bValidSetGkIn)
											sq.SetCmd(SS_Enter, 0, SF_ADVCHOOSER, "enter", setGkInCentralBuilding);

			sqLeaderHero = sqLeader.AsHero();
			bSqLeaderIsHero = sqLeaderHero.IsValid;

			if (sqLeader.command == "idle" || sqLeader.command == "stand_position") {
				if (nSqState == SS_IDLE || nSqState == SS_Enter)
					if (sqGkAiDest > 0 && sqGkIn != sqGkAiDest) {
						sq.SendTo(sqGkAiDest, 1);
						Sleep(100);
						continue;
					}
					else if (sq.Size <= min - 10)//send units from tents and other small armies at home
						if (sq.Eval < 4000)
							if (sqGkIn.StratRunning(aiPlayer) == GS_NONE || sqGkIn.StratRunning(aiPlayer) == GS_EnterSettlement)
								if (!sq.TestFlags(SF_PEACEFUL) || sqLeader.AsDruid().IsValid) {
									Settlement s;
									s = sqLeader.GetHolderSett();
									if (s.IsTTent) {
										if (rand(15) == 0)
											if (s.UnitsCount >= 10) {
												s = NearestStronghold(sqPos, sq.Player);
												if (s.IsValid) {
													SquadList SL;
													sqGkIn.GetSquads(SL, AI_STAYING, aiPlayer);
													SL.Lock();
													for (; !SL.EOL; SL.Next())
														if (SL.Cur.Leader.GetHolderSett().IsTTent)
															sq.SetCmd(SS_Flee, 0, SF_ADVCHOOSER, "enter", s.GetCentralBuilding());
													SL.Unlock();
													Sleep(100);
													continue;
												}
											}
									}
									else if (!sq.InHolder && GetTime() > 900000) {
										s = NearestStronghold(sqPos, sq.Player);
										if (s.IsValid) {
											sq.SetCmd(SS_Flee, 0, SF_ADVCHOOSER, "enter", s.GetCentralBuilding());
											Sleep(100);
											continue;
										}
									}
									else if (!bSqLeaderIsHero)
										if (!sqLeader.HasFreedom)
											if (!s.IsStronghold) {
												s = NearestStronghold(sqPos, sq.Player);
												if (s.IsValid) {
													sq.SetCmd(SS_Flee, 0, SF_ADVCHOOSER, "enter", s.GetCentralBuilding());
													Sleep(100);
													continue;
												}
											}
								}
				if (nSqState == SS_IDLE || nSqState == SS_Wait)//retreat idle units from tower/sentry range
					if (sq.LastFightTime > GetTime() - 3000) {
						Obj lastAttacker;
						lastAttacker = sq.GetLastAttacker();
						if (lastAttacker.IsAlive)
							if (lastAttacker.IsSentry) {
								point pt;
								pt = sqPos - sq.GetLastAttacker().pos;
								pt.SetLen(125);
								sq.SetCmd(SS_IDLE, 0, SF_ADVCHOOSER, "move", sqPos + pt);
							}
							else if (lastAttacker.AsBuilding().IsValid) {
								point pt;
								pt = sqPos - sq.GetLastAttacker().pos;
								pt.SetLen(150);
								sq.SetCmd(SS_IDLE, 0, SF_ADVCHOOSER, "move", sqPos + pt);
							}
					}
			}
			// =============================
			// FIND AND LOOT RUINS
			// =============================
			if (bUseRuins)//use ruins
				if (rand(3) == 0)
					if (bSqLeaderIsHero)
						if (sqLeaderHero.free_item_slots > 0)
							if (sq.InHolder)
								if (bValidSetGkIn)
									if (setGkIn.IsStronghold) {
										Obj ruins;
										if (nSqState == SS_Ruins)
											sq.SetState(SS_IDLE);
										ruins = FindRuins(sqPos, 8000, sqLeader.inherentlevel);
										if (ruins.IsValid) {
											sqLeaderHero.DetachArmy();
											sq.SetCmd(SS_Ruins, 0, SF_ADVCHOOSER, "enter", ruins);
											sqLeader.AddCommand(false, "enter", setGkInCentralBuilding);
											Sleep(100);
											continue;
										}
									}
			// =============================
			// USE ITEMS
			// =============================
			if (sqLeader.items_count > 0)//use items
				if (bSqLeaderIsHero) {
					if (sqLeader.HasItem("Poison Mushroom"))
						if (sqLeader.HasItem("Healing herbs"))
							sqLeader.UseItem("Poison Mushroom");
						else if (sqLeader.HasItem("Ash of druid heart"))
							sqLeader.UseItem("Poison Mushroom");
						else if (sqLeader.HasItem("Ring of Power"))
							sqLeader.UseItem("Poison Mushroom");
						else if (sqLeader.HasItem("Elephant Tusk"))
							sqLeader.UseItem("Poison Mushroom");
						else {
							Item water_bowl, water_bag;
							int amount_bowl, amount_bag;

							water_bowl = sqLeader.FindItem("Healing water");
							if (water_bowl.IsValid)
								amount_bowl = water_bowl.use_count;

							water_bag = sqLeader.FindItem("Bag of healing water");
							if (water_bag.IsValid)
								amount_bag = water_bag.use_count;

							if (sqLeader.maxhealth / 2 <= MAX(amount_bowl, amount_bag))//use if possible to heal at least 50% max health with water
								sqLeader.UseItem("Poison Mushroom");
						}

					if (sqLeader.HasItem("Healing herbs"))
						if (sqLeader.health < sqLeader.maxhealth / 4)
							sqLeader.UseItem("Healing herbs");

					if (sqLeader.HasItem("Healing water"))
						if (sqLeader.health < sqLeader.maxhealth / 3)
							sqLeader.UseItem("Healing water");
						else if (sq.health < sq.maxhealth / 2)
							sqLeader.UseItem("Healing water");
						else if (sq.health <= sq.maxhealth - 1000)
							sqLeader.UseItem("Healing water");

					if (sqLeader.HasItem("Bag of healing water"))
						if (sqLeader.health < sqLeader.maxhealth * 2 / 5)
							sqLeader.UseItem("Bag of healing water");
						else if (sq.health < sq.maxhealth * 3 / 5)
							sqLeader.UseItem("Bag of healing water");
						else if (sq.health <= sq.maxhealth - 800)
							sqLeader.UseItem("Bag of healing water");

					if (sqLeader.HasItem("Ash of druid heart"))
						if (sqLeader.health < sqLeader.maxhealth / 4)
							sqLeader.UseItem("Ash of druid heart");
						else if (sq.health < sq.maxhealth / 3)
							sqLeader.UseItem("Ash of druid heart");

					if (sqLeader.HasItem("Rye spikes"))
						if (sq.food < sq.Size * 3 / 2)
							sqLeader.UseItem("Rye spikes");

					if (rand(3) == 0) {//avoid spamming items
						str item;
						if (sqLeader.HasItem("Horn of victory"))
							item = "Horn of victory";
						else if (sqLeader.HasItem("Finger of death"))
							item = "Finger of death";
						else if (sqLeader.HasItem("Skull of Pain")) {
							if (sqLeader.health >= sqLeader.maxhealth * 3 / 4)
								item = "Skull of Pain";
						}
						else if (sqLeader.HasItem("Battle Drums of Rage"))
							if (nSqState == SS_KillAll)
								item = "Battle Drums of Rage";
							else if (sqLeader.command == "ai_killall")
								item = "Battle Drums of Rage";
							else if (sqLeader.command == "engage")
								item = "Battle Drums of Rage";
							else if (sqLeader.command == "attack")
								item = "Battle Drums of Rage";
						if (item != "") {
							sqGkIn.Eval(AI_ALL, aiPlayer, own, ally, enemy, enemy_hidden);
							if (own + ally < sqGkIn.MinNeed(aiPlayer, own, ally, enemy) * 5 / 4)//difficult situation
								sqLeader.UseItem(item);
						}
					}
				}
			// =========================
			// DROP ITEMS
			// =========================
			if (bSqLeaderIsHero &&
				(nSqState == SS_IDLE || nSqState == SS_Enter || nSqState == SS_Ruins || nSqState == SS_Wait) &&
				sq.InHolder && bValidSetGkIn) {
				if (setGkIn.IsStronghold && sqLeader.item_count > 0) {
					bool tryDrop;
					int nPosibilities;
					pr("Seems the hero has items and has nothing to do, lets calculate de drop chance.");
					nPosibilities = (sqLeader.free_item_slots * 20) + 1;
					tryDrop = rand(nPosibilities) == 0;
					pr("The drop chance is one in: " + nPosibilities);
					if (tryDrop) {
						IntArray heroItems;
						IntArray itemScore;
						Item worstItem;
						int nItems, nWorstScore, nScoreThreshold, j, k, l;
						pr("TryDrop true. Entered drop logic");
						nItems = sqLeader.items_count;
						nScoreThreshold = 150;
						nWorstScore = 999999;

						heroItems.resize(nItems);
						itemScore.resize(nItems);  
						for (j = 0; j < nItems; j += 1) {
							Item item;
							int nStatScore, nEffectScore, nTotalScore, itemId, otherItemId;

							item = sqLeader.GetItem(j+1);
							if (!item.IsValid)
								continue;
							
							itemId = items.find(item.name) - 1;
							if(itemId < 0)
								continue;

							
							nStatScore = itemStatValue[itemId];
							nEffectScore = itemEffectValue[itemId];

							if (item.name == "Gem of Wisdom") {
								nEffectScore = nEffectScore - sqLeader.inherentlevel * 6;
							}
							else if (item.name == "Invigorating dark harp") {
								Hero sqHero;
								int nHeroSkill;
								
								sqHero = sqLeader.AsHero();
								nHeroSkill = sqHero.GetSkill(hsAssault) + sqHero.GetSkill(hsBattleCry) + sqHero.GetSkill(hsCharge) + sqHero.GetSkill(hsHealing);
								if (nHeroSkill > 0) 
									nEffectScore = itemEffectValue[itemId] * nHeroSkill;
								else
									nEffectScore = nEffectScore/2;
							} 
							else if (item.name == "Healing water" || item.name == "Bag of healing water") 
								nEffectScore = nEffectScore * item.use_count / 500;				
							else if (item.name == "Rye spikes") 
								nEffectScore = nEffectScore * item.use_count / 200;							
							else if (item.name == "Poison mushrooms" && sqLeader.free_item_slots == 0) 
								nEffectScore = nScoreThreshold - 1;							
							else if (item.name == "Healing herbs") 
								nEffectScore = nEffectScore * sqLeader.maxhealth / 500;							
							else if (item.name == "Ash of druid heart") 
								nEffectScore = nEffectScore * item.use_count * sqLeader.maxhealth / 500;							
							else if (item.name == "Horn of victory") 
								nEffectScore = nEffectScore * item.use_count;						
							else if (item.name == "Skull of pain") 
								nEffectScore = nEffectScore * sqLeader.maxhealth / 1000;
							// Endif

							for(k = 0; k < nItems; k += 1) {
								if(heroItems[k] < 1)		// Empty. We save itemId + 1.  0 means no items. 1 "would" be healing water.
									continue;
								otherItemId = heroItems[k] - 1;
								if (itemId == otherItemId && itemStatValue[itemId] > 0)  // Duplicate of stats dont work.
									nStatScore = 0;
								else if (itemId <= 5 && itemId != 4 && otherItemId <= 5 && itemId != 4 &&
										 itemScore[itemId] <= itemScore[otherItemId])  // Both healing items and this one is worse
									nEffectScore = nEffectScore / 2;
								// Endif
							}
							nTotalScore = nStatScore + nEffectScore;
							heroItems[j] = itemId + 1;
							itemScore[j] = nTotalScore;

							// Track the worst item
							if (nTotalScore < nWorstScore) {
                                nWorstScore = nTotalScore;
								worstItem = item;
								pr("Current worst score: " + nWorstScore);
								pr("Current worst item: " + item.name);
                            }
						}
						if (nWorstScore < nScoreThreshold && worstItem.IsValid) {
							point exitPt;
							point offSet;
							pr("Attempt to drop item.");
							pr("Hero race: " + sqLeader.race + ", level: " + sqLeader.inherentlevel);
							exitPt = setGkInCentralBuilding.GetExitPoint(sqLeader.pos, false);
							offSet = Point(300,300);

							sqLeader.ExitHolder(exitPt);
							Sleep(100);
							//sqLeader.AddCommand(true, "move", exitPt + offSet);
							//Sleep(100);
							//sqLeader.AddCommand(true, "dropitem", exitPt + offSet);
							//Sleep(100);
							pr("After ExitHolder hero position is x=" + sqLeader.pos.x + ", y=" + sqLeader.pos.y);
							sqLeader.DropItem(worstItem, sqLeader.pos + offSet);
							sqLeader.SetUser(GetTime() + 60000);

							Sleep(100);
							continue;
						}
					}
				}
			}
			// =============================
			// SPOILS OF WAR
			// =============================
			// Trade spoils of war for gold
			if (nSqState != SS_KillAll && nSqState != SS_Flee && nSqState != SS_Enter) {
				if (sqLeader.BestTargetInSquadSight.IsDead) {
					int nTotalSpoils, j, k;
					ObjList squadUnits;
					Unit u;
					Item item;

					squadUnits = sq.Units;

					for (j = 0; j < squadUnits.count; j += 1) {
						u = squadUnits[j].AsUnit();
						if (u.IsAlive) {
							int nItems;
							nItems = u.items_count;
							if (nItems > 0) {
								for (k = 0; k < nItems; k +=1) {
									item = u.GetItem(k);
									if (item.IsValid)
										if (item.name == "Spoils of War")
											nTotalSpoils += 1;
								}
							}
						}
					}
					if (nTotalSpoils >= 10) {
						if (bValidSetGkIn) {
							if (setGkIn.IsAlly(aiPlayer) && !setGkIn.IsFull) {
								int nDist;
								nDist = sqPos.Dist(setGkInCentralBuilding.pos);
								if (nDist <= 2000) {
									sq.SetCmd(SS_Enter, 0, SF_ADVCHOOSER, "enter", setGkInCentralBuilding);
									Sleep(100);
									continue;
								}
							}
						}
						if (!bValidSetGkIn || !setGkIn.IsAlly(aiPlayer)) {
							Settlement s;
							s = NearestStronghold(sqPos, aiPlayer);
							if (s.IsValid) {
								int nDist;
								nDist = sqPos.Dist(s.GetCentralBuilding().pos);
								if (nDist <= 2000 && !s.IsFull) {
									sq.SetCmd(SS_Enter, 0, SF_ADVCHOOSER, "enter", s.GetCentralBuilding());
									Sleep(100);
									continue;
								}
							}
						}
					}
				}
			}
			// =============================
			// FLEEING SQUADS
			// =============================
			if (nSqState == SS_Flee)  //stop fleeing to heal and check if stopping fleeing is worth
				if (sq.InHolder)
					sq.SetState(SS_IDLE);
				else {
					bool bCheck = false;

					if (bSqLeaderIsHero)
						if (sq.food > 100)
							if (sqLeader.BestTargetInSquadSight.IsDead) {
								int healers;
								healers = sq.Count("GDruid");
								if (healers < 5) {
									healers += sq.Count("RPriest");
									if (healers < 5)
										healers += sq.Count("HPriest");
								}
								if (healers >= 5)
									sq.SetCmd(SS_IDLE, 0, SF_ADVCHOOSER, "move", sqLeader.pos);
							}

					if (bSqLeaderIsHero)
						if (sqLeader.health < sqLeader.maxhealth / 3)
							sqLeaderHero.DetachArmy();
					if (sqPos.Dist(sqGkAiDest.Center) <= 1500)
						bCheck = true;
					else if (sqLeader.BestTargetInSquadSight.IsDead)
						bCheck = true;
					if (bCheck)
						if (sqGkIn == sqGkAiDest) {
							if (bValidSetGkIn)
								if (!setGkIn.IsAlly(aiPlayer))
									sq.ClrCmd(SS_IDLE, 0, SF_ADVCHOOSER);
								else if (setGkIn.IsFull)
									sq.ClrCmd(SS_IDLE, 0, SF_ADVCHOOSER);
								else
									sq.SetCmd(SS_Enter, 0, SF_ADVCHOOSER, "enter", setGkInCentralBuilding);
							else
								sq.ClrCmd(SS_IDLE, 0, SF_ADVCHOOSER);
							Sleep(100);
							continue;
						}
						else if (bCoward)
							if (sq.Size >= min - 10)
								if (sqLeader.health * 3 >= sqLeader.maxhealth * 2)
									if (sq.health * 3 >= sq.maxhealth * 2) {
										sq.SetState(SS_Approach);
										Sleep(100);
										continue;
									}
				}
			// =============================
			// NOT FLEEING SQUADS
			// =============================
			else {
				// =============================
				// FEED SQUADS
				// =============================
				if (sq.Eval >= 3000) {//check feeding
					int needed, food;
					needed = sq.Size * (sqPos.Dist(sqGkAiDest.Center) + 200) / 700;//add 200 to help feeding already hungry squads
					if (bSynchApproach)
						needed = needed * 4 / 3;
					food = sq.food + sq.FoodComing;
					if (food + 100 < needed)//do not ask for less than 100 food
						sq.SendFoodWagon(needed - food, 3000);
				}
				if (nSqState != SS_Ruins)  //flee behaviour and collection of items
					if (bSqLeaderIsHero) {
						//==============================
						// FLEE BEHAVIOUR
						//==============================
						bool bHeroHurt = false, bDetachArmy = false;
						int nFlee;//2-hero_dying, 4-army_dying, 8-losing

						if (sqLeader.health * 3 < sqLeader.maxhealth * 2)
							if (sqLeader.BestTargetInSquadSight.IsAlive) {
								bHeroHurt = true;
								nFlee += 2;
								if (sqLeader.health < sqLeader.maxhealth / 3)
									bDetachArmy = true;
							}

						if (bCoward) {
							bool bFleeCheck = false;
							if (sq.health < sq.maxhealth / 2)
								if (!sqLeaderHero.SkillInEffect(hsFrenzy))//avoid fleeing if the skill has just been activated
									nFlee += 4;
							if (sqGkAiDest == sqGkIn)
								bFleeCheck = true;
							if (!bFleeCheck)
								if (bValidSetGkIn)
									if (setGkIn.IsTTent)
										if (setGkIn.IsEnemy(aiPlayer))
											if (sqLeader.command == "engage")
												bFleeCheck = true;
							if (bFleeCheck) {
								sqGkIn.Eval(AI_ALL, aiPlayer, own, ally, enemy, enemy_hidden);
								if (own + ally < sqGkIn.MinNeed(aiPlayer, own, ally, enemy) / 2)
									nFlee += 8;
							}
						}
					
						if (!bHeroHurt)
							if (nFlee != 0)
								if (nFlee != 8) {
									int nMinNeed;
									sqGkAiDest.Eval(AI_COMING + AI_STAYING, aiPlayer, own, ally, enemy, enemy_hidden);
									nMinNeed = sqGkIn.MinNeed(aiPlayer, own, ally, enemy);
									if (own + ally >= nMinNeed)
										if (sq.Size > 6) {
											int n;
											n = own + ally - sq.Eval;
											if (n > 0)
												if (n < nMinNeed)//do not flee if allies cannot win
													nFlee = 0;
										}
								}

						if (nFlee != 0) {
							sqGkIn.Eval(AI_STAYING, aiPlayer, own, ally, enemy, enemy_hidden);
							enemy += sqGkIn.Eval(AI_LEAVING, aiPlayer, AI_ENEMY);
							if (enemy <= 0)
								if (bValidSetGkIn)
									if (setGkIn.IsEnemy(aiPlayer))
										if (setGkIn.CanBeCaptured)
											nFlee = 0;

							if (nFlee != 0) {
								GAIKA gFlee;

								gFlee = NearestHospital(sq);
								if (gFlee == 0)	{
									int nHomeGaikaID;
									nHomeGaikaID = EnvReadInt(aiPlayer, "HomeGaika");
									if (nHomeGaikaID > 0)
										gFlee = GetGAIKA(nHomeGaikaID);
								}
								if (nFlee == 8)
									if (sqGkAiDest != sqGkIn) {//ambushed but otherwise ok, decide where to flee
										int distGoal;
										if (sq.DestGAIKA == sqGkAiDest) {
											bool bCheck = false;
											if (sqLeader.command == "move")
												bCheck = true;
											else if (sqLeader.command == "sneak")
												bCheck = true;
											else if (sqLeader.command == "advance")
												bCheck = true;
											else if (sqLeader.command == "enter")
												bCheck = true;
											if (bCheck) {
												SetMAIKA(sq.SrcGAIKA, sqGkAiDest, sqGkIn);
												if (bGoAround)
													if (sq.CalcGoAround()) {
														Sleep(100);
														continue;
													}
											}
										}
										distGoal = sqPos.Dist(sqGkAiDest.Center);
										if (distGoal >= 1500)
											if (distGoal < sqPos.Dist(gFlee.Center))
												gFlee = sqGkAiDest;
									}

								if (gFlee == 0)
									nFlee = 0;
								else if (gFlee == sqGkIn)
									if (enemy > 0)
										nFlee = 0;
									else if (nSqState == SS_Enter)
										nFlee = 0;

								if (nFlee != 0) {
									SetMAIKA(sq.SrcGAIKA, sqGkAiDest, sqGkIn);
									sq.SetState(SS_Flee);
									if (bDetachArmy)
										sqLeaderHero.DetachArmy();
									if (bCoward)
										sq.SendTo(gFlee, 1000);
									else
										sq.SendTo(gFlee, 1);
									Sleep(100);
									continue;
								}
							}
						}
						//==============================
						// TAKE ITEMS
						//==============================
						// User field is used to store the time when it drop an item to avoid picking it up again.
						if (bTakeItems && GetTime() > sqLeader.user)
							if (sq.TakeNearbyItems(sqLeader.sight)) {
								Sleep(100);
								continue;
							}
					}
				// =============================
				// UNIT ATTACHMENT
				// =============================
				// attach free units (without upgrades, enchantresses and Britain druids are almost useless in combat)
				if (nSqState != SS_Catapult && nSqState != SS_Train && !sqLeader.HasFreedom && (!sq.TestFlags(SF_PEACEFUL) || sqLeader.AsDruid.IsValid)) {
					bool bCheck = false;
					if (!sqLeader.IsHeirOf("IEnchantress")) {
						if (!sqLeader.IsHeirOf("BDruid"))
							bCheck = true;
						else if (IsResearched(aiPlayer, "Mass Heal"))
							bCheck = true;
						else if (IsResearched(aiPlayer, "Mass Invisibility"))
							bCheck = true;
					}
					else if (IsResearched(aiPlayer, "Cover of Mercy"))
						bCheck = true;
					else if (IsResearched(aiPlayer, "Restoration"))
						bCheck = true;
					if (bCheck) { 
						Unit bestHero;
						int bestEval;
						{  // scope to make sure SquadList is deallocated
							SquadList SL;
							Squad squad;  										// This squad can be different from the squad of the main Loop!
							int eval;
							sqGkIn.GetSquads(SL, AI_STAYING + AI_LEAVING, aiPlayer, AI_OWN);
							SL.Lock();
							for (; !SL.EOL; SL.Next()) {
								squad = SL.Cur;
								if (!squad.Leader.GetFlags(UNITFLAG_NOAI) && !squad.TestFlags(SF_NOAI) && squad.State != SS_Ruins && squad.State != SS_Flee) {
									eval = sq.EvalAttach(squad.Leader, min);  	// This squad.Leader is not the same from below (sqLeader). sq is from Main Loop, but it doesnt really matter lol.
									if (eval > 0) {  							// Looking for a hero between the squads in this for loop
										if (sqLeader.AsDruid().IsValid) {  		// Checking if the leader from the main loop squad is a Druid to assign to the Hero
											int nWant;
											nWant = squad.Size * nMagePerc / 100 - squad.Count("BaseMage");
											if (nWant > 0)
												eval = eval * nWant;
											else
												continue;
										}
										else if (sqLeader.IsRanged()) {  
											int nWant;
											nWant = squad.Size * 40 / 100 - squad.Count("Ranged");
											if (nWant > 0)
												eval = eval * nWant;
											else
												continue;
										}
										else if (sqLeader.IsHeirOf("Melee")) {
											int sqAvg;
											sqAvg = sq.Eval / sq.Size;
											if (sqAvg < eval / 2) 
												continue;  							// Don't attach if the main loop squad is too weak compared to the squad from the for loop	
										}
										// Unit skill and hero skill interactions influences eval.
										if (squad.Leader.AsHero().IsValid) {
											Hero heroToAttachTo;
											Unit unitsToBeAttached;

											heroToAttachTo = squad.Leader.AsHero();
											unitsToBeAttached = sqLeader.AsUnit();
											if (unitsToBeAttached.HasSpecial(offensive_tactics)) {
												int battleCryLvl;
												int leadershipLvl;
												
												battleCryLvl = heroToAttachTo.GetSkill(hsBattleCry);
												leadershipLvl = heroToAttachTo.GetSkill(hsLeadership);
												eval = eval * (1 + battleCryLvl / 20 + leadershipLvl / 40); 
											}
											if (unitsToBeAttached.HasSpecial(triple_strike)) {
												int assaultLvl;
												int teamAttackLvl;

												assaultLvl = heroToAttachTo.GetSkill(hsAssault);
												teamAttackLvl = heroToAttachTo.GetSkill(hsTeamAttack);
												eval = eval * (1 + assaultLvl / 10 + teamAttackLvl / 20);
											}
										}
										
										
										if (squad.Size > 1 && squad.Count("Horse") == squad.Size - 1 && sq.Count("Horse") != sq.Size)  // Army of only horses
											continue;  								
										if (eval > bestEval) {
											bestHero = squad.Leader;  				// This picks the best hero for min value
											bestEval = eval;		  				// Save eval for future iteration
										}
									}
								}
							}
							SL.Unlock();
						}
						if (bestEval > 0)  									// We found a hero previously...
							if (!bSqLeaderIsHero) {  						// The leader of the main loop squad is not a hero, meaning the squad is a free unit squad.
								bool bAttached = true;
								if (!bestHero.InHolder || sq.InHolder) {  	// Hero has to be inside a building
									if (nSqState == SS_Attach)
										if (!sq.InHolder)
											bAttached = false;
									sq.SetCmd(SS_Attach, 0, SF_ADVCHOOSER, "attach", bestHero);  // Yay, finally the attach
								}
								else if (bValidSetGkIn)
									sq.SetCmd(SS_Attach, 0, SF_ADVCHOOSER, "enter", setGkInCentralBuilding);
								if (bAttached) {
									Sleep(100);
									continue;
								}
							}
						else if (bestHero != sqLeaderHero)  				// The leader of the main loop squad is a hero, and we found a better hero to attach to.
							if (sq.Size > 1)
								if (sq.Size < 51)
									if (bestHero.InHolder)
										if (sqLeader.SameHolderAs(bestHero)) {  // check if transfering army is worth
											int ev;
											ev = bestHero.GetSquad().Size + sq.Size - 1;  // best hero squad size after attaching
											if (ev < min)
												ev = 100 - (min - ev);
											else
												ev -= min + 1;
											
											//  best hero eval after attaching > cur hero eval after detaching
											if (ev * (1 + bestHero.inherentlevel / 50) > (101 - min) * (1 + sqLeader.inherentlevel / 5)) {
												int squadAvgPower;

												squadAvgPower = sq.Eval / sq.Size;
												if (squadAvgPower > bestEval / 2) {
													sqLeaderHero.DetachArmy();
													Sleep(100);
													continue;
												}
											}
										}		
					}
				}
				if (nSqState == SS_Attach)
					if (sqLeader.command == "idle" || sqLeader.command == "stand_position") {
						sq.DelOrder();
						sq.ClrCmd(SS_IDLE, 0, SF_ADVCHOOSER);
						Sleep(100);
						continue;
					}
			}
			// =============================
			// POWERFUL SQUAD WITH NO HERO
			// =============================
			if (!bSqLeaderIsHero && !sqLeader.HasFreedom && !sq.TestFlags(SF_PEACEFUL) &&
				nSqState != SS_Flee && nSqState != SS_Catapult && nSqState != SS_Train && nSqState != SS_Attach && nSqState != SS_Ruins) {
				int avgUnitPower;
				avgUnitPower = sq.Eval / sq.Size;
				if (avgUnitPower >= 180) {
					int nHomeGaikaID;
					nHomeGaikaID  = EnvReadInt(aiPlayer, "HomeGaika");
					if (nHomeGaikaID > 0) {
						GAIKA gHome;
						gHome = GetGAIKA(nHomeGaikaID);
						if (sqGkIn != gHome) {
							sq.SetCmd(SS_Flee, 0, SF_ADVCHOOSER, "enter", gHome.settlement.GetCentralBuilding());
							Sleep(100);
							continue;
						}
						else if (!sq.InHolder && bValidSetGkIn) {
							if (setGkIn.IsStronghold) {
								sq.SetCmd(SS_Enter, 0, SF_ADVCHOOSER, "enter", setGkInCentralBuilding);
								Sleep(100);
								continue;
							}
						}
					}	
				}
			}
			// =============================
			// PEACEFUL UNITS
			// =============================
			if (sq.TestFlags(SF_PEACEFUL)) {  // make peaceful units go around if endangered or enter a stronghold if idle
				if (sqGkAiDest != sqGkIn)
					if (sqGkAiDest != sq.SrcGAIKA)
						if (sq.DestGAIKA == sqGkAiDest)
							if (sqLeader.command == "move" || sqLeader.command == "enter" || sqLeader.command == "unload") {
								sqGkIn.Eval(AI_STAYING, aiPlayer, own, ally, enemy, enemy_hidden);
								if (enemy > 1000)
									if (own + ally < 500) {
										SetMAIKA(sq.SrcGAIKA, sqGkAiDest, sqGkIn);
										if (bGoAround)
											if (sq.CalcGoAround()) {
												Sleep(100);
												continue;
											}
									}
							}
				if (sqLeader.command == "idle" || sqLeader.command == "stand_position")
					if (!sq.InHolder) {
						Settlement s;
						s = NearestStronghold(sqLeader.pos, aiPlayer);
						if (s.IsValid)
							if (sqLeader.AsWagon().IsValid)
								sqLeader.SetCommand("unload", s.GetCentralBuilding());
							else
								sq.SetCmd(SS_Enter, 0, SF_ADVCHOOSER, "enter", s.GetCentralBuilding());
					}
					else if (sqLeader.AsWagon().IsValid)
						if (sqLeader.InHolder)
							sqLeader.SetCommand("unload", sqLeader.GetHolderSett().GetCentralBuilding());
			}
			// =============================
			// HERO ARMY BALANCE
			// =============================	
			if (bSqLeaderIsHero)
				if (bValidSetGkIn)
					if (setGkIn.IsStronghold) {
						// Mage Balance
						int nBalance;
						nBalance = sq.Count("BaseMage") - sq.Size * nMagePerc / 100;
						if (nBalance > 0) {
							ObjList sqUnits;
							Unit u;
							int j;

							sqUnits = sq.Units;
							for (j = sqUnits.count - 1; j >= 0; j -= 1) {//note that i is used in the original script (which vauses wrong loop iterations)
								u = sqUnits[j].AsUnit();
								if (u.IsAlive)
									if (u.IsReligious)
										if (u.hero == sqLeaderHero) {
											u.DetachFrom(sqLeaderHero);
											nBalance -= 1;
											if (nBalance <= 0)
												break;
										}
							}
						}
					}
			Sleep(48);  		// without this instruction, the game crashes
		}  						// End of if statement (Squad initial validation)
		Sleep(2);
	}  							// End of for loop (AI Player squad iteration)
	Sleep(nSleepSquadMonitor);
}  								// End of while loop (Main infinite loop)