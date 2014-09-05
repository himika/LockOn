Scriptname LockOn_Main extends Quest

;=====================================================================
; propaties
;=====================================================================

LockOn_HUDWidget Property widget auto
Sound Property UIMenuActive auto

float Property fSpeed
	Function Set(float value)
		_fSpeed = value
		SetCameraSpeed(value)
	EndFunction
	float Function Get()
		return _fSpeed
	EndFunction
EndProperty

float Property fDistance Auto

int Property keyLockon
	Function Set(int KeyCode)
		(_keyLockon != -1) && UnregisterForKey(_keyLockon)
		_keyLockon = KeyCode
		(_keyLockon != -1) && RegisterForKey(_keyLockon)
	EndFunction
	int Function Get()
		return _keyLockon
	EndFunction
EndProperty

int Property keyLeft
	Function Set(int KeyCode)
		(_keyLeft != -1) && UnregisterForKey(_keyLeft)
		_keyLeft = KeyCode
		(_keyLeft != -1) && RegisterForKey(_keyLeft)
	EndFunction
	int Function Get()
		return _keyLeft
	EndFunction
EndProperty

int Property keyUp
	Function Set(int KeyCode)
		(_keyUp != -1) && UnregisterForKey(_keyUp)
		_keyUp = KeyCode
		(_keyUp != -1) && RegisterForKey(_keyUp)
	EndFunction
	int Function Get()
		return _keyUp
	EndFunction
EndProperty

int Property keyDown
	Function Set(int KeyCode)
		(_keyDown != -1) && UnregisterForKey(_keyDown)
		_keyDown = KeyCode
		(_keyDown != -1) && RegisterForKey(_keyDown)
	EndFunction
	int Function Get()
		return _keyDown
	EndFunction
EndProperty

int Property keyRight
	Function Set(int KeyCode)
		(_keyRight != -1) && UnregisterForKey(_keyRight)
		_keyRight = KeyCode
		(_keyRight != -1) && RegisterForKey(_keyRight)
	EndFunction
	int Function Get()
		return _keyRight
	EndFunction
EndProperty

Actor Property refLockon
	Function Set(Actor ref)
		(_refLockon) && (GetAlias(0) as ReferenceAlias).Clear()
		_refLockon = ref
		(_refLockon) && (GetAlias(0) as ReferenceAlias).ForceRefTo(ref)
	EndFunction
	Actor Function Get()
		return _refLockon
	EndFunction
EndProperty

bool Property bDoubleTap Auto
bool Property bAutoAggressor Auto
bool Property bAutoTarget Auto
bool Property bAutoCombat Auto
int  Property iAutoDead Auto

bool Property bExceptCorpse
	Function Set(bool b)
		_bExceptCorpse = b
		_flagExcept = GetExceptFlag()
	EndFunction
	bool Function Get()
		return _bExceptCorpse
	EndFunction
EndProperty

bool Property bExceptSight
	Function Set(bool b)
		_bExceptSight = b
		_flagExcept = GetExceptFlag()
	EndFunction
	bool Function Get()
		return _bExceptSight
	EndFunction
EndProperty

bool Property bExceptFollower
	Function Set(bool b)
		_bExceptFollower = b
		_flagExcept = GetExceptFlag()
	EndFunction
	bool Function Get()
		return _bExceptFollower
	EndFunction
EndProperty

bool Property bExceptFrendly
	Function Set(bool b)
		_bExceptFrendly = b
		_flagExcept = GetExceptFlag()
	EndFunction
	bool Function Get()
		return _bExceptFrendly
	EndFunction
EndProperty

bool Property bExceptPrey
	Function Set(bool b)
		_bExceptPrey = b
		_flagExcept = GetExceptFlag()
	EndFunction
	bool Function Get()
		return _bExceptPrey
	EndFunction
EndProperty

int Function GetExceptFlag()
	int flags = 0
	if (_bExceptCorpse)
		flags += 1
	endif
	if (_bExceptSight)
		flags += 2
	endif
	if (_bExceptFollower)
		flags += 4
	endif
	if (_bExceptFrendly)
		flags += 8
	endif
	if (_bExceptPrey)
		flags += 16
	endif
	return flags
EndFunction


;=====================================================================
; private variable
;=====================================================================

