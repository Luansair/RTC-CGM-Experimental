//void, GAIKA gaika

int aiPlayer, nSleepGS, squadState;
point gaikaCenter;
Squad squad;
bool enableLogging = false;

aiPlayer = AIGetPlayer();
nSleepGS = AIVar(aiPlayer, AIV_Sleep_GS);
gaikaCenter = gaika.Center;

while (gaika.GetStrat(aiPlayer) == GS_Guard) {
	SquadList SL;
	Settlement setGkIn;
	int own, ally, enemy, enemy_hidden;
	bool bNoEnemies, bIsInOwnStronghold = false;

	gaika.Eval(AI_STAYING, aiPlayer, own, ally, enemy, enemy_hidden);
	bNoEnemies = enemy <= 0;
	setGkIn = gaika.settlement;

	if (setGkIn.IsValid)
		if (setGkIn.IsOwn(aiPlayer) && setGkIn.IsStronghold)
			bIsInOwnStronghold = true;

	gaika.GetSquads(SL, AI_ALL, aiPlayer, AI_OWN);

	SL.Lock();
	while (!SL.EOL) {

		squad = SL.Cur;
		squadState = squad.State;

		if (squadState == SS_Wait)
			squad.ClrCmd(SS_IDLE, 0, SF_ADVCHOOSER);
		else if (squadState == SS_Approach && squad.GAIKAIn == gaika && squad.AIDest == gaika && squad.pos.Dist(gaikaCenter) <= 500 && squad.Leader.command != "explore")
			squad.ClrCmd(SS_IDLE, 0, SF_ADVCHOOSER);
		
		// ============= IDLE SQUADS ============
		// Do something with squads that are idle for too long

		if (bNoEnemies && !bIsInOwnStronghold && squad.GAIKAIn == gaika && squad.StateTime > 20000 && squadState == SS_IDLE) {
			Settlement aStronghold;
			bool exploreNeighbors;
			GAIKA gkToExplore;

			aStronghold = NearestStronghold(squad.pos, aiPlayer);

			// ======== EXPLORATION VALIDATION =======
			// Checks the type of squad and if there is any valid gaika to explore

			if (!squad.Leader.AsHero().IsValid && squad.Size < 10) {
				int nNeighbors, j;
				
				nNeighbors = gaika.Neighbors();
				for (j = 0; j < nNeighbors; j += 1) {
					GAIKA gN;
					gN = gaika.Neighbor(j);
					if (gN.Explored(aiPlayer))
						continue;
					if (!gN.CanExplore(aiPlayer))
						continue;
					if (IsWaterLsa(gN.LSA))
						continue;

					if (rand(nNeighbors) <= j) {
						gkToExplore = gN;
						exploreNeighbors = true;
						break;
					}
				}
			}
			
			if (exploreNeighbors && gkToExplore.ID > 0) {
				squad.SetCmd(SS_Approach, 0, SF_ADVCHOOSER, "explore", gkToExplore.Center);
				Sleep(100);
			}
			// If can't explore, send army home
			else if (aStronghold.IsValid) {
				if (aStronghold.GetGaika() != gaika) {
					squad.SetCmd(SS_Approach, 0, SF_ADVCHOOSER, "advance", aStronghold.GetCentralBuilding());
					Sleep(100);
				} else {
					squad.SetCmd(SS_Enter, 0, SF_ADVCHOOSER, "enter", aStronghold.GetCentralBuilding());
					Sleep(100);
				}
			}

			if (enableLogging) {
				if (GetTime() >= EnvReadInt(aiPlayer, "logTimer")) {
					EnvWriteInt(aiPlayer, "logTimer", GetTime() + 500);
					AppendFile("AI_DEBUG2.log", "GUARD t=" + GetTime() + " retira sq de GAIKA " + gaika.ID + " st=" + squadState + "\n");
				}
			} 
		}
		SL.Next();
	}
	SL.Unlock();

	Sleep(nSleepGS);
}