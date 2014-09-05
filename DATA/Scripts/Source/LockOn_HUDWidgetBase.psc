Scriptname LockOn_HUDWidgetBase Extends SKI_WidgetBase

; -------------------------------------------------------------------------------------------------

; @override SKI_WidgetBase
event OnWidgetReset()
	parent.OnWidgetReset()
endEvent

; @overrides SKI_WidgetBase
string function GetWidgetSource()
	return "LockOn/Marker.swf"
endFunction

; @overrides SKI_WidgetBase
string function GetWidgetType()
	return "LockOn_HUDWidgetBase"
endFunction


Function EnterLockOn()
	UI.Invoke(HUD_MENU, WidgetRoot + ".enterLockOn")
EndFunction


Function LeaveLockOn()
	UI.Invoke(HUD_MENU, WidgetRoot + ".leaveLockOn")
EndFunction
