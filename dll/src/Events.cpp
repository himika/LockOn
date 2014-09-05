#include <skse.h>
#include <skse/GameObjects.h>
#include <skse/GameReferences.h>
#include <skse/GameTESEvents.h>
#include <skse/GameInput.h>
#include <skse/GameRTTI.h>
#include <skse/GamePapyrusEvents.h>

#include "Address.h"
#include "Events.h"
#include "Papyrus.h"
#include "Hooks.h"
#include "Utils.h"

ThumbstickInfo g_leftThumbstick = {0, 0};
ThumbstickInfo g_rightThumbstick = {0, 0};
MouseInfo g_mousePosition = {0, 0};


EventResult OnCombatEvent(TESCombatEvent* evn)
{
#ifdef _DEBUG
	const char* casterName = GetActorName(evn->caster);
	const char* targetName = GetActorName(evn->target);

	switch (evn->state)
	{
	case 0:
		_MESSAGE("CombatEvent: %s (not in combat)", casterName);
		break;
	case 1:
		_MESSAGE("CombatEvent: %s => %s (start combat)", casterName, targetName);
		break;
	case 2:
		_MESSAGE("CombatEvent: %s => %s (searching)", casterName, targetName);
		break;
	}
#endif
	if (evn->state != 1)
		return kEvent_Continue;

	if (evn->target == NULL)
		return kEvent_Continue;

	if (evn->caster == NULL)
		return kEvent_Continue;

	PlayerCharacter* player = *g_thePlayer;
	if (evn->caster == player)
		return kEvent_Continue;

	Actor* enemy = NULL;

	if (evn->target == player || IsPlayerTeammate(evn->target))
		enemy = evn->caster;
	else if (IsPlayerTeammate(evn->caster))
		enemy = evn->target;

	if (enemy)
	{
		TESQuest* quest = GetLockOnQuest();
		if (quest && quest->IsRunning())
		{
			BGSBaseAlias* baseAlias;
			quest->aliases.GetNthItem(1, baseAlias);
			BGSRefAlias*  refAlias = (BGSRefAlias*)baseAlias;
			static BSFixedString eventName = "Lockon_OnCombatStart";
			
			PapyrusUtil::SendEvent(refAlias, &eventName, enemy);
		}
	}

	return kEvent_Continue;
}


EventResult OnHitEvent(TESHitEvent* evn)
{
	if (evn->caster != *g_thePlayer)
		return kEvent_Continue;

	TESQuest* quest = GetLockOnQuest();

	if (quest && quest->IsRunning())
	{
		BGSBaseAlias* baseAlias;
		quest->aliases.GetNthItem(1, baseAlias);
		BGSRefAlias*  refAlias = (BGSRefAlias*)baseAlias;

		TESForm* akSource = NULL;
		BGSProjectile* akProjectile = NULL;
		
		if (evn->sourceID != 0)
		{
			akSource = LookupFormByID(evn->sourceID);
			if (akSource != NULL) {
				if (akSource->formType != kFormType_Weapon
					&& akSource->formType != kFormType_Explosion
					&& akSource->formType != kFormType_Spell
					&& akSource->formType != kFormType_Ingredient
					&& akSource->formType != kFormType_Potion
					&& akSource->formType != kFormType_Enchantment)
				{
					akSource = NULL;
				}
			}
		}

		if (evn->projectileID != 0)
		{
			akProjectile = (BGSProjectile*)LookupFormByID(evn->projectileID);
			if (akProjectile != NULL && akProjectile->formType != kFormType_Projectile)
			{
				akProjectile = NULL;
			}
		}
		static BSFixedString eventName = "Lockon_OnPlayerHit";
		PapyrusUtil::SendEvent(refAlias, &eventName, evn->target, akSource, akProjectile);
	}

	return kEvent_Continue;
}


static void OnThumbstickEvent(ThumbstickEvent* evt, TESQuest* quest)
{
	static bool bThumbstickLeft  = false;
	static bool bThumbstickRight = false;

	bool  bTrigger = false;
	bool  bState = (evt->x != 0 || evt->y != 0);

	if (evt->keyMask == evt->kInputType_LeftThumbstick)
	{
		g_leftThumbstick.x = evt->x;
		g_leftThumbstick.y = evt->y;

		if (bThumbstickLeft != bState)
		{
			bThumbstickLeft = bState;
			bTrigger = true;
		}
	}
	else if (evt->keyMask == evt->kInputType_RightThumbstick)
	{
		g_rightThumbstick.x = evt->x;
		g_rightThumbstick.y = evt->y;

		if (bThumbstickRight != bState)
		{
			bThumbstickRight = bState;
			bTrigger = true;
		}
	}

	if (bTrigger)
	{
		static BSFixedString eventName = "Lockon_OnThumbstick";
		PapyrusUtil::SendEvent(quest, &eventName, evt->keyMask, evt->x, evt->y);
	}
}


static void OnMouseMoveEvent(MouseMoveEvent* evt, TESQuest* quest)
{
	static bool   bMoving = false;
	static SInt32 totalX = 0;
	static SInt32 totalY = 0;
	
	if (evt->source != evt->kInputType_Mouse)
		return;
	
	bool  bTrigger = false;
	bool  bState = (evt->moveX != 0 || evt->moveY != 0);
	// _MESSAGE("MouseMove: %08X %08X %08X", evt->source, evt->moveX, evt->moveY);
	
	totalX += evt->moveX;
	totalY += evt->moveY;
	g_mousePosition.x += evt->moveX;
	g_mousePosition.y += evt->moveY;

	if (g_mousePosition.x > MOUSE_THRESHOLD)
		g_mousePosition.x = MOUSE_THRESHOLD;
	if (g_mousePosition.x < -MOUSE_THRESHOLD)
		g_mousePosition.x = -MOUSE_THRESHOLD;
	if (g_mousePosition.y > MOUSE_THRESHOLD)
		g_mousePosition.y = MOUSE_THRESHOLD;
	if (g_mousePosition.y < -MOUSE_THRESHOLD)
		g_mousePosition.y = -MOUSE_THRESHOLD;

	if (bMoving != bState)
	{
		bMoving = bState;
		bTrigger = true;
	}
	
	if (bTrigger && bState == false)
	{
		static BSFixedString eventName = "Lockon_OnMouse";
		PapyrusUtil::SendEvent(quest, &eventName, totalX, totalY);
	}
}



EventResult OnInputEvent(InputEvent** evn)
{
	TESQuest* quest = GetLockOnQuest();
	if (!quest || !quest->IsRunning())
		return kEvent_Continue;

	for (InputEvent* e = *evn; e; e = e->next)
	{
		if (e->eventType == InputEvent::kEventType_Thumbstick)
		{
			ThumbstickEvent * t = DYNAMIC_CAST(e, InputEvent, ThumbstickEvent);
			OnThumbstickEvent(t, quest);
		}
		else if (e->eventType == InputEvent::kEventType_MouseMove)
		{
			MouseMoveEvent * t = DYNAMIC_CAST(e, InputEvent, MouseMoveEvent);
			OnMouseMoveEvent(t, quest);
		}
	}

	return kEvent_Continue;
}



#include <skse/SafeWrite.h>
#include "HookUtil.h"

static void Hook_OnCombat(UInt32* stack, UInt32 ecx)
{
	OnCombatEvent((TESCombatEvent*)stack[1]);
}

namespace Events
{
	void Init(void)
	{
		g_hitEventSource += OnHitEvent;
		g_inputEventSource += OnInputEvent;

		// g_combatEventSource += OnCombatEvent;
		HookRelCall(ADDR_OnCombat, Hook_OnCombat);
	}
}

