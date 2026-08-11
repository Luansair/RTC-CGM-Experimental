//int, int aiPlayer, GAIKA g

Settlement set, nearSh;
int nHomeDist, nAllyHomeDist, nEnemyHomeDist, nActualPerc = 10, nPlayerRace;
int independentBonus = 0, foodNeedBonus, popNeedBonus;
rect rcMap;
bool playerCanSellFood, playerRaceIsGreece, playerAllowedGoldProduction, playerAllowedFoodTrade, inCrisis;

g.GetDistToPlayers(aiPlayer, nHomeDist, nAllyHomeDist, nEnemyHomeDist);

// I may add 3 villages per stronghold. Get number of strongholds and villages. Each missing is +10 prio
set = g.settlement;
nearSh = NearestStronghold(g.Center, aiPlayer);
nPlayerRace = GetPlayerRace(aiPlayer);

foodNeedBonus = (3000 - MIN(2000, nearSh.food)) / 75;
popNeedBonus = (nearSh.max_population - nearSh.population) * 2 / 5;

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
		nActualPerc = 80;
		independentBonus = 10;
	}
	else if (set.IsVillage) {
		nActualPerc = 55;
		independentBonus = 20;

		nActualPerc += foodNeedBonus + popNeedBonus;

		if (playerCanSellFood)
			nActualPerc += 10;
		
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
		if (playerAllowedFoodTrade && setCanTradeFood && !playerCanSellFood) {
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
}

rcMap = GetMapRect();

return MAX(
	1,
	MIN(
		MaxGAIKAPriority - 1,
		nActualPerc * (MaxGAIKAPriority * (100 - nHomeDist * 100 / Dist(Point(rcMap.left, rcMap.top), Point(rcMap.right, rcMap.bottom))) / 100) / 100
	)
);//it must be greater than 0