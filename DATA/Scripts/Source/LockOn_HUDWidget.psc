Scriptname LockOn_HUDWidget extends LockOn_HUDWidgetBase

; @override SKI_WidgetBase
event OnWidgetInit()
	parent.OnWidgetInit()
	VAnchor = "top"
	Y = 400;
endEvent

event OnWidgetReset()
	parent.OnWidgetReset()
endEvent

