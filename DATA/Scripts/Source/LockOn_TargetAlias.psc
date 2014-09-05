Scriptname LockOn_TargetAlias extends ReferenceAlias  


Event OnDying(Actor akKiller)
	LockOn_Main LockonQuest = GetOwningQuest() as LockOn_Main
	
	int case = LockonQuest.iAutoDead
	if (case == 0)
		; Unlock
		LockonQuest.StopLockon()
	elseif (case == 1)
		; Target Closest Enemy
		Actor target = LockonQuest.FindClosestCombatTarget(LockonQuest.fDistance)
		if (target && target != self.GetActorReference())
			LockonQuest.StartLockOn(target)
		else
			LockonQuest.StopLockon()
		endif
	elseif (case == 2)
		; Keep Locking
	endif
EndEvent


Event OnEnterBleedout()
	if (self.GetActorReference().IsEssential())
		LockOn_Main LockonQuest = GetOwningQuest() as LockOn_Main
		
		int case = LockonQuest.iAutoDead
		if (case == 0)
			; Unlock
			LockonQuest.StopLockon()
		elseif (case == 1)
			; Target Closest Enemy
			Actor target = LockonQuest.FindClosestCombatTarget(LockonQuest.fDistance)
			if (target && target != self.GetActorReference())
				LockonQuest.StartLockOn(target)
			else
				LockonQuest.StopLockon()
			endif
		elseif (case == 2)
			; Keep Locking
		endif
	endif
EndEvent


Event OnCellDetach()
	(GetOwningQuest() as LockOn_Main).StopLockOn()
EndEvent


Event OnUnload()
	(GetOwningQuest() as LockOn_Main).StopLockOn()
EndEvent


Event OnDetachedFromCell()
	(GetOwningQuest() as LockOn_Main).StopLockOn()
EndEvent

