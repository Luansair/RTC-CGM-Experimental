//void, Settlement set

//called from ES_Stronghold, this script sets "nBuildType" and "nBuildCount" in the settlement environment (Rome, Gaul, Iberia, Britain, Egypt and Greece)

int nAssUnderFire;
bool bAssUnderFire;

nAssUnderFire = EnvReadInt(set, "AssUnderFire");//set in ES_Stronghold
bAssUnderFire = nAssUnderFire > 0;

// ======================
// ARMY BUILD CONDITIONS
// ======================
if (!bAssUnderFire)
	if (set.gold < 800 || (GetTime() < EnvReadInt(set, "nNextArmyBuildTime")))
		return;

if (set.population > GetConst("MinPopulation")) {
	int nRace, nType, nLastResearched, aiPlayer, nMilUnits;
	bool bBuildArmy, bRaceIsImperialRome = false, bRaceIsPunicRome = false, bRaceIsGreece = false;
	StrArray imperialOrPunicOrGreekOrGaulTechs, gaulImprovedTechs;
	IntArray valueUnitType, costUnitType, weightUnitType, uTypeIsRanged;

	nRace = set.GetCentralBuilding().race;
	// ===============================
	// TYPE -> UNIT TECH | MAPPER SETUP
	// ================================
	// The mapper is built depending on the race due to mods. UType won't work properly in these cases.
	// The mapper receives the type of unit (int) and returns the tech name (strTech).

	// Modded Race Checks
	if (nRace == RepublicanRome)
		if (IsResearched(set, "ChooseImperialRome"))
			bRaceIsImperialRome = true;
		else if (IsResearched(set, "ChoosePunicRome"))
			bRaceIsPunicRome = true;
		else
			imperialOrPunicOrGreekOrGaulTechs[1] = "Roman Archers";//this manages the final part about basic units if nothing has been chosen

	bRaceIsGreece = nRace == ImperialRome;

	// Techs selection
	if (bRaceIsImperialRome) {
		imperialOrPunicOrGreekOrGaulTechs[0] = "";
		imperialOrPunicOrGreekOrGaulTechs[1] = "Roman Archers";
		imperialOrPunicOrGreekOrGaulTechs[2] = "Roman Velit";
		imperialOrPunicOrGreekOrGaulTechs[3] = "Roman Principle";
		imperialOrPunicOrGreekOrGaulTechs[4] = "Roman Scout";
		imperialOrPunicOrGreekOrGaulTechs[5] = "Roman Praetorian";
	}
	else if (bRaceIsPunicRome) {
		imperialOrPunicOrGreekOrGaulTechs[0] = "";
		imperialOrPunicOrGreekOrGaulTechs[1] = "Roman Archers";
		imperialOrPunicOrGreekOrGaulTechs[2] = "Gladiator Shows";
		imperialOrPunicOrGreekOrGaulTechs[3] = "Roman Principle";
		imperialOrPunicOrGreekOrGaulTechs[4] = "Roman Scout";
		imperialOrPunicOrGreekOrGaulTechs[5] = "Roman Praetorian";
	}
	else if (bRaceIsGreece) {
		imperialOrPunicOrGreekOrGaulTechs[0] = "";
		imperialOrPunicOrGreekOrGaulTechs[1] = "Greek Archers";
		imperialOrPunicOrGreekOrGaulTechs[2] = "Greek Spears";
		imperialOrPunicOrGreekOrGaulTechs[3] = "Greek Horse Armor";
		imperialOrPunicOrGreekOrGaulTechs[4] = "Greek Royal Armor";
		imperialOrPunicOrGreekOrGaulTechs[5] = "Greek Chariot Wheels";
	}
	else if (nRace == Gaul) {  // using the original UTech function is not correct because it returns the level 2 research, which messes up checks on IsResearching/IsResearched
		imperialOrPunicOrGreekOrGaulTechs[0] = "";
		imperialOrPunicOrGreekOrGaulTechs[1] = "";
		imperialOrPunicOrGreekOrGaulTechs[2] = "Gaul Axeman";
		imperialOrPunicOrGreekOrGaulTechs[3] = "Gaul Spearman";
		imperialOrPunicOrGreekOrGaulTechs[4] = "Gaul Horseman";
		imperialOrPunicOrGreekOrGaulTechs[5] = "Gaul Woman Warrior";

		gaulImprovedTechs[0] = "";
		gaulImprovedTechs[1] = "";
		gaulImprovedTechs[2] = "Gaul Iron Axes";
		gaulImprovedTechs[3] = "Gaul Iron Spearheads";
		gaulImprovedTechs[4] = "Gaul Exceptional Horseshoes";
		gaulImprovedTechs[5] = "Gaul Fine Armor";
	}
	// =======================
	// UNIT PROPERTIES MAPPER
	// =======================
	// Maps the value (arbitrary), the cost and the class (ranged or not) to a number.
	// These numbers will be used later to calculate the weight.

	valueUnitType.resize(6);
	costUnitType.resize(6);
	weightUnitType.resize(6);
	uTypeIsRanged.resize(6);
	if (nRace == Britain) {
		valueUnitType[0] = 8;
		valueUnitType[1] = 12;
		valueUnitType[2] = 20;
		valueUnitType[3] = 20;
		valueUnitType[4] = 24;
		valueUnitType[5] = 32;

		costUnitType[0] = 50;
		costUnitType[1] = 60;
		costUnitType[2] = 150;
		costUnitType[3] = 150;
		costUnitType[4] = 150;
		costUnitType[5] = 400;

		uTypeIsRanged[1] = 1;
		uTypeIsRanged[4] = 1;
	}
	else if (bRaceIsImperialRome) {
		valueUnitType[0] = 12;
		valueUnitType[1] = 12;
		valueUnitType[2] = 16;
		valueUnitType[3] = 16;
		valueUnitType[4] = 12;
		valueUnitType[5] = 32;

		costUnitType[0] = 100;
		costUnitType[1] = 80;
		costUnitType[2] = 120;
		costUnitType[3] = 160;
		costUnitType[4] = 150;
		if (IsResearched(set, "Improve Praetorian Equipment"))
			costUnitType[5] = 320;
		else
			costUnitType[5] = 400;

		uTypeIsRanged[1] = 1;
		uTypeIsRanged[2] = 1;
	}
	else if (nRace == RepublicanRome) {
		valueUnitType[0] = 12;  // Hastatus
		valueUnitType[1] = 12;  // Roman Archer
		valueUnitType[2] = 20;  // Gladiator 
		valueUnitType[3] = 16;  // Princep 
		valueUnitType[4] = 12;  // Equite 
		valueUnitType[5] = 24;  // Triarus

		costUnitType[0] = 100;
		costUnitType[1] = 80;
		costUnitType[2] = 200;
		costUnitType[3] = 160;
		costUnitType[4] = 150;
		costUnitType[5] = 300;

		uTypeIsRanged[1] = 1;
	}
	else if (bRaceIsPunicRome) {
		valueUnitType[0] = 12;
		valueUnitType[1] = 12;
		valueUnitType[2] = 20;
		valueUnitType[3] = 16;
		valueUnitType[4] = 8;
		valueUnitType[5] = 32;

		costUnitType[0] = 100;
		costUnitType[1] = 80;
		costUnitType[2] = 200;
		costUnitType[3] = 160;
		costUnitType[4] = 150;
		costUnitType[5] = 420;

		uTypeIsRanged[1] = 1;
	}
	else if (nRace == Egypt) {
		valueUnitType[0] = 12;
		valueUnitType[1] = 12;
		valueUnitType[2] = 20;
		valueUnitType[3] = 24;
		valueUnitType[4] = 24;
		valueUnitType[5] = 24;

		costUnitType[0] = 70;
		costUnitType[1] = 60;
		costUnitType[2] = 160;
		costUnitType[3] = 260;
		costUnitType[4] = 260;
		costUnitType[5] = 240;

		uTypeIsRanged[1] = 1;
		uTypeIsRanged[2] = 1;
	}
	else if (nRace == Gaul) {
		valueUnitType[0] = 4;
		valueUnitType[1] = 8;
		valueUnitType[2] = 20;
		valueUnitType[3] = 16;
		valueUnitType[4] = 16;
		valueUnitType[5] = 24;

		costUnitType[0] = 60;
		costUnitType[1] = 50;
		costUnitType[2] = 160;
		costUnitType[3] = 120;
		costUnitType[4] = 170;
		costUnitType[5] = 240;

		uTypeIsRanged[1] = 1;
	}
	else if (bRaceIsGreece) {
		valueUnitType[0] = 12;
		valueUnitType[1] = 12;
		valueUnitType[2] = 20;
		valueUnitType[3] = 24;
		valueUnitType[4] = 28;
		valueUnitType[5] = 12;

		costUnitType[0] = 80;
		costUnitType[1] = 70;
		costUnitType[2] = 180;
		costUnitType[3] = 220;
		costUnitType[4] = 320;
		costUnitType[5] = 450;

		uTypeIsRanged[0] = 1;
		uTypeIsRanged[1] = 1;
	}
	else if (nRace == Iberia) {
		valueUnitType[0] = 8;
		valueUnitType[1] = 12;
		valueUnitType[2] = 16;
		valueUnitType[3] = 16;
		valueUnitType[4] = 24;
		valueUnitType[5] = 28;

		costUnitType[0] = 50;
		costUnitType[1] = 60;
		costUnitType[2] = 150;
		costUnitType[3] = 160;
		costUnitType[4] = 200;
		costUnitType[5] = 300;

		uTypeIsRanged[1] = 1;
		uTypeIsRanged[4] = 1;
	}
	
	
	nType = -1;
	// ======================================
	// UNIT RESEARCH CHECK AND TYPE RETRIEVAL
	// ======================================
	// If there was a research for a unit type it sets the type. If the previous call of this script left a unit research in progress, the script stops.

	nLastResearched = EnvReadInt(set, "nLastResearched");
	if (nLastResearched > 0) {
		str strTech;

		nType = nLastResearched - 1;  // Unit type retrieval from previous research.

		// Modded races unit tech retrieval.
		if (bRaceIsImperialRome) {
			strTech = imperialOrPunicOrGreekOrGaulTechs[nType];
			if (nType == 5)//RPraetorian
				if (IsResearched(set, strTech))
					strTech = "Improve Praetorian Equipment";
		}
		else if (bRaceIsPunicRome)
			strTech = imperialOrPunicOrGreekOrGaulTechs[nType];
		else if (bRaceIsGreece)
			strTech = imperialOrPunicOrGreekOrGaulTechs[nType];
		else if (nRace == Gaul) {
			strTech = imperialOrPunicOrGreekOrGaulTechs[nType];
			if (IsResearched(set, strTech))
				strTech = gaulImprovedTechs[nType];
		}
		else
			strTech = UTech(nType, nRace);

		// Current unit research check.
		if (IsResearching(set, strTech))//already researching for desired unit
			return;
		if (!IsResearched(set, strTech)) {//no research going -> reset army recruitment (it might happen because a human player with shared control stopped the research)
			nType = -1;
			nLastResearched = 0;
			EnvWriteInt(set, "nLastResearched", 0);
			EnvWriteInt(set, "nLastResearchedCounter", 0);
		}
	}


	aiPlayer = set.player;
	nMilUnits = MilUnits(aiPlayer);

	// ========================
	// ARMY BUILD DECISION
	// ========================
	if (bAssUnderFire)
		bBuildArmy = true;
	else if (EnvReadInt(set, "FreezeArmyBuild") > 0)
		bBuildArmy = false;
	else {
		int nArmyBuilds;
		nArmyBuilds = EnvReadInt(set, "nArmyBuilds");//set in ES_Stronghold
		if (nArmyBuilds <= 0)
			bBuildArmy = true;
		else {
			int pop_perc;
			if (nMilUnits <= 20)
				pop_perc = 30;
			else if (nArmyBuilds <= 10)
				pop_perc = 35;
			else
				pop_perc = 40;
			bBuildArmy = set.population >= set.max_population * pop_perc / 100;
		}
	}

	// ========================
	// ARMY BUILDING
	// ========================
	if (bBuildArmy) {
		int nCount = 10, nTotalRecruited, nUnitPickedType, nUnitPickedCounter, nMeleeCount, nRangedCount;

		// ================
		// PREVIOUS BATCH 
		// ================
		nMeleeCount = EnvReadInt(set, "nMeleeCount");
		nRangedCount = EnvReadInt(set, "nRangedCount"); 
		nTotalRecruited = nMeleeCount + nRangedCount;

		nUnitPickedCounter = EnvReadInt(set, "nUnitPickedCounter");
		nUnitPickedType = EnvReadInt(set, "nUnitPickedType") - 1;
		if (nUnitPickedCounter > 0) {
			nType = nUnitPickedType;
			nCount = MIN(10, nUnitPickedCounter);
		}

		// ========================
		// UNIT TYPE DECISION
		// ========================
		if (nType < 0) {  //check which units are desired in case nothing has already been decided previously
			int i;
			str strTech;
			// =========================
			// UNIT WEIGHT CONTEXT SETUP
			// =========================
			int nGold, nRoll, nPosibilities, sum, nBestHeroLevel; 

			// Economy context
			nGold = set.gold;

			// Present Hero context
			nBestHeroLevel = 0;
			{
				SquadList SL;
				set.GetGaika().GetSquads(SL, AI_STAYING, aiPlayer, AI_OWN);
				SL.Lock();
				for (; !SL.EOL; SL.Next()) {
					Hero h;
					h = SL.Cur.Leader.AsHero();
					if (h.IsValid)
						if (h.inherentlevel > nBestHeroLevel) {
							nBestHeroLevel = h.inherentlevel;
						}
				}
				SL.Unlock();
			}

			// =========================
			// UNIT WEIGHT CALCULATION
			// =========================

			for(i = 0; i <= 5; i += 1) {
				// Weight influenced by settlement gold
				if(nGold > costUnitType[i] * 20) 
					weightUnitType[i] = valueUnitType[i] * 4;
				else if (nGold > costUnitType[i] * 10) 
					weightUnitType[i] = valueUnitType[i] * 2;
				else if (nGold > costUnitType[i] * 5)
					weightUnitType[i] = valueUnitType[i];
				else
					weightUnitType[i] = valueUnitType[i] / 2;

				// Weight influenced by hero level
				weightUnitType[i] += valueUnitType[i] * nBestHeroLevel / 10;

				// Check which units type should consider
				if (nRangedCount > nMeleeCount && uTypeIsRanged[i] == 1)
					weightUnitType[i] = weightUnitType[i] / 2;
				else if (nMeleeCount > nRangedCount && uTypeIsRanged[i] == 0)
					weightUnitType[i] = weightUnitType[i] / 2;
				if (nUnitPickedType == i)
					weightUnitType[i] = weightUnitType[i] / 2;
			}

			// Posibilities calculation
			for(i = 0; i <= 5; i += 1) {
				nPosibilities += weightUnitType[i];
			}

			// Nothing to recruit, lets wait...
			if (nPosibilities <= 0) {
				EnvWriteInt(set, "nNextArmyBuildTime", GetTime() + 30000 + rand(30001));
				return;
			}

			// Roll and type selection
			nRoll = rand(nPosibilities);
			for(i = 0; i <= 5; i += 1) {
				sum += weightUnitType[i];
				if (sum > nRoll) {
					nType = i;
					break;
				}
			}

			// We picked a nType. Let's pick an amount.
			nUnitPickedCounter = 10 + rand(11);
			nUnitPickedType = nType;
			
			// =======================
			// UNIT TECH PICK
			// =======================
			// Picks the tech for the unit that wants to recruit in case it is not researched.

			// Specific case that has two researches for the same unit, the praetorian.
			if (bRaceIsImperialRome) {
				strTech = imperialOrPunicOrGreekOrGaulTechs[nType];
				if (nType == 5)//RPraetorian
					if (rand(3) > 0)
						if (IsResearched(set, strTech))
							strTech = "Improve Praetorian Equipment";
			}

			// Modded races
			else if (bRaceIsPunicRome)
				strTech = imperialOrPunicOrGreekOrGaulTechs[nType];
			else if (bRaceIsGreece)
				strTech = imperialOrPunicOrGreekOrGaulTechs[nType];

			// Like before, but has two researches but for every unit.
			else if (nRace == Gaul) {
				strTech = imperialOrPunicOrGreekOrGaulTechs[nType];
				if (strTech != "")
					if (rand(3) == 0)
						if (IsResearched(set, strTech))
							strTech = gaulImprovedTechs[nType];
			}

			// Normal scenario
			else
				strTech = UTech(nType, nRace);

			// =======================
			// UNIT TECH RESEARCH
			// =======================
			// Research the tech for the unit that want to be produced in case it is not researched.

			if (strTech != "") {
				if (!IsResearched(set, strTech)) {
					int j, k, r;
					i = EnvReadInt(set, "nArmyTechTime");

					// Wait tactic script execution (2-4 min)
					if (i <= 0) { 
						i = GetTime() + 120000 + rand(120001);
						EnvWriteInt(set, "nArmyTechTime", i);
					}

					// Can be researched?
					if (GetTime() >= i) {
						if (set.CanResearch(strTech))
							if (set.CanAfford(strTech)) {  // using ESH_NeedTech is not good because it might set FreezeArmyBuild
								int gold, food;
								if (GetCmdCost(strTech, gold, food)) {  //recruit at least 10-20 units (4-8 in the case of 5-HChariot) of the researched type
									set.SpentGoldOnTech(gold + food / 2);
									set.Research(strTech);
									EnvWriteInt(set, "nArmyTechTime", GetTime() + 120000 + rand(120001));
									EnvWriteInt(set, "nLastResearchedCounter", nUnitPickedCounter);
									EnvWriteInt(set, "nLastResearched", nType + 1);
									return;
								}
							}
					}
        			return;
				}
			}	
		}
		// =======================
		// CHARIOT UNIT AMOUNT
		// =======================
		if (bRaceIsGreece)
			if (nType == 5)  // In case of 5-HChariot, reduce the amount of units to recruit (4-6 instead of 10) because the cost is very high and they are not attachable to heroes
				nCount = rand(3) + 2;
		
		// =========================
		// ENVIRONMENT VARIABLES SET
		// =========================
		if (nType >= 0) {
			

			if (nType == nLastResearched - 1) {
				int nLastResearchedCounter;
				nLastResearchedCounter = EnvReadInt(set, "nLastResearchedCounter");
				nCount = MIN(nCount, nLastResearchedCounter);
				nLastResearchedCounter -= MIN(nCount, nLastResearchedCounter);
				EnvWriteInt(set, "nLastResearchedCounter", nLastResearchedCounter);
				if (nLastResearchedCounter <= 0)
					EnvWriteInt(set, "nLastResearched", 0);
			} else {
				nUnitPickedCounter -= nCount;
				EnvWriteInt(set, "nUnitPickedCounter", MAX(0, nUnitPickedCounter));
				EnvWriteInt(set, "nUnitPickedType", nType + 1);
			}

			// For Recruitment
			EnvWriteInt(set, "nBuildType", nType);
			EnvWriteInt(set, "nBuildCount", nCount);

			if (uTypeIsRanged[nType] == 1)
				EnvWriteInt(set, "nRangedCount", nRangedCount + nCount);
			else
				EnvWriteInt(set, "nMeleeCount", nMeleeCount + nCount);

			if(nTotalRecruited + nCount >= 100 + rand(100)) {
				int nGameTimeInSec, nGameTimeInMin, nTimeToWait;

				nGameTimeInSec = GetTime() / 1000;
				nGameTimeInMin = nGameTimeInSec / 60;

				if (set.gold > 8000)
					nTimeToWait = 0;
				else if (nGameTimeInMin < 10)
					nTimeToWait = 10000;
				else
					nTimeToWait = 30000;

				EnvWriteInt(set, "nMeleeCount", 0);
				EnvWriteInt(set, "nRangedCount", 0);
				EnvWriteInt(set, "nNextArmyBuildTime", GetTime() + nTimeToWait + rand(nTimeToWait));
			}
		}

		

	}  // Endif - bBuildArmy
}