#include <skse.h>
#include <skse/GameReferences.h>
#include <skse/GameCamera.h>
#include <skse/GameInput.h>
#include <skse/GameMenus.h>
#include <skse/GamePapyrusFunctions.h>
#include <skse/GamePapyrusEvents.h>

#include "Address.h"
#include "Papyrus.h"
#include "Utils.h"
#include "Hooks.h"
#include "Events.h"

#define _USE_MATH_DEFINES
#include <math.h>

#include <vector>
#include <algorithm>

/*
//=============================
// テスト中
//=============================

struct TargetInfo
{
	struct State
	{
		UInt32 handle;
		SInt32 hostility;
		UInt32 pad04[0x1D];
	};
	STATIC_ASSERT(sizeof(State) == 0x7C);

	UInt32 unk00;
	UInt32 unk04;
	tArray<State> targets;
	UInt32 pad14[(0xB8 - 0x14) >> 2];
	float  unkB8;
	float  unkBC;	// 敵を探している場合は0以外
};
STATIC_ASSERT(offsetof(TargetInfo, unkBC) == 0xBC);


struct UNK0D8
{
	TargetInfo* info;
	void*       unk04;

};


static UNK0D8* Get0D8(Actor* actor)
{
	return (UNK0D8*)((UInt32)actor + 0x0D8);
}

static int GetHostileValue(Actor* caster, Actor* target)
{
	int hostility = -1000;

	UNK0D8* p = Get0D8(caster);
	if (p)
	{
		TargetInfo* info = p->info;
		if (info)
		{
			UInt32 handle = target->CreateRefHandle();

			for (int i = 0; i < info->targets.count; i++)
			{
				if (handle == info->targets[i].handle)
				{
					hostility = info->targets[i].hostility;
					break;
				}
			}
		}
	}

	return hostility;
}
*/


// プレイヤーの居るセルの情報
struct UnkCellInfo
{
	UInt32          unk00;
	UInt32          unk04;
	UInt32          unk08;
	UInt32          unk0C;
	UInt32          unk10;
	UInt32          unk14;
	UInt32          unk18;
	UInt32          unk1C;
	UInt32          unk20;
	UInt32	        unk24;
	tArray<UInt32>  actorHandles;	// 28
	tArray<UInt32>  objectHandles;	// 34
};
STATIC_ASSERT(offsetof(UnkCellInfo, actorHandles) == 0x28);
STATIC_ASSERT(offsetof(UnkCellInfo, objectHandles) == 0x34);


static UnkCellInfo** s_cellInfo = (UnkCellInfo**)ADDR_UnkCellInfo;




class LockOn_Main : public TESQuest
{
public:
	// ゲームパッドが有効になっているかどうか調べる
	static bool IsGamepadEnabled(void)
	{
		return (*g_inputEventDispatcher && (*g_inputEventDispatcher)->IsGamepadEnabled());
	}

	// プレイヤーの角度を変更する
	static void SetPlayerAngle(float rotZ, float rotX, float wait)
	{
		PlayerCharacter* player = *g_thePlayer;
		TESCameraController* controller = TESCameraController::GetSingleton();

		if (wait < 20)
			wait = 20;

		controller->Rotate(player->rot.z, player->rot.x, rotZ, rotX, wait, 0);
	}
	
	// カメラを任意の座標に向ける
	static void LookAt(float posX, float posY, float posZ, float wait)
	{
		PlayerCharacter* player = *g_thePlayer;
		NiPoint3 cameraPos;
		double x, y, z, xy;
		double rotZ, rotX;
		
		GetCameraPos(&cameraPos);

		x = posX - cameraPos.x;
		y = posY - cameraPos.y;
		z = posZ - cameraPos.z;

		xy = sqrt(x*x + y*y);
		rotZ = atan2(x, y);
		rotX = atan2(-z, xy);
		
		if (rotZ - player->rot.z > M_PI)
			rotZ -= M_PI * 2;
		else if (rotZ - player->rot.z < -M_PI)
			rotZ += M_PI * 2;

		SetPlayerAngle(rotZ, rotX, wait);
	}

	// プレイヤーを対象に向ける
	static void LookAtRef(TESObjectREFR* akRef, float wait)
	{
		if (akRef == NULL)
			return;
		// akRef->Is3DLoaded()
		if (akRef->GetNiNode() == NULL)
			return;

		NiPoint3 targetPos;
		if (!GetTargetPos(akRef, &targetPos))
			return;

		LookAt(targetPos.x, targetPos.y, targetPos.z, wait);
	}

