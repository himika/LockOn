Scriptname LockOn_MCM extends SKI_ConfigBase

LockOn_Main Property LockonQuest Auto

;=======================
; version
;=======================

int Function GetVersion()
;	return 1		; 1.6
;	return 2		; 1.7 / 1.8 / 2.0
	return 3		; 3.0
EndFunction


;=======================
; constants
;=======================

float Property      DEFAULT_SPEED           = 500.0     autoReadonly
bool  Property      DEFAULT_DOUBLE_TAP      = false     autoReadonly
float Property      DEFAULT_DISTANCE        = 2048.0    autoReadonly
bool  Property      DEFAULT_AUTO_AGGRESSOR  = false     autoReadonly
bool  Property      DEFAULT_AUTO_TARGET     = false     autoReadonly
bool  Property      DEFAULT_AUTO_COMBAT     = false     autoReadonly
int   Property      DEFAULT_AUTO_DEAD       = 1         autoReadonly
bool  Property      DEFAULT_EXCEPT_SIGHT    = true      autoReadonly
bool  Property      DEFAULT_EXCEPT_CORPSE   = true      autoReadonly
bool  Property      DEFAULT_EXCEPT_FOLLOWER = false     autoReadonly
bool  Property      DEFAULT_EXCEPT_FRENDLY  = false     autoReadonly
bool  Property      DEFAULT_EXCEPT_PREY     = true      autoReadonly

;=======================
; properties
;=======================

int Property keyLockon
	int Function Get()
		return _keyLockon
	EndFunction
	Function Set(int KeyCode)
		_keyLockon = KeyCode
		SetKeymapOptionValue(_keymap_lockon, _keyLockon)
		LockonQuest.keyLockon = KeyCode
	EndFunction
EndProperty

bool Property bDoubleTap
	bool Function Get()
		return _bDoubleTap
	EndFunction
	Function Set (bool value)
		_bDoubleTap = value
		SetToggleOptionValue(_toggle_doubleTap, _bDoubleTap)
		LockonQuest.bDoubleTap = value
	EndFunction
EndProperty

float Property fSpeed
	float Function Get()
		return _fSpeed
	EndFunction
	Function Set(float value)
		_fSpeed = value
		SetSliderOptionValue(_slider_speed, _fSpeed, "{0} msec")
		LockonQuest.fSpeed = value
	EndFunction
EndProperty

float Property fDistance
	float Function Get()
		return _fDistance
	EndFunction
	Function Set(float value)
		_fDistance = value
		SetSliderOptionValue(_slider_distance, _fDistance, "{0} units")
		LockonQuest.fDistance = value
	EndFunction
EndProperty

bool Property bAutoTarget
	bool Function Get()
		return _bAutoTarget
	EndFunction
	Function Set(bool value)
		_bAutoTarget = value
		SetToggleOptionValue(_toggle_autoTarget, _bAutoTarget)
		LockonQuest.bAutoTarget = value
	EndFunction
EndProperty

bool Property bAutoAggressor
	bool Function Get()
		return _bAutoAggressor
	EndFunction
	Function Set(bool value)
		_bAutoAggressor = value
		SetToggleOptionValue(_toggle_autoAggressor, _bAutoAggressor)
		LockonQuest.bAutoAggressor = value
	EndFunction
EndProperty

bool Property bAutoCombat
	bool Function Get()
		return _bAutoCombat
	EndFunction
	Function Set(bool value)
		_bAutoCombat = value
		SetToggleOptionValue(_toggle_autoCombat, _bAutoCombat)
		LockonQuest.bAutoCombat = value
	EndFunction
EndProperty

int Property iAutoDead
	int Function Get()
		return _iAutoDead
	EndFunction
	Function Set(int value)
		if (value >= 0 && value < _sAutoDeadIdx.Length)
			_iAutoDead = value
			SetMenuOptionValue(_menu_autoDead, _sAutoDeadIdx[_iAutoDead])
			LockonQuest.iAutoDead = _iAutoDead
		endif
	EndFunction
EndProperty