Actor           _refLockon          = None
int             _keyLockon          = -1
int             _keyLeft            = -1
int             _keyRight           = -1
int             _keyUp              = -1
int             _keyDown            = -1
float           _fSpeed             = 300.0
;bool           _bDoubleTap         = false
;bool           _bAutoAggressor     = true
;bool           _bAutoTarget        = true
;bool           _bAutoCombat        = false
bool            _bExceptCorpse      = true
bool            _bExceptSight       = true
bool            _bExceptFollower    = false
bool            _bExceptFrendly     = false
bool            _bExceptPrey        = true

int             _flagExcept         = 0
;=============================
; 0x0001 - except dead body
; 0x0002 - except out of sight
; 0x0004 - except follower
; 0x0008 - except frendly actors
; 0x0010 - except preys
;=============================

Actor _player = None
bool  _bIsGamepad = false

bool  _bPressLockonKey = false
bool  _bChangeTarget = false

float _fPrevTime = 0.0
int   _iPrevKey = -1
float _fStickLeftTime           = 0.0
float _fStickLeftPrevTime       = 0.0
int   _iStickLeftDirection      = 0
int   _iStickLeftPrevDirection  = 0
float _fStickRightTime          = 0.0
float _fStickRightPrevTime      = 0.0
int   _iStickRightDirection     = 0
int   _iStickRightPrevDirection = 0


;=====================================================================
; Override
;=====================================================================

bool Function Start()
	return Parent.Start()
EndFunction


Function Stop()
	keyLockon = -1
	keyLeft = -1
	keyRight = -1
	
	UnregisterForAnimationEvent(_player, "MountEnd")
	UnregisterForMenu("Journal Menu")
	
	StopLockOn()
	GotoState("")
	
	Parent.Stop()
EndFunction


;=====================================================================
; Initialization
;=====================================================================

Event OnInit()
	OnGameReload()
EndEvent


Event OnGameReload()
	int ver = SKSE.GetPluginVersion("lockon plugin")
	if (ver == -1)
		Debug.Notification("<font color='#FFA0A0'>(ERROR) LockOn.dll is not loaded.</font>")
		Debug.Trace("LockOn: (ERROR) LockOn.dll is not loaded.")
		return
	elseif (ver < 2)
		Debug.Notification("<font color='#FFA0A0'>(ERROR) LockOn.dll is too old.</font>")
		Debug.Trace("LockOn: (ERROR) LockOn.dll is too old.")
		return
	endif
	
	_player = Game.GetPlayer()
	_bIsGamepad = IsGamepadEnabled()
	_flagExcept = GetExceptFlag()
	
	; Reflesh events
	RegisterForAnimationEvent(_player, "MountEnd")
	
	int newKey = -1
	int keyboardDefaultKey = Input.GetMappedKey("Run", 0)
	int gamepadDefaultKey = Input.GetMappedKey("Sprint", 2)
	
	if (_keyLockon == -1 || _keyLockon == keyboardDefaultKey || _keyLockon == gamepadDefaultKey)
		if (_bIsGamepad)
			newKey = gamepadDefaultKey
		else
			newKey = keyboardDefaultKey
		endif
	else
		newKey = keyLockon
	endif
	keyLockon = newKey
	
	keyLeft  = Input.GetMappedKey("Strafe Left")
	keyRight = Input.GetMappedKey("Strafe Right")
	keyUp    = Input.GetMappedKey("Forward")
	keyDown  = Input.GetMappedKey("Back")
	
	fSpeed = fSpeed
	
	if (GetState() == "")
		GotoState("Ready")
	endif
EndEvent


;=====================================================================
; Default State
;=====================================================================

bool Function StartLockOn(Actor akRef)
	return false
EndFunction

Function StopLockOn()
EndFunction


Event OnKeyDown(int KeyCode)
	if (KeyCode == keyLockon)
		_bPressLockonKey = true
		_bChangeTarget = false
	endif
EndEvent