	// クロスヘアが当たっているオブジェクトを取得
	static TESObjectREFR* GetCrosshairReference(void)
	{
		CrosshairRefHandleHolder* crh = CrosshairRefHandleHolder::GetSingleton();
		UInt32 handle = crh->CrosshairRefHandle();
		TESObjectREFR* akRef = NULL;

		if (handle != *g_invalidRefHandle)
		{
			LookupREFRByHandle(&handle, &akRef);
		}

		return (Actor*)akRef;
	}

	// 一定距離内に居るアクターをすべて返す
	VMArray<Actor*> FindCloseActor(float distance, UInt32 sortOrder)
	{
		enum Order {
			kSortOrder_distance		= 0,		// 距離が近い順
			kSortOrder_crosshair	= 1,		// クロスヘアに近い順
			kSortOrder_zaxis_clock	= 2,		// Z軸時計回り
			kSortOrder_zaxis_rclock	= 3,		// Z軸逆時計回り
			kSortOrder_invalid      = 4
		};

		double fovThreshold = (double)PlayerCamera::GetSingleton()->worldFOV / 180.0 * M_PI /2;

		VMArray<Actor*> result;
		result.arr = NULL;

		tArray<UInt32>* actorHandles = &(*s_cellInfo)->actorHandles;
		if (actorHandles->count == 0)
			return result;

		std::vector<std::pair<double, Actor*>> vec;
		vec.reserve(actorHandles->count);

		PlayerCharacter* player = *g_thePlayer;
		NiPoint3 camPos;
		GetCameraPos(&camPos);

		UInt32 handle;
		size_t i = 0;
		while (actorHandles->GetNthItem(i++, handle))
		{
			TESObjectREFR* ref = NULL;
			if (handle != *g_invalidRefHandle)
				LookupREFRByHandle(&handle, &ref);

			if (ref && ref->formType == kFormType_Character)
			{
				Actor* actor = (Actor*)ref;
				NiPoint3 pos;
				GetTargetPos(actor, &pos);
				double dx = pos.x - camPos.x;
				double dy = pos.y - camPos.y;
				double dz = pos.z - camPos.z;
				double dd = sqrt(dx*dx + dy*dy + dz*dz);

				if (distance <= 0 || dd <= distance)
				{
					double point;
					NiPoint3 cameraAngle;
					GetCameraAngle(&cameraAngle);
					double angleZ = NormalRelativeAngle(atan2(dx, dy) - cameraAngle.z);
					double angleX = NormalRelativeAngle(atan2(-dz, sqrt(dx*dx + dy*dy)) - cameraAngle.x);
					
					if (abs(angleZ) < fovThreshold)
					{
						switch (sortOrder)
						{
						case kSortOrder_distance:
							point = dd;
							break;
						case kSortOrder_crosshair:
							point = sqrt(angleZ*angleZ + angleX*angleX);
							break;
						case kSortOrder_zaxis_clock:
							point = NormalAbsoluteAngle(atan2(dx, dy) - cameraAngle.z);
							break;
						case kSortOrder_zaxis_rclock:
							point = 2*M_PI - NormalAbsoluteAngle(atan2(dx, dy) - cameraAngle.z);
							break;
						default:
							point = 0;
							break;
						}

						if (point >= 0)
						{
							vec.push_back(std::make_pair(point, actor));
						}
					}
				}
			}
		}

		if (vec.size() == 0)
			return result;

		if (sortOrder < kSortOrder_invalid)
			std::sort(vec.begin(), vec.end());

		// Papyrusに返す配列を確保
		if (result.Allocate(vec.size()))
		{
			for (i = 0; i < vec.size(); i++)
			{
				result.Set(&vec[i].second, i);
			}
		}

		return result;
	}

	void SendLockonStartEvent(void)
	{
		if (this && this->IsRunning())
		{
			UInt32 handle;
			TESObjectREFR* refTarget = NULL;

			CALL_MEMBER_FN(this, CreateRefHandleByAliasID)(&handle, 0);
			if (handle != *g_invalidRefHandle)
				LookupREFRByHandle(&handle, &refTarget);

			if (refTarget && refTarget->formType == kFormType_Character)
			{
				PapyrusUtil::PapyrusEventArguments1<Actor*> args((Actor*)refTarget);
				SendLockonEvent(args, "OnLock");
			}
		}
	}

