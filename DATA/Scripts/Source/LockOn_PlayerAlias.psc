Scriptname LockOn_PlayerAlias extends ReferenceAlias  

Keyword Property WeapTypeBow Auto

Event OnPlayerLoadGame()
	(GetOwningQuest() as LockON_Main).OnGameReload()
EndEvent


Event OnHit(ObjectReference akAggressor, Form akSource, Projectile akProjectile, bool abPowerAttack, bool abSneakAttack,  bool abBashAttack, bool abHitBlocked)
	LockON_Main LockonQuest = GetOwningQuest() as LockON_Main
	
	if (LockonQuest.GetState() != "Ready" || Game.GetPlayer().IsOnMount())
		return
	endif
	
	Actor target = akAggressor as Actor
	if (target == None)
		return
	endif
	
	if (LockonQuest.bAutoAggressor)
		if (akProjectile == None)
			if (akSource as Weapon && !akSource.HasKeyword(WeapTypeBow))
				if (LockonQuest.bExceptFollower && target.IsPlayerTeammate())
					return
				endif
				LockonQuest.StartLockon(target)
			endif
		endif
	endif
EndEvent



Event Lockon_OnPlayerHit(ObjectReference akTarget, Form akSource, Projectile akProjectile)
	LockON_Main LockonQuest = GetOwningQuest() as LockON_Main
	
	if (LockonQuest.GetState() != "Ready" || Game.GetPlayer().IsOnMount())
		return
	endif
	
	Actor target = akTarget as Actor
	if (target == None)
		return
	endif
	
	if (LockonQuest.bAutoTarget)
		if (akProjectile == None)
			if (akSource as Weapon && !akSource.HasKeyword(WeapTypeBow))
				if (LockonQuest.bExceptCorpse && target.IsDead())
					return
				endif
				if (LockonQuest.bExceptFollower && target.IsPlayerTeammate())
					return
				endif
				LockonQuest.StartLockon(target)
			endif
		endif
	endif
EndEvent


Event Lockon_OnCombatStart(Actor akTarget)
	LockON_Main LockonQuest = GetOwningQuest() as LockON_Main
	
	if (LockonQuest.bAutoCombat == false)
		return
	endif

	if (LockonQuest.GetState() != "Ready" || Game.GetPlayer().IsOnMount())
		return
	endif
	
	if (LockonQuest.bExceptFollower && akTarget.IsPlayerTeammate())
		return
	endif
	
	Actor target = LockonQuest.FindClosestCombatTarget(LockonQuest.fDistance)
	if (target)
		LockonQuest.StartLockOn(target)
	else
		LockonQuest.StartLockon(akTarget)
	endif
EndEvent