bool Property bExceptSight
	bool Function Get()
		return _bExceptSight
	EndFunction
	Function Set(bool value)
		_bExceptSight = value
		SetToggleOptionValue(_toggle_exceptSight, value)
		LockonQuest.bExceptSight = value
	EndFunction
EndProperty

bool Property bExceptCorpse
	bool Function Get()
		return _bExceptCorpse
	EndFunction
	Function Set(bool value)
		_bExceptCorpse = value
		SetToggleOptionValue(_toggle_exceptCorpse, value)
		LockonQuest.bExceptCorpse = value
	EndFunction
EndProperty

bool Property bExceptFollower
	bool Function Get()
		return _bExceptFollower
	EndFunction
	Function Set(bool value)
		_bExceptFollower = value
		SetToggleOptionValue(_toggle_exceptFollower, value)
		LockonQuest.bExceptFollower = value
	EndFunction
EndProperty

bool Property bExceptFrendly
	bool Function Get()
		return _bExceptFrendly
	EndFunction
	Function Set(bool value)
		_bExceptFrendly = value
		SetToggleOptionValue(_toggle_exceptFrendly, value)
		LockonQuest.bExceptFrendly = value
	EndFunction
EndProperty

bool Property bExceptPrey
	bool Function Get()
		return _bExceptPrey
	EndFunction
	Function Set(bool value)
		_bExceptPrey = value
		SetToggleOptionValue(_toggle_exceptPrey, value)
		LockonQuest.bExceptPrey = value
	EndFunction
EndProperty

FormList Property AddonQuestList Auto


;=======================
; private variables
;=======================

int _modIndex

; MCM options
int _keymap_lockon
int _toggle_doubleTap
int _slider_speed
int _slider_distance
int _menu_effect
int _toggle_autoAggressor
int _toggle_autoTarget
int _toggle_autoCombat
int _menu_autoDead
int _toggle_exceptSight
int _toggle_exceptCorpse
int _toggle_exceptFollower
int _toggle_exceptFrendly
int _toggle_exceptPrey
int _text_active
int[] _toggle_addons

; LockOn_Main variables
int    _keyLockon
bool   _bDoubleTap
float  _fSpeed
float  _fDistance
bool   _bAutoTarget
bool   _bAutoCombat
bool   _bAutoAggressor
int    _iAutoDead
bool   _bExceptSight
bool   _bExceptCorpse
bool   _bExceptFollower
bool   _bExceptFrendly
bool   _bExceptPrey

; quest starter
bool   _bStartReserve
bool   _bQuestStartReserve
bool[] _bAddonStartReserve

string[] _sAutoDeadIdx

;=======================
; initialization
;=======================

Event OnConfigInit()
	Pages = new string[1]
	Pages[0] = "Add-ons"
	
	_toggle_addons = new int[128]
	
	_keyLockon = Input.GetMappedKey("Run")
	if (_keyLockon == -1)
		_keyLockon = Input.GetMappedKey("Sprint")
	endif
	_bDoubleTap = DEFAULT_DOUBLE_TAP
	_fSpeed = DEFAULT_SPEED
	_fDistance = DEFAULT_DISTANCE
	_bAutoTarget = DEFAULT_AUTO_TARGET
	_bAutoAggressor = DEFAULT_AUTO_AGGRESSOR
	_bAutoCombat = DEFAULT_AUTO_COMBAT
	_iAutoDead = DEFAULT_AUTO_DEAD
	_bExceptSight = DEFAULT_EXCEPT_SIGHT
	_bExceptCorpse = DEFAULT_EXCEPT_CORPSE
	_bExceptFollower = DEFAULT_EXCEPT_FOLLOWER
	_bExceptFrendly = DEFAULT_EXCEPT_FRENDLY
	_bExceptPrey = DEFAULT_EXCEPT_PREY
	
	_bStartReserve = false
	_bQuestStartReserve = false
	_bAddonStartReserve = new bool[128]
	int idx = 0
	while (idx < _bAddonStartReserve.Length)
		_bAddonStartReserve[idx] = false
		idx += 1
	endwhile
EndEvent


Event OnGameReload()
	_modIndex = Math.RightShift(self.GetFormID(), 24)
	
	Parent.OnGameReload()
EndEvent


