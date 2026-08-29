//void, Settlement set

int aiPlayer, min_pop, pop_group, nSleepES, nRectLongestSide, nDist, nBestDist;
bool bUseForts, bCanDrain;
str cmd;
Building hall;
Settlement stronghold;
point ptDummy;
Obj objDummy;

aiPlayer = set.player;
min_pop = GetConst("MinPopulation");
pop_group = GetConst("PopGroup");
nSleepES = AIVar(aiPlayer, AIV_Sleep_ES);
if (AIVar(aiPlayer, AIV_VillageDrain) != 0) {
	rect rc;
	rc = GetMapRect();
	nRectLongestSide = MAX(rc.width, rc.height);
}
bUseForts = AIVar(aiPlayer, AIV_UseForts) != 0;

hall = set.GetCentralBuilding();
if (hall.race == ImperialRome)//Greece
	cmd = "trainpeasanth";
else
	cmd = "trainpeasant" + hall.raceStrPrefLow;

EnvWriteInt(set, "ES_VillageRepopulateTime", GetTime() + 120000 + rand(120001));

while (set.player == aiPlayer) {
	if (hall.IsBroken || set.population < min_pop) {
		if (GetTime() >= EnvReadInt(set, "ES_VillageRepopulateTime"))
			if (Intersect(ObjsInRange(hall, "Military", 1500), EnemyObjs(aiPlayer, "Military")).IsEmpty) {
				hall.ExecCmd("repair village ai", ptDummy, objDummy, true);//using false does not work because it does not overwrite the "broken" command
				while (hall.command == "repopulate")
					Sleep(nSleepES);
				EnvWriteInt(set, "ES_VillageRepopulateTime", GetTime() + 120000 + rand(120001));
			}
	}
	else {
		// ========= PICK BEST STRONGHOLD =========
		ObjList olSh;
		int i, nMaxDistance, nBestScore;
		rect rcMap;
		Settlement bestSh;

		rcMap = GetMapRect();
		nMaxDistance = Dist(Point(rcMap.left, rcMap.top), Point(rcMap.right, rcMap.bottom));
		nBestScore = -1000000;

		olSh = GetSettlements("BaseTownhall", aiPlayer);

		for (i = olSh.count - 1; i >= 0; i  -= 1) {
			Settlement sCandidate;
			Building candidateBuilding;
			int nScore, nFoodScore, nPopScore, nDistToVillage, nDistPerc;

			candidateBuilding = olSh[i].AsBuilding();
			if (!candidateBuilding.IsValid) {
				continue;
			}
			sCandidate = candidateBuilding.settlement;
			if (!sCandidate.IsValid) {
				continue;
			}
			if (!sCandidate.IsStronghold) {
				continue;
			}
			if (sCandidate.LandLsa() != set.LandLsa()) {
				continue;
			}
			// +10 for each 500 food below 5000. -10 for each 500 food above 8000.
			nFoodScore = (5000 - MIN(5000, sCandidate.food)) / 50 - (8000 - MAX(8000, sCandidate.food)) / 50;

			// +2 for each missing % of population
			nPopScore = 200 * (sCandidate.max_population - MIN(sCandidate.max_population, sCandidate.population)) / sCandidate.max_population;

			nDistToVillage = set.GetCentralBuilding().DistTo(candidateBuilding);
			nDistPerc = nDistToVillage * 100 / nMaxDistance;
			nScore = (100 + nFoodScore + nPopScore) * (100 - nDistPerc) / 100;

			if (nScore > nBestScore) {
				nBestScore = nScore;
				bestSh = sCandidate;
			}
		}
		if (bestSh.IsValid) {
			stronghold = bestSh;
		}
		else {
			stronghold = set.BestToSupply;  // it returns the nearest owned stronghold
		}
		if (stronghold.IsValid) {
			nDist = hall.DistTo(stronghold.GetCentralBuilding());
			if (nDist != nBestDist) {
				nBestDist = nDist;
				EnvWriteInt(set, "ES_SuppliedStronghold", nDist);
			}
			if (hall.command == "idle") {
				if (!(set.supplied == stronghold))//the != operator does not exist for settlements
					set.StartSupplyFood(stronghold);

				if (set.population - pop_group >= min_pop) {
					bCanDrain = false;

					if (set.population >= set.max_population)
						bCanDrain = true;
					else if (nRectLongestSide > 0) {
						int nShPopPerc, nVillPopPerc, nDistPerc, nPopNeed, nDrainChance, nExtraShPop, nShFoodPerc, nFoodNeed, nMissingVillPopPerc;

						nShPopPerc =  stronghold.population * 100 / stronghold.max_population;
						nShFoodPerc = stronghold.food * 100 / 5000;
						nVillPopPerc = set.population * 100 / set.max_population;
						nMissingVillPopPerc = 100 - nVillPopPerc;
						nDistPerc = nDist * 100 / nRectLongestSide;
						nExtraShPop = MIN(40, (MAX(8000, stronghold.food) - 8000) / 50);

						nPopNeed = MAX(0, 90 + nExtraShPop - nShPopPerc);
						nFoodNeed = 100 - nShFoodPerc;

						nDrainChance = nPopNeed * 2 + nVillPopPerc * 2 / 3 + nDistPerc * 2 - nFoodNeed * 3 / 2 - nMissingVillPopPerc * 1 / 3;

						if (nDrainChance > rand(250)) {
							bCanDrain = true;
						}
					}
						

					if (bCanDrain) {
						if (bUseForts) {
							Building outpost;
							outpost = EnvReadObj(set, "ES_SuppliedOutpost").AsBuilding();
							if (outpost.IsValid) {
								Settlement setOutpost;
								bool supplyOutpost = false;
								setOutpost = outpost.settlement;
								if (outpost.player == aiPlayer)
									if (outpost.race == Carthage) {
										if (hall == EnvReadObj(setOutpost, "ES_SupplierVillage").AsBuilding())
											supplyOutpost = true;
									}
									else if (outpost.race == ImperialRome)//Greece
										if (hall == EnvReadObj(setOutpost, "ES_SupplierVillage").AsBuilding())
											supplyOutpost = true;
								if (supplyOutpost) {
									ObjList ol;
									Obj o;
									int i, peasants;
									ol = setOutpost.Units;
									for (i = ol.count - 1; i >= 0; i -= 1) {
										o = ol[i];
										if (o.IsAlive)
											if (o.IsPeasant) {
												peasants += 1;
												if (peasants >= 5)
													break;
											}
									}
									if (peasants < 5)
										set.StartSupplyFood(setOutpost);
								}
								else
									EnvWriteObj(set, "ES_SuppliedOutpost", objDummy);
							}
						}
						hall.ExecCmd(cmd, ptDummy, objDummy, false);
					}
				}
			}
		}
		else
			set.StopSupply();
	}
	Sleep(nSleepES);
}