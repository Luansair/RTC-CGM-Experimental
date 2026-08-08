//int, Squad sq, GAIKA g, GAIKA *gDepend

// This script evaluates the squad to send to support gaikas that need reinforcements
GAIKA gCurDest;
Unit sqLeader;
Settlement set;
int aiPlayer, lsaPathLen, nEval, avgUnitPower;
bool bAssUnderFire;

aiPlayer = sq.Player;
bAssUnderFire = g.ID == EnvReadInt(aiPlayer, "AssUnderFireGaika");

// Under attack it uses squads with no exception. Otherwise it looks for squads that are not doing anything relevant.
if (!bAssUnderFire) {
	int sqState;
	Settlement sOrigin;

	sqState = sq.State;

	if (sqState != SS_IDLE && sqState != SS_Approach && sqState != SS_Wait && sqState != SS_ApproachWait && sqState != SS_Enter)
		return -1;
	
	sOrigin = sq.GAIKAIn.settlement;
	
	if (sOrigin.IsValid)
		if (sOrigin.IsOwn(aiPlayer) && sOrigin.IsStronghold) {
			int nMaxLevel;
			bool bHasTraining = false;

			if (IsResearched(aiPlayer, "Gaul Training 3") || 
				IsResearched(aiPlayer, "Special training")) {

				bHasTraining = true;	
				nMaxLevel = 12;
			}
			else if (IsResearched(aiPlayer, "Spartan Training")) {
				bHasTraining = true;
				nMaxLevel = 10;
			}
			else if (IsResearched(aiPlayer, "Gaul Training 2") || 
					IsResearched(aiPlayer, "Advanced Training") || 
					IsResearched(aiPlayer, "Rome Training 2") ||
					IsResearched(aiPlayer, "Ancestral Knowledge")) {
				bHasTraining = true;
				nMaxLevel = 8;
			}
			else if (IsResearched(aiPlayer, "Gaul Training 1") ||
					IsResearched(aiPlayer, "Rome Training 1") ||
					IsResearched(aiPlayer, "Training")) {
				bHasTraining = true;
				nMaxLevel = 4;
			}

			if (bHasTraining) {
				bool bNeedsTraining = false;
				ObjList units;
				Unit u;
				int ui;

				units = sq.Units;
				for (ui = 0; ui < units.count; ui += 1) {
					u = units[ui].AsUnit();
					if (u.IsAlive && u.inherentlevel < nMaxLevel) {
						bNeedsTraining = true;
					}
				}
				if (bNeedsTraining && (sq.InHolder || sq.State == SS_IDLE || sq.State == SS_Enter))
					return -24;  // Need training
			}
		}
}

// If Squad is already assigned to the desired GAIKA dont eval again.
gCurDest = sq.AIDest;
if (gCurDest == g)
	return -2;

// Checks if squad can reach the destinated GAIKA (via caves/transport)
sqLeader = sq.Leader;
if (sqLeader.AsShip().IsValid) {
	if (sqLeader.AsShip().HasAiTransport)
		return -3;
	if (!IsWaterLsa(g.LSA))
		return -4;
}
else if (IsWaterLsa(g.LSA))
	return -5;

if (AIVar(aiPlayer, AIV_UseTeleports) == 0) {
	lsaPathLen = CheckLsaPath(sq.GAIKAIn.LSA, g.LSA, aiPlayer);
	if (lsaPathLen == 0)
		return -6;
}
else if (FindTeleport(aiPlayer, sq.pos, g.Center).IsValid)
	lsaPathLen = 1;
else {
	lsaPathLen = CheckLsaPath(sq.GAIKAIn.LSA, g.LSA, aiPlayer);
	if (lsaPathLen == 0)
		return -7;
}

set = g.settlement;  // Destination settlement

// Prevent scattering small armies
if (set.IsValid)
	if (!set.IsOwn(aiPlayer))
		if (!sqLeader.AsHero().IsValid)
			if (!sqLeader.HasFreedom) {
				if (set.IsTTent)
					return -8;
				if (!set.IsIndependent)
					return -9;
				if (set.IsIndependentGuarded)
					return -10;
				if (set.IsOutpost)
					return -23;
			}

if (sq.Size > 0)
	avgUnitPower = sq.Eval / sq.Size;
