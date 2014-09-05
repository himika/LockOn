Scriptname LockOn_AddonBase extends Quest

;=================================================
; properties
;=================================================

bool Property CanDeactivate
	Function Set(bool flag)
		LockOn_Main mq = Game.GetFormFromFile(0x000D62, "hmkLockOn.esp") as LockOn_Main
		FormList regList = Game.GetFormFromFile(0x000D64, "hmkLockOn.esp") as FormList
		regList && !regList.HasForm(self) && regList.AddForm(self)
		_lab_canDeactivate = flag
		_lab_quest = mq
		_lab_regList = regList
	EndFunction
	bool Function Get()
		return _lab_canDeactivate
	EndFunction
EndProperty

string Property AddonDescription Auto


;=================================================
; private variables
;=================================================

bool        _lab_canDeactivate
LockOn_Main _lab_quest
FormList    _lab_regList


;=================================================
; Override
;=================================================

Function Stop()
	OnDeactivate()
	Parent.Stop()
EndFunction


;=================================================
; Interfaces
;=================================================

Actor Function GetTarget()
	Actor result = None
	if (_lab_quest != None && _lab_quest.IsRunning())
		result = _lab_quest.refLockon
	endif
	return result
EndFunction


bool Function LockOn(Actor akTarget)
	if (_lab_quest != None && _lab_quest.IsRunning())
		return _lab_quest.StartLockOn(akTarget)
	endif
	return false
EndFunction


Function Unlock()
	if (_lab_quest != None && _lab_quest.IsRunning())
		_lab_quest.StopLockOn()
	endif
EndFunction


ObjectReference Function GetCrosshairReference()
	return LockOn_Main.GetCrosshairReference()
EndFunction


Actor[] Function FindCloseActor(float distance)
	_lab_quest.FindCloseActor(distance, 0)
EndFunction


Actor Function FindTarget()
	Actor result = None
	
	if (_lab_quest && _lab_quest.IsRunning())
		result = _lab_quest.FindTarget(_lab_quest.fDistance)
	endif
	return result
EndFunction


Actor Function FindNextTarget(bool abRight, Actor akTarget = None)
	Actor result = None
	if (_lab_quest && _lab_quest.IsRunning())
		result = _lab_quest.FindNextTarget(_lab_quest.fDistance, abRight)
	endif
	return result
EndFunction


Function LookAt(float x, float y, float z, float fSpeed)
	if (_lab_quest && _lab_quest.IsRunning() && _lab_quest.GetState() == "")
		LockOn_Main.LookAt(x, y, z, fSpeed)
	endif
EndFunction


Function LookAtRef(ObjectReference akRef, float fSpeed)
	if (_lab_quest && _lab_quest.IsRunning() && _lab_quest.GetState() == "")
		LockOn_Main.LookAtRef(akRef, fSpeed)
	endif
EndFunction



;=================================================
; Events
;=================================================

Event OnLock(Actor akTarget)
	{Called when the player locks on the target}
EndEvent


Event OnUnlock(Actor akTarget)
	{Called when the player unlocks the target}
EndEvent


Event OnDeactivate()
	{Called when this addon is deacitivated}
EndEvent
