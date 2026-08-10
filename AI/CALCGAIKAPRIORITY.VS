//int, int aiPlayer, GAIKA g

Settlement set;
int nHomeDist, nAllyHomeDist, nEnemyHomeDist, nActualPerc = 10, nPlayerRace, independentBonus = 0;
rect rcMap;
bool playerCanSellFood, playerRaceIsGreece, playerAllowedGoldProduction, playerAllowedFoodTrade;

g.GetDistToPlayers(aiPlayer, nHomeDist, nAllyHomeDist, nEnemyHomeDist);

// I will check in the future for the nearest stronghold amount of food. More food less village prio and more trade outpost prio. Less food does the opposite.

set = g.settlement;
nPlayerRace = GetPlayerRace(aiPlayer);

playerAllowedGoldProduction = AIVar(aiPlayer, AIV_TradeGold) > 0;
playerAllowedFoodTrade = AIVar(aiPlayer, AIV_TradeFood) > 0;
playerRaceIsGreece = nPlayerRace == ImperialRome;
playerCanSellFood = nPlayerRace == Iberia || playerRaceIsGreece || nPlayerRace == Carthage;

// Explore is non-negociable.
if (!g.Explored(aiPlayer)) {
	nActualPerc = 100;
}
else if (set.IsValid) {
	if (set.IsStronghold) {
		nActualPerc = 80;
		independentBonus = 10;
	}
	else if (set.IsVillage) {
		nActualPerc = 65;
		independentBonus = 20;

		if (playerCanSellFood)
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

	// More aggressive
	if (g.Explored(aiPlayer) && set.IsEnemy(aiPlayer)) {
		nActualPerc += 10;
		if (g.Revealed(aiPlayer))
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