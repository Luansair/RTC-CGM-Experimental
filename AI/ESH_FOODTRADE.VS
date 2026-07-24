// void, Settlement set

// Called by ES_Stronghold, this script finds outposts (Gaul/Germany) that need food
// and sends a mule to one of them per execution.
// Multiple outposts are supported: the script iterates and processes the first
// one that needs attention, automatically rotating between them.

int aiPlayer, nLsa, nMaxSetIdx, i;
Settlement sSell;
Building b;

aiPlayer = set.player;
nLsa = set.GetCentralBuilding().LSA;
nMaxSetIdx = MaxSetIdx;

for (i = 0; i < nMaxSetIdx; i += 1) {
    sSell = IdxToSet(i);
    if (!sSell.IsValid)
        continue;
    if (!sSell.IsOwn(aiPlayer))
        continue;
    if(!sSell.IsOutpost)
        continue;

    b = sSell.GetCentralBuilding();
    if (b.LSA != nLsa)  // Debe estar en la misma masa terrestre
        continue;

    if (b.race != Gaul && b.race != Germany)
        continue;

    if (!sSell.supplied.IsValid) {
        sSell.StartSupplyFood(set);
        EnvWriteInt(set, "FoodTradeMuleWait", GetTime() + 20000);
        return;
    }

    if (sSell.supplied.IsValid) {
        if (sSell.food < 500) {
            Wagon mule;
            mule = set.CreateMuleFood(MIN(1000, set.food - 1000));
            if (mule.IsValid) {
                mule.SetCommand("unload", b);
                EnvWriteInt(set, "FoodTradeMuleWait", GetTime() + 20000);
            }
            return;
        }
    }
}

// If we reach here, no outpost for food trade needed atention...