Event OnKeyUp(int KeyCode, float HoldTime)
	if (KeyCode == keyLockon)
		_bPressLockonKey = false
	endif
	
	float fCurrentTime = Utility.GetCurrentRealTime()
	if (HoldTime >= 0.3)
		_iPrevKey = -1
		_fPrevTime = fCurrentTime
		return
	endif
	
	bool IsDoubleTap = false
	if (KeyCode == _iPrevKey && fCurrentTime - _fPrevTime < 0.333)
		IsDoubleTap = true
	endif
	_iPrevKey = KeyCode
	_fPrevTime = fCurrentTime
	
	if (Utility.IsInMenuMode() || _player.IsOnMount())
		return
	endif
	
	if (KeyCode == keyLockon)
		OnKey_Lockon(IsDoubleTap)
	elseif (KeyCode == keyLeft)
		_bChangeTarget = _bChangeTarget || _bPressLockonKey
		OnKey_Left(0, IsDoubleTap)
	elseif (KeyCode == keyRight)
		_bChangeTarget = _bChangeTarget || _bPressLockonKey
		OnKey_Right(0, IsDoubleTap)
	elseif (KeyCode == keyUp)
		_bChangeTarget = _bChangeTarget || _bPressLockonKey
		OnKey_Up(0, IsDoubleTap)
	elseif (KeyCode == keyDown)
		_bChangeTarget = _bChangeTarget || _bPressLockonKey
		OnKey_Down(0, IsDoubleTap)
	endif
EndEvent


Event OnKey_Lockon(bool IsDoubleTap)
EndEvent


Event OnKey_Left(int device, bool IsDoubleTap)
EndEvent


Event OnKey_Right(int device, bool IsDoubleTap)
EndEvent


Event OnKey_Up(int device, bool IsDoubleTap)
EndEvent


Event OnKey_Down(int device, bool IsDoubleTap)
EndEvent


Event Lockon_OnThumbstick(int stick, float axisX, float axisY)
	float absX = Math.Abs(axisX)
	float absY = Math.Abs(axisY)
	float currentTime = Utility.GetCurrentRealTime()
	
	if (axisX != 0 || axisY != 0)
		int direction
		if (absX > absY)
			if (axisX > 0)
				direction = 1   ; right
			else
				direction = 3   ; left
			endif
		else
			if (axisY > 0)
				direction = 0   ; up
			else
				direction = 2   ; down
			endif
		endif
		
		if (stick == 0x0B)
			_fStickLeftTime = currentTime
			_iStickLeftDirection = direction
		elseif (stick == 0x0C)
			_fStickRightTime = currentTime
			_iStickRightDirection = direction
		endif
	else
		float startTime = 0.0
		float prevTime  = 0.0
		int   direction
		int   prevDirection
		
		if (stick == 0x0B)
			startTime     = _fStickLeftTime
			prevTime      = _fStickLeftPrevTime
			direction     = _iStickLeftDirection
			prevDirection = _iStickLeftPrevDirection
		elseif (stick == 0x0C)
			startTime     = _fStickRightTime
			prevTime      = _fStickRightPrevTime
			direction     = _iStickRightDirection
			prevdirection = _iStickRightPrevDirection
		endif
		
		if (currentTime - startTime < 0.5)
			bool IsDoubleTap = false
			if (direction == prevDirection && currentTime - prevTime < 0.5)
				IsDoubleTap = true
			endif
			
			if (stick == 0x0B)
				_fStickLeftPrevTime = currentTime
				_iStickLeftPrevDirection = direction
			elseif (stick == 0x0C)
				_fStickRightPrevTime = currentTime
				_iStickRightPrevDirection = direction
			endif
			
			if (Utility.IsInMenuMode() || _player.IsOnMount())
				return
			endif
			
			if (direction == 0)
				OnKey_Up(stick, IsDoubleTap)
			elseif (direction == 1)
				OnKey_Right(stick, IsDoubleTap)
			elseif (direction == 2)
				OnKey_Down(stick, IsDoubleTap)
			elseif (direction == 3)
				OnKey_Left(stick, IsDoubleTap)
			endif
		endif
	endif
EndEvent


Event Lockon_OnMouse(int x, int y)
EndEvent


Event OnAnimationEvent(ObjectReference akSource, string eventName)
EndEvent


bool Function CheckThumbstick()
	if (_bIsGamepad && _player.IsSneaking())
		float axisX = GetThumbstickAxisX(0x0B)
		float axisY = GetThumbstickAxisY(0x0B)
		if (axisY > 0.0 && axisY > Math.Abs(axisX))
			return false
		endif
	endif
	return true
EndFunction


Function _GUARD()
	Debug.MessageBox("LockOn_Main: Don't recompile this script!")
EndFunction


;=====================================================================
State Ready
;=====================================================================

bool Function StartLockOn(Actor akRef)
	GotoState("Busy")
	
	if (akRef == None || !akRef.Is3DLoaded())
		GotoState("Ready")
		return false
	endif
	
	refLockon = akRef
	
	Game.DisablePlayerControls(false, false, false, true, false, false, false, false)
	
	GotoState("LockOn")
	return true
