//int, GAIKA g, int aiPlayer, bool bMin, int own, int ally, int enemy

// Given the parameters, this script returns the army needed for a gaika for the AI player.
// The value returned should be deterministic, so use of rand is not advisable.
// Unpredictable behaviour should be done outside this script. It doesn't make sense to make this calculation unpredictable.
// Some values are arbitrary. May change in the future if deem so.
// These calculations are independent of whatever the caller does. It doesn't affect gaika priorities.
// Exaggerated army needs may result in big armies going to empty spaces or freezing the AI. 
// This script attempts to cover all scenarios.

// Parameters:
//   g        = GAIKA dest (the zone to evaluate)
//   aiPlayer 
//   bMin     = true → MinNeed, false → MaxNeed
//   own      = own power in the GAIKA (the caller should have calculated it with Gaika::Eval)
//   ally     = ally power in the GAIKA (the caller should have calculated it with Gaika::Eval)
//   enemy    = enemy power in the GAIKA (the caller should have calculated it with Gaika::Eval. This includes enemies in holder)

// ======
// SETUP
// ======
// 
// There are some unused booleans that are for a future feature to give IA more personality.

Settlement settlement;
bool gaikaHasSettlement, isSetStronghold, gaikaHasEnemies, isAIPreventive, especulateForces, needExplorers, anticipateEnemyReinforcements, enableLogging;
int nTime, nEnemyNeighbors, nMaxNeed, nMinNeed, importanceMultiplier, originalEnemyEval;

enableLogging = false;
originalEnemyEval = enemy;

settlement =  g.settlement;
gaikaHasSettlement = false;
isSetStronghold = false;

isAIPreventive = false;  // try to prevents its outposts from being captured. Defends prematurely
especulateForces = false;  // from the gaika itself when enemy == 0. Consider distance and enemy military power.
gaikaHasEnemies = true;
needExplorers = false;
anticipateEnemyReinforcements = true;  // from gaikas around
// Avoid early returns, easier to test but "if nesting" may make code harder to read.

nMinNeed = 0;
nMaxNeed = 0;

if (settlement.IsValid) {
	gaikaHasSettlement = true;
	if (settlement.IsStronghold)
		isSetStronghold = true;
}

// ===================
// NEED ARMY DECISION
// ===================
// This sections analyzes the context of the gaika to take a decision.
// Depending of these decisions further calculations may be needed.

if (enemy <= 0) 
	gaikaHasEnemies = false;
else 
	gaikaHasEnemies = true;

if (!g.Explored(aiPlayer) && g.CanExplore(aiPlayer) && !IsWaterLsa(g.LSA))
	needExplorers = true;
else
	needExplorers = false;

if(gaikaHasSettlement) {
	if (settlement.IsIndependent) {
		anticipateEnemyReinforcements = false;
		if (!gaikaHasEnemies) {
			needExplorers = true;
		}
	} else {
		anticipateEnemyReinforcements  = true;
		if (settlement.IsEnemy(aiPlayer) && enemy <= 1000)
			nMaxNeed += 15000;
	}
}

// =====================
// ARMY NEED CALCULATION
// =====================
// Calculates min and max army need depending on the context previously analysed.

// Exploration has a priority over sending complete armies to unexplored gaikas.
// Exploration mean sending free units or small squads. 
if (needExplorers) {
	nMinNeed = 1;
	nMaxNeed = 1250;
}
else if (gaikaHasEnemies) {
	if (anticipateEnemyReinforcements) {
		int ownNeighborsEval, allyNeighborsEval, enemyNeighborsEval;

		g.EvalNeighbors(AI_STAYING + AI_COMING, aiPlayer, ownNeighborsEval, allyNeighborsEval, enemyNeighborsEval, true);

		if (enemyNeighborsEval > ownNeighborsEval)
			enemy += (enemyNeighborsEval - ownNeighborsEval) * 2 / 3;
	}
	nMinNeed += enemy * 3 / 2;
	nMaxNeed += enemy * 4;
}

// =============
// LOGGING INFO
// =============

if (enableLogging) {
	int lastLog, logTimer;
	
	lastLog = EnvReadInt(aiPlayer, "armyNeedLogTime");
	logTimer = 2000 + aiPlayer * 200;
	
	if (GetTime() > lastLog + logTimer) {
		int minutes, seconds, miliseconds, hour, minute, second, milisecond;
		str gaikaPos, explored, revealed, limit, settlement, setType, gameTime;

		gaikaPos = "(" + g.Center.x + "," + g.Center.y + ")";
		miliseconds = GetTime();
		milisecond = miliseconds % 1000;
		seconds = GetTime() / 1000;
		second = seconds % 60;
		minutes = seconds / 60;
		minute = minutes % 60;
		hour = minutes / 60;

		gameTime = ""+ hour + ":" + minute + ":" + second;

		if (g.Explored(aiPlayer)) 
			explored = "explored";
		else
			explored = "not explored";

		if (g.Revealed(aiPlayer))
			revealed = "revealed";
		else
			revealed = "not revealed";

		if (bMin)
			limit = "minimum value";
		else
			limit = "maximum value";

		if (gaikaHasSettlement) {

			settlement = "has a Settlement";

			if (g.settlement.IsIndependent) {
				if (g.settlement.IsIndependentGuarded)
					settlement = "has an Independent Settlement Guarded";
				else 
					settlement = "has an Independent Settlement";
			}
			else if (g.settlement.IsEnemy(aiPlayer)) {
				int enemyPlayer;

				enemyPlayer = g.settlement.player;
				settlement = "has a Settlement from the Enemy Player " + enemyPlayer;
			}
			else if (g.settlement.IsOwn(aiPlayer))
				settlement = "has a Settlement owned by the Player " + aiPlayer;

			else if (g.settlement.IsAlly(aiPlayer)) {
				int allyPlayer;

				allyPlayer = g.settlement.player;
				settlement = "has a Settlement owned by the Ally Player " + allyPlayer;
			} 
			else
				settlement = "has a Settlement of unkown player";

			if (g.settlement.IsVillage)
				setType = "Village";
			else if (g.settlement.IsOutpost)
				setType = "Outpost";
			else if (g.settlement.IsStronghold)
				setType = "Stronghold";
			else if (g.settlement.IsTTent)
				setType = "Tent";
			else if (g.settlement.IsShipyard)
				setType = "Shipyard";
			else
				setType = "Unknown";

			settlement = settlement + " of Type " + setType;
		} else {
			settlement = "doesn't have a Settlement";
		}

		AppendFile("Data/useful-info/AI_ARMYNEED.log", "Game time (Hour:Min:Sec) is " + gameTime + " or " + miliseconds + " milliseconds. Player " + aiPlayer + "\n" +
					"The GAIKA " + g.ID + " at " + gaikaPos + " is " + explored + " and is " + revealed + " by " + aiPlayer + ".\n" +
					"The enemy value is " + enemy + ". The minimum army need is " + nMinNeed + " and the max is " + nMaxNeed + ". This call asks for " + limit + ".\n" +
					"This GAIKA " + settlement + ".\n\n");

		EnvWriteInt(aiPlayer, "armyNeedLogTime", GetTime());
	}
}

// ================
// ARMY NEED RETURN
// ================

if (bMin)
	return nMinNeed;

return nMaxNeed;
