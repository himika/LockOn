#include <skse.h>
#include <skse/GameReferences.h>
#include <skse/GameObjects.h>
#include <skse/GameInput.h>
#include <skse/GameMenus.h>
#include <skse/GameCamera.h>
#include <skse/GameRTTI.h>
#include <skse/GamePapyrusFunctions.h>
#include <skse/PapyrusVM.h>

#define _USE_MATH_DEFINES
#include <math.h>

#include "Address.h"
#include "Utils.h"
#include "Events.h"
#include "Hooks.h"


float g_cameraSpeed = 500.0;
double g_targetPosX = 0.0f;
double g_targetPosY = 0.0f;
double g_targetDist = 0.0f;
UInt32 g_targetFormID = 0;
const char* g_targetName = NULL;

static bool &s_bInvertYValues = *(bool*)ADDR_bInvertYValues;

typedef void (*_InvokeIntA)(StaticFunctionTag* thisInput, BSFixedString menuName, BSFixedString targetStr, VMArray<UInt32> args);
static _InvokeIntA InvokeIntA = NULL;


DEFINE_MEMBER_FN_EX(PlayerCharacter, SetAngleZ, void, ADDR_SetAngleZ, float)
DEFINE_MEMBER_FN_EX(PlayerCharacter, SetAngleX, void, ADDR_SetAngleX, float)


template <class T>
struct _SharedPtrInternal
{
public:
	static void IncRef(T* p);
	static void DecRef(T* p);
};


template <>
struct _SharedPtrInternal<TESObjectREFR>
{
	static void IncRef(TESObjectREFR* p) {p->handleRefObject.IncRef();}
	static void DecRef(TESObjectREFR* p) {p->handleRefObject.DecRefHandle();}
};


template <class T, class I=_SharedPtrInternal<T>>
class SharedPtr
{
public:
	SharedPtr() : pointer(NULL) {}
	~SharedPtr()
	{
		if (pointer)
			I::DecRef(pointer);
	}

	operator T*()	{return pointer;}
	T* operator->()		{return pointer;}
	bool operator!()	{return pointer != NULL;}

	SharedPtr& operator=(T* refr) {
		I::IncRef(refr);
		if (pointer)
			I::DecRef(pointer);
		pointer = refr;
		return *this;
	}

	bool LookupByHandle(UInt32 handle) {
		return LookupSharedPtrByHandle(handle, this);
	}

private:
	T* pointer;
};

template<class T>
bool LookupSharedPtrByHandle(UInt32 handle, SharedPtr<T>* mp)
{
	bool (*Lookup)(UInt32*, SharedPtr<T>*) = (bool (*)(UInt32*, SharedPtr<T>*))ADDR_LookupSharedPtrByHandle;
	return Lookup(&handle, mp);
}




// プレイヤーとターゲットのなす角を計算する
static void CalcAngle(NiPoint3* targetPos, AngleZX* angle)
{
	PlayerCharacter* player = *g_thePlayer;
	AngleZX baseAngle;
	NiPoint3 cameraPos;

	GetCameraPos(&cameraPos);
	GetAngle(cameraPos, *targetPos, &baseAngle);

	double angleDiffZ = baseAngle.z - (double)player->rot.z;
	double angleDiffX = baseAngle.x - (double)player->rot.x;

	// アナログスティックで角度を微調整できるようにする
	if(*g_inputEventDispatcher && (*g_inputEventDispatcher)->IsGamepadEnabled())
	{
		double angle = atan2(128.0, baseAngle.distance);
		angleDiffZ += (double)g_rightThumbstick.x * angle;

		if (s_bInvertYValues)
			angleDiffX += (double)g_rightThumbstick.y * angle;
		else
			angleDiffX -= (double)g_rightThumbstick.y * angle;
	}

	angle->z = NormalRelativeAngle(angleDiffZ);
	angle->x = NormalRelativeAngle(angleDiffX);
	angle->distance = baseAngle.distance;
}