EndFunction


Function StopLockOn()
EndFunction


Event OnKey_Lockon(bool IsDoubleTap)
	if (IsDoubleTap)
		return
	endif
	
	if (!Game.IsLookingControlsEnabled())
		return
	endif
	
	if (CheckThumbstick())
		Actor akTarget = FindTarget(fDistance)
		if (akTarget)
			StartLockOn(akTarget)
		endif
	endif
EndEvent

Event OnKey_Left(int device, bool IsDoubleTap)
	if (_bPressLockonKey || (bDoubleTap && IsDoubleTap))
		Actor akTarget = FindTarget(fDistance)
		if (akTarget)
			StartLockon(akTarget)
		endif
	endif
EndEvent

Event OnKey_Right(int device, bool IsDoubleTap)
	if (_bPressLockonKey || (bDoubleTap && IsDoubleTap))
		Actor akTarget = FindTarget(fDistance)
		if (akTarget)
			StartLockon(akTarget)
		endif
	endif
EndEvent

Event OnKey_Down(int device, bool IsDoubleTap)
	if (_bPressLockonKey || (bDoubleTap && IsDoubleTap))
		Actor akTarget = None
		
		akTarget = FindClosestTarget(fDistance)
		if (akTarget)
			StartLockon(akTarget)
		endif
	endif
EndEvent


EndState


;=====================================================================
State Busy
;=====================================================================

bool Function StartLockOn(Actor akRef)
	int safety = 20;
	while (GetState() == "Busy" && safety > 0)
		Utility.Wait(0.125)
		safety -= 1
	endwhile
	if (safety == 0)
		Debug.Trace("LockOn_Main: (Warning) busy state loop is timed out.")
		if (refLockon)
			GotoState("LockOn")
		else
			GotoState("Ready")
		endif
	endif
	
	return StartLockOn(akRef)
EndFunction

Function StopLockOn()
	int safety = 20;
	while (GetState() == "Busy" && safety > 0)
		Utility.Wait(0.125)
		safety -= 1
	endwhile
	if (safety == 0)
		Debug.Trace("LockOn_Main: (Warning) busy state loop is timed out.")
		if (refLockon)
			GotoState("LockOn")
		else
			GotoState("Ready")
		endif
	endif
	
	StopLockOn()
EndFunction

EndState


;=====================================================================
State LockOn
;=====================================================================

Event OnBeginState()
	SendLockonStartEvent()
	UIMenuActive.Play(_player)
	widget.enterLockOn()
	
	ResetMouse()
EndEvent


Event OnEndState()
	SendLockonStopEvent()
	widget.leaveLockOn()
EndEvent


bool Function StartLockOn(Actor akRef)
	GotoState("Busy")
	
	if (!akRef.Is3DLoaded())
		GotoState("LockOn")
		return false
	endif
	
	refLockon = akRef
	if (akRef == None)
		refLockon = None
		Game.EnablePlayerControls(false, false, false, true, false, false, false, false)
		GotoState("Ready")
		return true
	endif
	
	GotoState("LockOn")
	return true
EndFunction


Function StopLockOn()
	GotoState("Busy")
	refLockon = None
	Game.EnablePlayerControls(false, false, false, true, false, false, false, false)
	GotoState("Ready")
EndFunction


Event OnKey_Lockon(bool IsDoubleTap)
	if (IsDoubleTap || _bChangeTarget)
		return
	endif
	
	if (CheckThumbstick())
		StopLockon()
	endif
EndEvent


Event OnKey_Left(int device, bool IsDoubleTap)
	if (_bPressLockonKey || (bDoubleTap && IsDoubleTap))
		Actor akTarget = FindNextTarget(fDistance, false)
		if (akTarget)
			StartLockon(akTarget)
		endif
	endif
EndEvent


Event OnKey_Right(int device, bool IsDoubleTap)
	if (_bPressLockonKey || (bDoubleTap && IsDoubleTap))
		Actor akTarget = FindNextTarget(fDistance, true)
		if (akTarget)
			StartLockon(akTarget)
		endif
	endif
EndEvent


