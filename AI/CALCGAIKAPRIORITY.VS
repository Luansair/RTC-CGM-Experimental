//int, int aiPlayer, GAIKA g

Settlement set, nearSh;
int nHomeDist, nAllyHomeDist, nEnemyHomeDist, nActualPerc = 10, nPlayerRace, nResult, nDistFactor, nReturn;
int independentBonus = 0, foodNeedBonus, popNeedBonus;
rect rcMap;
bool playerCanSellFood, playerRaceIsGreece, playerAllowedGoldProduction, playerAllowedFoodTrade, inCrisis;
bool allowLogging = false;

g.GetDistToPlayers(aiPlayer, nHomeDist, nAllyHomeDist, nEnemyHomeDist);

set = g.settlement;
nearSh = NearestStronghold(g.Center, aiPlayer);
nPlayerRace = GetPlayerRace(aiPlayer);

foodNeedBonus = (3000 - MIN(3000, nearSh.food)) / 100;
popNeedBonus = (nearSh.max_population - nearSh.population) * 1 / 5;

inCrisis = nearSh.population < nearSh.max_population / 5 || nearSh.food < 250;
playerAllowedGoldProduction = AIVar(aiPlayer, AIV_TradeGold) > 0;
playerAllowedFoodTrade = AIVar(aiPlayer, AIV_TradeFood) > 0;
playerRaceIsGreece = nPlayerRace == ImperialRome;
playerCanSellFood = nPlayerRace == Iberia || playerRaceIsGreece || nPlayerRace == Carthage;

// Exploration is a priority unless in crisis.
if (!g.Explored(aiPlayer) && g.CanExplore(aiPlayer) && !IsWaterLsa(g.LSA) && !inCrisis) {
	nActualPerc = 100;
}
else if (set.IsValid) {
	if (set.IsStronghold) {
		nActualPerc = 90;
		independentBonus = 10;
	}
	else if (set.IsVillage) {
		nActualPerc = 55;
		independentBonus = 20;

		nActualPerc += foodNeedBonus + popNeedBonus;

		if (playerCanSellFood)
			nActualPerc += 15;
		
		if (nPlayerRace == Germany)
			nActualPerc += 10;
	}
	else if (set.IsTTent) {
		nActualPerc = 45;
		independentBonus = 20;
	}
	else if (set.IsOutpost) {
		bool setCanTradeFood, setCanProduceGold;
		int nRace;

		nActualPerc = 50;
		independentBonus = 10;
		nRace = set.GetCentralBuilding().race;
		setCanProduceGold = nRace == RepublicanRome || nRace == Egypt;
		setCanTradeFood = nRace == Gaul || nRace == Germany;

		if (playerAllowedGoldProduction && setCanProduceGold) {
			nActualPerc += 10;
			if (!playerCanSellFood)
				nActualPerc += 10;
		}
		if (playerAllowedFoodTrade && setCanTradeFood && !playerCanSellFood && nearSh.food > 3000 && nPlayerRace != Germany) {
			nActualPerc += 20;
		}
	}
	else if (set.IsShipyard) {
		nActualPerc = 40;
		independentBonus = 15;
	}

	if (set.IsIndependent) {
		nActualPerc += independentBonus;
	}

	if (g.Explored(aiPlayer) && set.IsEnemy(aiPlayer)) {
		nActualPerc += 10;
		if (g.Revealed(aiPlayer))
			nActualPerc += 5;
	}
	else if (set.IsOwn(aiPlayer)) {
		nActualPerc += 20;
	}
	else if (set.IsAlly(aiPlayer)) {
		nActualPerc += 5;
	}

	if (!set.IsVillage) {
		nActualPerc -= (foodNeedBonus + popNeedBonus) / 3;
	}
}

rcMap = GetMapRect();

nDistFactor = MaxGAIKAPriority * (100 - nHomeDist * 100 / Dist(Point(rcMap.left, rcMap.top), Point(rcMap.right, rcMap.bottom))) / 100;
nResult = nActualPerc * nDistFactor / 100;
nReturn = MAX(1, MIN(MaxGAIKAPriority - 1, nResult));

// ============ LOGGING ==============
if (allowLogging) {
	int lastLog, lastPlayerLog, logTimer;
	lastLog = EnvReadInt("anyPrioCalcLogTime");
	logTimer = 1000;
	if (GetTime() > lastLog + logTimer) {
		str setType, setOwner;
		int nPlayerCanSellFood, nInCrisis, nExplored, nRevealed;

		if (set.IsValid) {
			if (set.IsStronghold) setType = "Stronghold";
			else if (set.IsVillage) setType = "Village";
			else if (set.IsTTent) setType = "TTent";
			else if (set.IsOutpost) setType = "Outpost";
			else if (set.IsShipyard) setType = "Shipyard";
			else setType = "Other";
			if (set.IsIndependent) setOwner = "Independent";
			else if (set.IsOwn(aiPlayer)) setOwner = "Own";
			else if (set.IsAlly(aiPlayer)) setOwner = "Ally";
			else if (set.IsEnemy(aiPlayer)) setOwner = "Enemy";
			else setOwner = "Unknown";
		} else {
			setType = "NoSettlement";
			setOwner = "-";
		}
		if (playerCanSellFood) nPlayerCanSellFood = 1;
		else nPlayerCanSellFood = 0;
		if (inCrisis) nInCrisis = 1;
		else nInCrisis = 0;
		if (g.Explored(aiPlayer)) nExplored = 1;
		else nExplored = 0;
		if (g.Revealed(aiPlayer)) nRevealed = 1;
		else nRevealed = 0;
		AppendFile("Data/useful-info/AI_PRIORITY.log",
			"t=" + GetTime() + " P" + aiPlayer + " g=" + g.ID +
			" set=" + setType + "(" + setOwner + ")" +
			" Shfood=" + nearSh.food + " Shpop=" + nearSh.population + "/" + nearSh.max_population +
			" foodBonus=" + foodNeedBonus + " popBonus=" + popNeedBonus +
			" canSellFood=" + nPlayerCanSellFood + " inCrisis=" + nInCrisis +
			" nHomeDist=" + nHomeDist + " nActualPerc=" + nActualPerc +
			" distFactor=" + nDistFactor + " result=" + nResult + " return=" + nReturn +
			" explored=" + nExplored + " revealed=" + nRevealed + "\n");
		EnvWriteInt("anyPrioCalcLogTime", GetTime());
	}
}

return nReturn;
