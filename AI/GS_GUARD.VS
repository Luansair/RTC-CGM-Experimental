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
		else if (squadState == SS_Approach && squad.GAIKAIn == gaika && squad.AIDest == gaika && squad.pos.Dist(gaikaCenter) <= 500)
			squad.ClrCmd(SS_IDLE, 0, SF_ADVCHOOSER);
		
		if (bNoEnemies && !bIsInOwnStronghold && squad.GAIKAIn == gaika && squad.StateTime > 10000 && squadState == SS_IDLE) {
			Settlement aStronghold;

			if (aiPlayer == 2 && enableLogging)
				if (GetTime() >= EnvReadInt(aiPlayer, "logTimer")) {
					EnvWriteInt(aiPlayer, "logTimer", GetTime() + 500);
					AppendFile("AI_DEBUG2.log", "GUARD t=" + GetTime() + " retira sq de GAIKA " + gaika.ID + " st=" + squadState + "\n");
				}

			aStronghold = NearestStronghold(squad.pos, aiPlayer);
			if (aStronghold.IsValid)
				if (aStronghold.GetGaika() != gaika) {
					squad.SetCmd(SS_Approach, 0, SF_ADVCHOOSER, "advance", aStronghold.GetCentralBuilding());
				}
		}
		SL.Next();
	}
	SL.Unlock();

	Sleep(nSleepGS);
}