Event OnKey_Down(int device, bool IsDoubleTap)
	if (_bPressLockonKey || (bDoubleTap && IsDoubleTap))
		Actor akTarget = None
		
		if (_player.IsInCombat() && _player.IsWeaponDrawn())
			akTarget = FindClosestCombatTarget(fDistance)
		endif
		
		if (!akTarget)
			akTarget = FindClosestTarget(fDistance)
		endif
		
		if (akTarget)
			StartLockon(akTarget)
		endif
	endif
EndEvent



Event Lockon_OnMouse(int x, int y)
	if (Utility.IsInMenuMode())
		return
	endif
	
	if (_bPressLockonKey)
		float absX = Math.Abs(x)
		float absY = Math.Abs(y)
		if (absX+absY > 64.0)
			_bChangeTarget = true
			int device = 0x0A;
			if (absX > absY)
				if (x > 0)
					OnKey_Right(device, false)
				else
					OnKey_Left(device, false)
				endif
			else
				if (y > 0)
					OnKey_Down(device, false)
				else
					OnKey_Up(device, false)
				endif
			endif
		endif
	endif
EndEvent


Event OnAnimationEvent(ObjectReference akSource, string eventName)
	if (eventName == "MountEnd")
		StopLockon()
	endif
EndEvent

EndState


;=====================================================================
; native functions
; (CAUTION) DO NOT CALL THESE FUNCTIONS DIRECTRY !!
;=====================================================================

Function SetPlayerAngle(float fRotZ, float fRotX, float fSpeed) global native
Function LookAt(float x, float y, float z, float fSpeed) global native
Function LookAtRef(ObjectReference akRef, float fSpeed) global native
ObjectReference Function GetCrosshairReference() global native
Actor[] Function FindCloseActor(float distance = 0.0, int sort = 0) native

bool Function IsValidActor(Actor akActor)
	if (akActor == None)
		return false
	endif
	if (_bExceptCorpse && akActor.IsDead())
		return false
	endif
	if (_bExceptFollower && akActor.IsPlayerTeammate())
		return false
	endif
	if (_bExceptFrendly && !akActor.IsHostileToActor(_player))
		return false
	endif
	if (_bExceptPrey && (akActor.IsInFaction(Game.GetForm(0x02E894) as Faction) || akActor.IsInFaction(Game.GetForm(0x0F1ABC) as Faction)))
		return false
	endif
	if (_bExceptSight && !_player.HasLos(akActor))
		return false
	endif
	return true
EndFunction


bool Function IsCombatTarget(Actor akActor)
	Actor target = akActor.GetCombatTarget()
	if (target != _player && !target.IsPlayerTeammate())
		return false
	endif
	if (akActor.IsEssential() && akActor.IsBleedingOut())
		return false
	endif
	if (akActor.IsChild())
		return false
	endif
	return true
EndFunction


Actor Function FindTarget(float distance)
	Actor crosshair = GetCrosshairReference() as Actor
	if (crosshair && IsValidActor(crosshair))
		return crosshair
	endif
	
	Actor[] actors = FindCloseActor(distance, 1)
	int i = 0
	while (i < actors.Length)
		if (IsValidActor(actors[i]))
			return actors[i]
		endif
		i += 1
	endwhile
EndFunction


Actor Function FindNextTarget(float distance, bool bRight)
	int order = 3
	if (bRight)
		order = 2
	endif
	
	Actor[] actors = FindCloseActor(distance, order)
	int i = 0
	while (i < actors.Length)
		Actor current = actors[i]
		if (current != refLockon && IsValidActor(current))
			return current
		endif
		i += 1
	endwhile
	return None
EndFunction


Actor Function FindClosestTarget(float distance)
	Actor[] actors = FindCloseActor(distance, 0)
	int i = 0
	while (i < actors.Length)
		Actor current = actors[i]
		if (current != refLockon && IsValidActor(current))
			return current
		endif
		i += 1
	endwhile
	return None
EndFunction


Actor Function FindClosestCombatTarget(float distance)
	Actor[] actors = FindCloseActor(distance, 0)
	int i = 0
	while (i < actors.Length)
		Actor current = actors[i]
		if (current != refLockon && IsCombatTarget(current))
			return current
		endif
		i += 1
	endwhile
	return None
EndFunction


bool Function IsGamepadEnabled() global native
Function SetCameraSpeed(float speed) global native

float Function GetThumbstickAxisX(int type) global native
float Function GetThumbstickAxisY(int type) global native

Function ResetMouse() global native
int Function GetMouseX() global native
int Function GetMouseY() global native

Function SendLockonStartEvent() native
Function SendLockonStopEvent() native