	void SendLockonStopEvent(void)
	{
		if (this && this->IsRunning())
		{
			UInt32 handle;
			TESObjectREFR* refTarget = NULL;

			CALL_MEMBER_FN(this, CreateRefHandleByAliasID)(&handle, 0);
			if (handle != *g_invalidRefHandle)
				LookupREFRByHandle(&handle, &refTarget);

			if (refTarget && refTarget->formType == kFormType_Character)
			{
				PapyrusUtil::PapyrusEventArguments1<Actor*> args((Actor*)refTarget);
				SendLockonEvent(args, "OnUnlock");
			}
		}
	}

	static void SetCameraSpeed(float speed)
	{
		g_cameraSpeed = speed;
	}

	static float GetThumbstickAxisX(UInt32 type)
	{
		if (type == 0x0B)
			return g_leftThumbstick.x;
		else if (type == 0x0C)
			return g_rightThumbstick.x;

		return 0;
	}

	static float GetThumbstickAxisY(UInt32 type)
	{
		if (type == 0x0B)
			return g_leftThumbstick.y;
		else if (type == 0x0C)
			return g_rightThumbstick.y;

		return 0;
	}

	static void ResetMouse(void)
	{
		g_mousePosition.x = 0;
		g_mousePosition.y = 0;
	}

	static SInt32 GetMouseX(void)
	{
		return g_mousePosition.x;
	}

	static SInt32 GetMouseY(void)
	{
		return g_mousePosition.y;
	}

private:
	// 全てのアドオンにロックオンイベントを送る
	void SendLockonEvent(IFunctionArguments& args, const char* eventName)
	{
		BGSListForm* list = GetQuestList();

		if (list && list->forms.count)
		{
			VMClassRegistry* registry = (*g_skyrimVM)->GetClassRegistry();
			IObjectHandlePolicy* policy = registry->GetHandlePolicy();
			BSFixedString eventString(eventName);

			for(int i = 0; i < list->forms.count; i++)
			{
				if (list->forms[i] && list->forms[i]->formType == kFormType_Quest)
				{
					TESQuest* quest = (TESQuest*)list->forms[i];
					if (quest && quest->IsRunning())
					{
						UInt64 handle = policy->Create(quest->kTypeID, quest);
						registry->QueueEvent(handle, &eventString, &args);
					}
				}
			}
		}
	}
};


namespace Papyrus
{
	// パピルス関数を登録するときに呼ばれる
	void Init()
	{
		VMClassRegistry* registry = (*g_skyrimVM)->GetClassRegistry();

		REGISTER_PAPYRUS_FUNCTION(LockOn_Main, IsGamepadEnabled, registry, VMClassRegistry::kFunctionFlag_NoWait);
		REGISTER_PAPYRUS_FUNCTION(LockOn_Main, SetPlayerAngle, registry);
		REGISTER_PAPYRUS_FUNCTION(LockOn_Main, LookAt, registry);
		REGISTER_PAPYRUS_FUNCTION(LockOn_Main, LookAtRef, registry);
		REGISTER_PAPYRUS_FUNCTION(LockOn_Main, GetCrosshairReference, registry);
		REGISTER_PAPYRUS_FUNCTION(LockOn_Main, FindCloseActor, registry);
		REGISTER_PAPYRUS_FUNCTION(LockOn_Main, SendLockonStartEvent, registry);
		REGISTER_PAPYRUS_FUNCTION(LockOn_Main, SendLockonStopEvent, registry);
		REGISTER_PAPYRUS_FUNCTION(LockOn_Main, SetCameraSpeed, registry, VMClassRegistry::kFunctionFlag_NoWait);
		REGISTER_PAPYRUS_FUNCTION(LockOn_Main, GetThumbstickAxisX, registry, VMClassRegistry::kFunctionFlag_NoWait);
		REGISTER_PAPYRUS_FUNCTION(LockOn_Main, GetThumbstickAxisY, registry, VMClassRegistry::kFunctionFlag_NoWait);
		REGISTER_PAPYRUS_FUNCTION(LockOn_Main, ResetMouse, registry, VMClassRegistry::kFunctionFlag_NoWait);
		REGISTER_PAPYRUS_FUNCTION(LockOn_Main, GetMouseX, registry, VMClassRegistry::kFunctionFlag_NoWait);
		REGISTER_PAPYRUS_FUNCTION(LockOn_Main, GetMouseY, registry, VMClassRegistry::kFunctionFlag_NoWait);
	}
}

