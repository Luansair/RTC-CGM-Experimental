//void, Settlement set

//called from ES_Stronghold, this script sets "nBuildType" and "nBuildCount" in the settlement environment (Rome, Gaul, Iberia, Britain, Egypt and Greece)

int nAssUnderFire;
bool bAssUnderFire;
StrArray typeClass;

nAssUnderFire = EnvReadInt(set, "AssUnderFire");//set in ES_Stronghold
bAssUnderFire = nAssUnderFire > 0;

typeClass.resize(6);

// ======================
// ARMY BUILD CONDITIONS
// ======================
if (!bAssUnderFire)
	if (set.gold < 800)
		return;

if (set.population > GetConst("MinPopulation")) {
	int nRace, nType, nLastResearched, aiPlayer, nMilUnits;
	bool bBuildArmy, bRaceIsImperialRome = false, bRaceIsPunicRome = false, bRaceIsGreece = false;
	StrArray imperialOrPunicOrGreekOrGaulTechs, gaulImprovedTechs;

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
	// ===============================
	// TYPE -> CLASS | MAPPER SETUP
	// ================================
	

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
		int nCount = 10;

		// ========================
		// UNIT TYPE DECISION
		// ========================
		if (nType < 0) {//check which units are desired in case nothing has already been decided previously
			int i;
			str strTech;

			// Type 5 weight based on gold
			i = set.gold;
			if (i >= 5000)//if there is a lot of gold, give higher chance to the heavy unit (5 - RTribune, RPraetorian(Punic), GWomanWarrior, IEliteGuard, BHighlander, EGuardian, HChariot)
				i = 8;
			else if (i >= 3000)
				i = 4;
			else
				i = 2;
			
			// Type pick. Worst case scenario has 50% + 1/6 chance to pick type 5. Best case has 7/8 + 1/6.
			if (rand(i) == 0)
				nType = rand(6);  // Equiprobable
			else
				nType = 5;

			// After picking a type and depending on race change the type.
			if (nType == 5)  // 5-HChariot and 5-EGuardian have a chance to be replaced by 4-HHypaspista (50%) or 3-EAnubisWarrior/4-EHorusWarrior (66%)
				if (bRaceIsGreece) {  
					if (rand(2) == 0)
						nType = 4;
				}
				// Egypt type 5 is not "the best" like other races. It can switch to anubis/horus warriors.
				else if (nRace == Egypt)
					if (rand(3) > 0)
						nType = rand(2) + 3;

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

			if (strTech != "")
				if (!IsResearched(set, strTech)) {
					int j, k, r;
					i = EnvReadInt(set, "nArmyTechTime");

					// Wait tactic script execution (2-4 min)
					if (i <= 0) { 
						i = GetTime() + 120000 + rand(120001);
						EnvWriteInt(set, "nArmyTechTime", i);
					}

					// Can be researched case.
					if (GetTime() >= i)
						if (set.CanResearch(strTech))
							if (set.CanAfford(strTech)) {  // using ESH_NeedTech is not good because it might set FreezeArmyBuild
								int gold, food;
								if (GetCmdCost(strTech, gold, food)) {  //recruit at least 25-40 units (8-12 in the case of 5-HChariot) of the researched type
									set.SpentGoldOnTech(gold + food / 2);
									set.Research(strTech);
									if (bRaceIsGreece)  
										if (nType == 5)
											i = rand(5) + 8;
										else
											i = rand(16) + 25;
									else
										i = rand(16) + 25;
									EnvWriteInt(set, "nLastResearched", nType + 1);
									EnvWriteInt(set, "nLastResearchedCounter", i);
									EnvWriteInt(set, "nArmyTechTime", GetTime() + 120000 + rand(120001));
									return;
								}
							}

					// Cannot be researched, change the unit type and select another tech.
					nType = -1;
					if (nRace == RepublicanRome) {
						k = 1;
						r = 5;
					}
					else if (bRaceIsGreece) {  
						k = 1;
						r = 5;
					}
					else if (nRace == Egypt) {
						k = 3;
						r = 2;
					}
					else {
						k = 2;
						r = 4;
					}
					for (i = 0; i < 5; i += 1) {  //  no research is going, choose another advanced unit randomly (max 5 attempts)
						j = rand(r) + k;  //1-5 or 3-4 or 2-5, depending on the race
						if (bRaceIsImperialRome) {
							strTech = imperialOrPunicOrGreekOrGaulTechs[j];
							if (j == 5)
								if (rand(3) > 0)
									strTech = "Improve Praetorian Equipment";
						}
						else if (bRaceIsPunicRome)
							strTech = imperialOrPunicOrGreekOrGaulTechs[j];
						else if (bRaceIsGreece) {
							if (j == 5)
								if (rand(2) == 0)//5-HChariot has a 50% chance to be replaced by 4-HHypaspista
									j = 4;
							strTech = imperialOrPunicOrGreekOrGaulTechs[j];
						}
						else if (nRace == Gaul) {
							strTech = imperialOrPunicOrGreekOrGaulTechs[j];
							if (rand(3) == 0)
								strTech = gaulImprovedTechs[j];
						}
						else
							strTech = UTech(j, nRace);
						if (IsResearched(set, strTech)) {  // note that units with 2 researches have reduced chance to be chosen if only the first has been completed
							nType = j;
							break;
						}
					}
				}
		}

		// Very small chance to change idea and recruit basic units
		if (rand(15) == 0) 
			nType = -1;
		
		// =======================
		// NOTHING CHOSEN
		// =======================
		// If nothing has been chosen, recruit basic units (type 0 or 1).

		if (nType < 0)
			if (rand(2) == 0)
				nType = 0;
			else if (nRace == RepublicanRome)
				if (IsResearched(set, imperialOrPunicOrGreekOrGaulTechs[1]))
					nType = 1;
				else
					nType = 0;
			else if (bRaceIsGreece)
				if (IsResearched(set, imperialOrPunicOrGreekOrGaulTechs[1]))
					nType = 1;
				else
					nType = 0;
			else
				nType = 1;

		// =======================
		// CHARIOT UNIT AMOUNT
		// =======================
		if (bRaceIsGreece)
			if (nType == 5)  // In case of 5-HChariot, reduce the amount of units to recruit (4-6 instead of 10) because the cost is very high and they are not attachable to heroes
				nCount = rand(3) + 4;
		
		// =========================
		// ENVIRONMENT VARIABLES SET
		// =========================

		// For Research
		if (nType == nLastResearched - 1) {
			int nLastResearchedCounter;
			nLastResearchedCounter = EnvReadInt(set, "nLastResearchedCounter");
			nLastResearchedCounter -= MIN(nCount, nLastResearchedCounter);
			EnvWriteInt(set, "nLastResearchedCounter", nLastResearchedCounter);
			if (nLastResearchedCounter <= 0)
				EnvWriteInt(set, "nLastResearched", 0);
		}

		// For Recruitment
		EnvWriteInt(set, "nBuildType", nType);
		EnvWriteInt(set, "nBuildCount", nCount);
	}
}