//void, Obj this

.Progress();

{
	Settlement set;

	set = .AsBuilding().settlement;

	set.GoldSpent(-2000);
	set.SetGold(set.gold + 3000);
	set.GoldConverted(1000);
}