Event OnVersionUpdate(int a_version)
	if (CurrentVersion <= 1)		; 0.1.6
	endif
EndEvent


Function InitVariables()
	_keyLockon = LockonQuest.keyLockOn
	if (_keyLockon == -1)
		_keyLockon = Input.GetMappedKey("Run")
	endif
	_bDoubleTap = LockonQuest.bDoubleTap
	_fSpeed = LockonQuest.fSpeed
	_fDistance = LockonQuest.fDistance
	_bAutoTarget = LockonQuest.bAutoTarget
	_bAutoAggressor = LockonQuest.bAutoAggressor
	_bAutoCombat = LockonQuest.bAutoCombat
	_iAutoDead = LockonQuest.iAutoDead
	_bExceptSight = LockonQuest.bExceptSight
	_bExceptCorpse = LockonQuest.bExceptCorpse
	_bExceptFollower = LockonQuest.bExceptFollower
	_bExceptFrendly = LockonQuest.bExceptFrendly
	_bExceptPrey = LockonQuest.bExceptPrey
	
	_sAutoDeadIdx = new string[4];
	_sAutoDeadIdx[0] = "解除"
	_sAutoDeadIdx[1] = "最寄りの敵"
	_sAutoDeadIdx[2] = "ロック維持"
	if (_iAutoDead < 0 || iAutoDead > 2)
		_iAutoDead = DEFAULT_AUTO_DEAD
	endif
EndFunction


;=======================
; events
;=======================

string _page

Event OnPageReset(string page)
	_page = page
	
	if (page == "")
		bool bEnabled = LockonQuest.IsRunning()
		
		if (bEnabled)
			InitVariables()
		endif
		
		SetCursorFillMode(TOP_TO_BOTTOM)
		if (bEnabled)
			AddHeaderOption("Settings")
			_keymap_lockon = AddKeyMapOption("Lock-On キー", keyLockon)
			_toggle_doubleTap = AddToggleOption("ダブルタップで次の対象に", bDoubleTap)
			_slider_speed = AddSliderOption("カメラの移動速度", fSpeed, "{0} msec")
			_slider_distance = AddSliderOption("ロックオン可能距離", fDistance, "{0} units")
			AddEmptyOption()
		endif
		
		AddHeaderOption("Activate/Deactivate Lock-On")
		if (bEnabled)
			_text_active = AddTextOption("", "Click to Deactivate")
		elseif (_bQuestStartReserve)
			_text_active = AddTextOption("", "Exit Menus to Deactivate")
		else
			_text_active = AddTextOption("", "Click to Activate")
		endif
		
		if (bEnabled)
			SetCursorPosition(1)
			
			AddHeaderOption("オートターゲット")
			_toggle_autoAggressor = AddToggleOption("攻撃を受けた時", bAutoAggressor)
			_toggle_autoTarget = AddToggleOption("攻撃した時", bAutoTarget)
			_toggle_autoCombat = AddToggleOption("戦闘が始まった時", bAutoCombat)
			_menu_autoDead = AddMenuOption("ターゲット死亡時", _sAutoDeadIdx[_iAutoDead])
			AddEmptyOption()
			
			AddHeaderOption("除外する対象")
			_toggle_exceptSight = AddToggleOption("視界外", bExceptSight)
			_toggle_exceptCorpse = AddToggleOption("死体", bExceptCorpse)
			_toggle_exceptFollower = AddToggleOption("フォロワー", bExceptFollower)
			_toggle_exceptFrendly = AddToggleOption("友好的な人物", bExceptFrendly)
			_toggle_exceptPrey = AddToggleOption("家畜・獲物", bExceptPrey)
			AddEmptyOption()
		endif
		
	elseif (page == "Add-ons")
		SetCursorFillMode(TOP_TO_BOTTOM)
		
		AddHeaderOption("Activate/Deactivate Addons")
		int idx = 0
		int len = AddonQuestList.GetSize()
		if (len > _toggle_addons.Length)
			len = _toggle_addons.Length
		endif
		while (idx < len)
			LockOn_AddonBase addon = AddonQuestList.GetAt(idx) as LockOn_AddonBase
			
			if (addon && addon.CanDeactivate)
				_toggle_addons[idx] = AddToggleOption(addon.GetName(), (addon.IsRunning() || _bAddonStartReserve[idx]))
			else
				_toggle_addons[idx] = -1
			endif
			idx += 1
		endwhile
	endif