static void RotateCamera(AngleZX* angle)
{
	if (TESCameraController::GetSingleton()->unk1C == 0)
		return;

	PlayerCamera* camera = PlayerCamera::GetSingleton();
	PlayerCharacter* player = *g_thePlayer;

	double angleZ = NormalAbsoluteAngle((double)player->rot.z + angle->z / (g_cameraSpeed * 60 / 2000));
	double angleX = NormalRelativeAngle((double)player->rot.x + angle->x / (g_cameraSpeed * 60 / 2000));

	if ((player->actorState.flags04 & 0x0003C000) == 0)
	{
		// 納刀時？
		if (IsCameraThirdPerson())
		{
			ThirdPersonState* tps = (ThirdPersonState*)camera->cameraState;
			tps->diffRotZ = 0.0;
			tps->diffRotX = 0.0;
		}
		CALL_MEMBER_FN_EX(player, SetAngleZ)(angleZ);
		CALL_MEMBER_FN_EX(player, SetAngleX)(angleX);
	}
	else
	{
		// 抜刀時？
		if (IsCameraFirstPerson())
		{
			FirstPersonState* fps = (FirstPersonState*)camera->cameraState;
			angleZ -= player->Unk_A3(0);

			fps->unk20 = angleZ;
			CALL_MEMBER_FN_EX(player, SetAngleX)(angleX);
		}
		else if (IsCameraThirdPerson())
		{
			ThirdPersonState* tps = (ThirdPersonState*)camera->cameraState;
			angleZ -= camera->unkC4;

			tps->diffRotZ = angleZ;
			tps->diffRotX = 0;
		}
		else
		{
			CALL_MEMBER_FN_EX(player, SetAngleZ)(angleZ);
			CALL_MEMBER_FN_EX(player, SetAngleX)(angleX);
		}
	}
}


static void OnCameraMove(UInt32* stack, UInt32 ecx)
{
	g_targetFormID = 0;

	static BSFixedString menuName("Dialogue Menu");
	MenuManager* mm = MenuManager::GetSingleton();
	if (!mm || mm->IsMenuOpen(&menuName))
		return;

	TESQuest* quest = GetLockOnQuest();
	if (!quest || !quest->IsRunning())
		return;

	UInt32 handle;
	CALL_MEMBER_FN(quest, CreateRefHandleByAliasID)(&handle, 0);
	if (handle == *g_invalidRefHandle)
		return;
	
	SharedPtr<TESObjectREFR> refTarget;
	if (!refTarget.LookupByHandle(handle))
		return;

	NiPoint3 cameraPos, cameraAngle, targetPos;
	if (GetTargetPos(refTarget, &targetPos))
	{
		AngleZX targetAngle;
		double fov = 1 / tan(PlayerCamera::GetSingleton()->worldFOV * M_PI / 360.0);

		// HUD表示・透視投影変換式
		GetCameraPos(&cameraPos);
		GetCameraAngle(&cameraAngle);
		GetAngle(cameraPos, targetPos, &targetAngle);
		targetAngle.z = NormalRelativeAngle(targetAngle.z - cameraAngle.z);
		targetAngle.x = NormalRelativeAngle(targetAngle.x - cameraAngle.x);
		g_targetFormID = refTarget->formID;
		double distance = targetAngle.distance * cos(targetAngle.z) * cos(targetAngle.x);
		double x = targetAngle.distance * sin(targetAngle.z);
		double y = targetAngle.distance * sin(targetAngle.x);

		if (abs(cameraAngle.y) > 0)
		{
			double x2 = x * cos(cameraAngle.y) - y * sin(cameraAngle.y);
			double y2 = y * cos(cameraAngle.y) + x * sin(cameraAngle.y);
			x = x2;
			y = y2;
		}

		static UInt32 screenWidth = 0;
		static UInt32 screenHeight = 0;
		if (screenHeight == 0)
		{
			screenWidth = GetINISetting("iSize W:Display")->data.u32;
			screenHeight = GetINISetting("iSize H:Display")->data.u32;
		}

		g_targetPosX = x / distance * fov * 800.0 / screenWidth * screenHeight;
		g_targetPosY = y / distance * fov * 480.0;
		g_targetDist = targetAngle.distance;
		TESActorBase* actorBase = (TESActorBase*)refTarget->baseForm;
		g_targetName = "";
		if (actorBase)
		{
			TESFullName* fullName = (TESFullName*)DYNAMIC_CAST(actorBase, TESActorBase, TESFullName);
			if (fullName && fullName->name.data)
			{
				g_targetName = fullName->name.data;
			}
		}

		// カメラ回転
		CalcAngle(&targetPos, &targetAngle);
		RotateCamera(&targetAngle);
	}
}


#include <skse/SafeWrite.h>
#include "HookUtil.h"
namespace Hooks
{
	void Init(void)
	{
		HookRelCall(ADDR_OnCameraMove, OnCameraMove);
	}
}