if (!sqLeader.AsHero().IsValid && !sqLeader.HasFreedom) {
	if (avgUnitPower > 120 || sq.Size > 10) {
		return -21;
	} 
	else if (GetTime() < EnvReadInt(g.ID, "nTimerAttemptSendFreeSquad")) {
		return -22;
	}
	EnvWriteInt(g.ID, "nTimerAttemptSendFreeSquad", GetTime() + 30000 + rand(30001));
}

if (!bAssUnderFire) {
	Settlement s;
	bool bFightForFood = false;

	//do not explore with Trident Warriors, Viking Lords or Elephants
	if (sqLeader.HasFreedom) {
		if (sqLeader.IsHeirOf("GTridentWarrior")) {
			if (g.Eval(AI_STAYING, aiPlayer, AI_ENEMY) < 500)
				return -11;
		}
		else if (sqLeader.IsHeirOf("BVikingLord")) {
			if (g.Eval(AI_STAYING, aiPlayer, AI_ENEMY) < 500)
				return -12;
		}
		else if (sqLeader.IsHeirOf("CWarElephant"))
			if (g.Eval(AI_STAYING, aiPlayer, AI_ENEMY) < 500)
				return -13;
		if (set.IsValid)
			if (set.IsIndependent)
				if (set.IsStronghold)
					return -14;
		if (!g.Explored(aiPlayer))
			return -15;
	}

	s = sq.GAIKAIn.settlement;  // Settlement where the squad currently is / sOrigin

	if (set.IsValid)
		if (set.IsVillage)
			if (s.IsValid)
				if (s.IsStronghold)
					if (s.food < 100)
						bFightForFood = true;

		if (!bFightForFood)
			// Squads with Hero
			if (sqLeader.AsHero().IsValid) {
			if (s.IsValid) {
				//always enforce a minimum army size before sending a hero to fight (not only in strongholds)
				{
				int nHeroMin;
				nHeroMin = AIVar(aiPlayer, AIV_HeroMinArmySize);  // Checks size instead of power. Uses pre defined variable instead of evaluating the context/situation like military power.
					if (nHeroMin > 0)
						if (sq.Size < nHeroMin)
							if (!set.IsValid || !set.IsOwn(aiPlayer))
								return -16;//not enough army, do not send the hero out
				}
				if (s.IsStronghold) {
					int time, min;
					time = GetTime() / 60000;
					if (time < 10)
						min = 30;
					else if (time < 20)
						min = 44;
					else if (time < 30)
						min = 46;
					else if (time < 60)
						min = 48;
					else
						min = 50;
					if (sq.Size < min)
						return -16;
				}
				if (s.food >= 100)
					if (set.IsValid)
						if (!set.IsOwn(aiPlayer)) {
							if (sq.health < sq.maxhealth * 4 / 5)
								return -17;//heal first
						}
						else if (!set.IsStronghold)
							if (sq.health < sq.maxhealth * 4 / 5)
								return -18;//heal first
			}
			}
			// Squads without Hero.
			else {
				if (sq.Size < 10) {
					Settlement hs;
					hs = sqLeader.GetHolderSett();
					if (hs.IsValid)
						if (hs.IsTTent)
							return -19;
				}
				if (g.Explored(aiPlayer))
					if (set.IsValid)
						if (!set.IsIndependent)
							if (s.IsValid)
								if (s.IsStronghold)
									if (s.IsOwn(aiPlayer))
										if (!sq.HasFreedom)
											return -20;//wait to attach before sending
		}

	if (gCurDest.GetPriority(aiPlayer) >= g.GetPriority(aiPlayer))
		gDepend = gCurDest;//remember that gDepend is a reference variable, it is not used directly here but it is important not to remove it
}

nEval = 100000 - sq.pos.Dist(g.Center) * lsaPathLen;

//do not give tasks too often
{
	int nWeightTime;
	nWeightTime = AIVar(aiPlayer, AIV_SquadRecruitWeight);
	if (nWeightTime > 0) {
		int nStateTime;
		nStateTime = sq.StateTime / 1000;
		if (nStateTime < nWeightTime)
			nEval = MAX(1, nEval * nStateTime / nWeightTime);
	}
}

return nEval;