EndEvent


Event OnOptionDefault(int option)
	if (_page == "")
		if (option == _slider_speed)
			fSpeed = DEFAULT_SPEED
		elseif (option == _toggle_doubleTap)
			bDoubleTap = DEFAULT_DOUBLE_TAP
		elseif (option == _slider_distance)
			fDistance = DEFAULT_DISTANCE
		elseif (option == _keymap_lockon)
			keyLockon = Input.GetMappedKey("Run")
		elseif (option == _toggle_autoAggressor)
			bAutoAggressor = DEFAULT_AUTO_AGGRESSOR
		elseif (option == _toggle_autoTarget)
			bAutoTarget = DEFAULT_AUTO_TARGET
		elseif (option == _toggle_autoCombat)
			bAutoCombat = DEFAULT_AUTO_COMBAT
		elseif (option == _toggle_exceptSight)
			bExceptSight = DEFAULT_EXCEPT_SIGHT
		elseif (option == _toggle_exceptCorpse)
			bExceptCorpse = DEFAULT_EXCEPT_CORPSE
		elseif (option == _toggle_exceptFollower)
			bExceptFollower = DEFAULT_EXCEPT_FOLLOWER
		elseif (option == _toggle_exceptFrendly)
			bExceptFrendly = DEFAULT_EXCEPT_FRENDLY
		elseif (option == _toggle_exceptFrendly)
			bExceptPrey = DEFAULT_EXCEPT_PREY
		endif
	endif
EndEvent


Event OnOptionSliderOpen(int option)
	if (_page == "")
		if (option == _slider_speed)
			SetSliderDialogStartValue(fSpeed)
			SetSliderDialogDefaultValue(DEFAULT_SPEED)
			SetSliderDialogRange(50, 2000)
			SetSliderDialogInterval(50)
		elseif (option == _slider_distance)
			SetSliderDialogStartValue(fDistance)
			SetSliderDialogDefaultValue(DEFAULT_DISTANCE)
			SetSliderDialogRange(128, 8192)
			SetSliderDialogInterval(128)
		endif
	endif
EndEvent


Event OnOptionSliderAccept(int option, float value)
	if (_page == "")
		if (option == _slider_speed)
			fSpeed = value
		elseif (option == _slider_distance)
			fDistance = value
		endif
	endif
EndEvent


Event OnOptionMenuOpen(int option)
	if (_page == "")
		if (option == _menu_autoDead)
			SetMenuDialogOptions(_sAutoDeadIdx)
			SetMenuDialogStartIndex(_iAutoDead)
			SetMenuDialogDefaultIndex(DEFAULT_AUTO_DEAD)
		endif
	endif
EndEvent


Event OnOptionMenuAccept(int option, int index)
	if (_page == "")
		if (option == _menu_autoDead)
			iAutoDead = index
		endif
	endif
EndEvent


Event OnOptionKeyMapChange(int option, int KeyCode, string conflictControl, string conflictName)
	if (option == _keymap_lockon)
		keyLockon = KeyCode
	endif
EndEvent


Event OnOptionSelect(int option)
	if (_page == "")
		if (option == _toggle_doubleTap)
			bDoubleTap = !bDoubleTap
		elseif (option == _toggle_autoAggressor)
			bAutoAggressor = !bAutoAggressor
		elseif (option == _toggle_autoTarget)
			bAutoTarget = !bAutoTarget
		elseif (option == _toggle_autoCombat)
			bAutoCombat = !bAutoCombat
		elseif (option == _toggle_exceptSight)
			bExceptSight = !bExceptSight
		elseif (option == _toggle_exceptCorpse)
			bExceptCorpse = !bExceptCorpse
		elseif (option == _toggle_exceptFollower)
			bExceptFollower = !bExceptFollower
		elseif (option == _toggle_exceptFrendly)
			bExceptFrendly = !bExceptFrendly
		elseif (option == _toggle_exceptPrey)
			bExceptPrey = !bExceptPrey
		elseif (option == _text_active)
			if (LockonQuest.IsRunning())
				LockonQuest.Stop()
				ForcePageReset()
			elseif (_bQuestStartReserve)
			else
				SetTextOptionValue(_text_active, "Exit Menus To Activate MOD")
				StartLockonQuest()
			endif
		endif
	elseif (_page == "Add-ons")
		int idx = 0
		int len = AddonQuestList.GetSize()
		if (len > _toggle_addons.Length)
			len = _toggle_addons.Length
		endif
		while (idx < len)
			if (_toggle_addons[idx] != -1 && option == _toggle_addons[idx])
				LockOn_AddonBase addon = AddonQuestList.GetAt(idx) as LockOn_AddonBase
				if (addon.IsRunning())
					SetToggleOptionValue(option, false)
					addon.Stop()
				else
					SetToggleOptionValue(option, true)
					StartAddonQuest(idx)
				endif
				len = 0
			endif
			idx += 1
		endwhile
	endif
endEvent


Event OnOptionHighlight(int option)
	if (_page == "")
		if (option == _slider_speed)
			SetInfoText("speed")
		elseif (option == _text_active)
			if (LockonQuest.IsRunning())
				SetInfoText("Toggle this option off to deactivate the mod.")
			elseif (_bQuestStartReserve)
				SetInfoText("Exit menus to activate the mod.")
			else
				SetInfoText("Toggle this option on to activate the mod.")
			endif
		endif
	elseif (_page == "Add-ons")
		int idx = 0
		int len = AddonQuestList.GetSize()
		if (len > _toggle_addons.Length)
			len = _toggle_addons.Length
		endif
		while (idx < len)
			if (option == _toggle_addons[idx])
				LockOn_AddonBase addon = AddonQuestList.GetAt(idx) as LockOn_AddonBase
				SetInfoText(addon.AddonDescription)
				len = 0
			endif
			idx += 1
		endwhile
	endif
EndEvent


;===========================
; Quest Restarter
;===========================

Function StartLockonQuest()
	_bQuestStartReserve = true;
	
	if (_bStartReserve == false)
		RegisterForSingleUpdate(0.1)
	endif
	_bStartReserve = true
	CloseMenu()
EndFunction


Function StartAddonQuest(int idx)
	_bAddonStartReserve[idx] = true;
	
	if (_bStartReserve == false)
		RegisterForSingleUpdate(0.1)
	endif
	_bStartReserve = true
EndFunction

Event OnUpdate()
	if (LockonQuest && !LockonQuest.IsRunning())
		if (LockonQuest.Start())
			LockonQuest.keyLockon = keyLockon
			LockonQuest.bDoubleTap = bDoubleTap
			LockonQuest.fSpeed = fSpeed
			LockonQuest.fDistance = fDistance
			LockonQuest.bAutoAggressor = bAutoAggressor
			LockonQuest.bAutoTarget = bAutoTarget
			LockonQuest.bAutoCombat = bAutoCombat
			LockonQuest.bExceptSight = bExceptSight
			LockonQuest.bExceptCorpse = bExceptCorpse
			LockonQuest.bExceptFollower = bExceptFollower
			LockonQuest.bExceptFrendly = bExceptFrendly
			LockonQuest.bExceptPrey = bExceptPrey
		endif
	endif
	
	int idx = 0
	int len = AddonQuestList.GetSize()
	if (len > _bAddonStartReserve.Length)
		len = _bAddonStartReserve.Length
	endif
	while (idx < len)
		if (_bAddonStartReserve[idx])
			_bAddonStartReserve[idx] = false
			LockOn_AddonBase addon = AddonQuestList.GetAt(idx) as LockOn_AddonBase
			if (addon && !addon.IsRunning())
				if (addon.Start() == false)
					Debug.Trace("failed to start this add-on: " + addon.GetName())
				endif
			endif
		endif
		idx += 1
	endwhile
	
	_bStartReserve = false
	_bQuestStartReserve = false
EndEvent

Function CloseMenu()
	UI.InvokeBool("Journal Menu", "_root.QuestJournalFader.Menu_mc.CloseMenu", false)
EndFunction

