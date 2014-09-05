
#include <skse.h>
#include <skse/GameReferences.h>
#include <skse/GameObjects.h>
#include <skse/GameCamera.h>
#include <skse/NiNodes.h>
#include <skse/GameData.h>
#include <skse/GameRTTI.h>
#include <skse/GameSettings.h>

#define _USE_MATH_DEFINES
#include <math.h>

#include "Address.h"
#include "Utils.h"

void GetAngle(const NiPoint3 &from, const NiPoint3 &to, AngleZX* angle)
{
	float x = to.x - from.x;
	float y = to.y - from.y;
	float z = to.z - from.z;
	float xy = sqrt(x*x + y*y);

	angle->z = atan2(x, y);
	angle->x = atan2(-z, xy);
	angle->distance = sqrt(xy*xy + z*z);
}


bool GetAngle(TESObjectREFR* target, AngleZX* angle)
{
	NiPoint3 targetPos;
	NiPoint3 cameraPos;

	if (!GetTargetPos(target, &targetPos))
		return false;
	GetCameraPos(&cameraPos);

	GetAngle(cameraPos, targetPos, angle);
	
	return true;
}


double NormalAbsoluteAngle(double angle)
{
	while (angle < 0)
		angle += 2*M_PI;
	while (angle > 2*M_PI)
		angle -= 2*M_PI;
	return angle;
}

double NormalRelativeAngle(double angle)
{
	while (angle > M_PI)
		angle -= 2*M_PI;
	while (angle < -M_PI)
		angle += 2*M_PI;
	return angle;
}




TESQuest* GetLockOnQuest(void)
{
	static UInt32 formID = 0;
	TESQuest* quest = NULL;
	
	if (formID == 0)
	{
		DataHandler* dhdl = DataHandler::GetSingleton();
		UInt32 idx = dhdl->GetModIndex("hmkLockOn.esp");
		if (idx != 0xFF)
		{
			formID = (idx << 24) | 0x000D62;
		}
	}

	if (formID)
	{
		quest = (TESQuest*)LookupFormByID(formID);
	}

	return quest;
}



BGSListForm* GetQuestList(void)
{
	static UInt32 formIDQuestList = 0;
	BGSListForm* formList = NULL;

	if (formIDQuestList == 0)
	{
		DataHandler* dhdl = DataHandler::GetSingleton();
		UInt32 idx = dhdl->GetModIndex("hmkLockOn.esp");
		if (idx != 0xFF)
		{
			formIDQuestList = (idx << 24) | 0x000D64;
		}
	}

	if (formIDQuestList)
	{
		formList = (BGSListForm*)LookupFormByID(formIDQuestList);
	}

	return formList;
}



const char* GetActorName(Actor* akActor)
{
	static const char unkName[] = "unknown";
	const char* result = unkName;

	if (akActor && akActor->formType == kFormType_Character)
	{
		TESActorBase* actorBase = (TESActorBase*)akActor->baseForm;
		if (actorBase)
		{
			TESFullName* pFullName = DYNAMIC_CAST(actorBase, TESActorBase, TESFullName);
			
			if (pFullName)
			{
				result = pFullName->name.data;
			}
		}
	}

	return result;
}


// Matrix行列から回転角を計算
void ComputeAnglesFromMatrix(NiMatrix33* mat, NiPoint3* angle)
{
	const double threshold = 0.001;
	if (abs(mat->data[2][1] - 1.0) < threshold)
	{
		angle->x = M_PI / 2;
		angle->y = 0;
		angle->z = atan2(mat->data[1][0], mat->data[0][0]);
	}
	else if (abs(mat->data[2][1] + 1.0) < threshold)
	{
		angle->x = - M_PI / 2;
		angle->y = 0;
		angle->z = atan2(mat->data[1][0], mat->data[0][0]);
	}
	else
	{
		angle->x = asin(mat->data[2][1]);
		angle->y = atan2(-mat->data[2][0], mat->data[2][2]);
		angle->z = atan2(-mat->data[0][1], mat->data[1][1]);
	}
}

// カメラが一人称視点かどうか調べる
bool IsCameraFirstPerson()
{
	PlayerCamera* camera = PlayerCamera::GetSingleton();
	if (!camera)
		return false;

	return camera->cameraState == camera->cameraStates[camera->kCameraState_FirstPerson];
}


// カメラが三人称視点かどうか調べる
bool IsCameraThirdPerson()
{
	PlayerCamera* camera = PlayerCamera::GetSingleton();
	if (!camera)
		return false;

	return camera->cameraState == camera->cameraStates[camera->kCameraState_ThirdPerson2];
}


// カメラの位置を取得
void GetCameraPos(NiPoint3* pos)
{
	PlayerCharacter* player = *g_thePlayer;
	PlayerCamera* camera = PlayerCamera::GetSingleton();
	float x, y, z;

	if (IsCameraFirstPerson() || IsCameraThirdPerson())
	{
		NiNode* node = camera->cameraNode;
		if (node)
		{
			x = node->m_worldTransform.pos.x;
			y = node->m_worldTransform.pos.y;
			z = node->m_worldTransform.pos.z;
		}
	}
	else
	{
		NiPoint3 playerPos;

		player->GetMarkerPosition(&playerPos);
		z = playerPos.z;
		x = player->pos.x;
		y = player->pos.y;
	}
	
	pos->x = x;
	pos->y = y;
	pos->z = z;
}


// カメラの向きを取得
void GetCameraAngle(NiPoint3* pos)
{
	PlayerCamera* camera = PlayerCamera::GetSingleton();
	PlayerCharacter* player = *g_thePlayer;
	float x, y, z;

	if (IsCameraFirstPerson())
	{
		FirstPersonState* fps = (FirstPersonState*)camera->cameraState;
		NiPoint3 angle;
		ComputeAnglesFromMatrix(&fps->cameraNode->m_worldTransform.rot, &angle);
		z = NormalAbsoluteAngle(-angle.z);
		x = player->rot.x - angle.x;
		y = angle.y;
	}
	else if (IsCameraThirdPerson())
	{
		ThirdPersonState* fps = (ThirdPersonState*)camera->cameraState;
		NiPoint3 angle;
		z = player->rot.z + fps->diffRotZ;
		x = player->rot.x + fps->diffRotX;
		y = 0;
	}
	else
	{
		x = player->rot.x;
		y = player->rot.y;
		z = player->rot.z;
	}

	pos->x = x;
	pos->y = y;
	pos->z = z;
}

// アクターのノードのワールド座標を取得
static bool GetNodePosition(Actor* actor, const char* nodeName, NiPoint3* point)
{
	bool bResult = false;

	if (nodeName[0])
	{
		NiAVObject* object = actor->GetNiNode();
		if (object)
		{
			object = object->GetObjectByName(&nodeName);
			if (object)
			{
				point->x = object->m_worldTransform.pos.x;
				point->y = object->m_worldTransform.pos.y;
				point->z = object->m_worldTransform.pos.z;
				bResult = true;
			}
		}
	}

	return bResult;
}



// アクターのTorso(胴)の位置を取得
static bool GetTorsoPos(Actor* actor, NiPoint3* point)
{
	TESRace* race = actor->race;
	BGSBodyPartData* bodyPart = race->bodyPartData;
	BGSBodyPartData::Data* data;

	// bodyPart->part[0] 胴
	// bodyPart->part[1] 頭
	data = bodyPart->part[0];
	if (data)
	{
		return GetNodePosition(actor, data->unk04.data, point);
	}

	return false;
}


// ターゲットの座標を取得する
bool GetTargetPos(TESObjectREFR* target, NiPoint3* pos)
{
	if (target->GetNiNode() == NULL)
		return false;
	
	if (target->formType == kFormType_Character)
	{
		if (!GetTorsoPos((Actor*)target, pos))
			target->GetMarkerPosition(pos);
	}
	else
	{
		pos->x = target->pos.x;
		pos->y = target->pos.y;
		pos->z = target->pos.z;
	}
	
	return true;
}


DEFINE_MEMBER_FN_EX(PlayerCharacter, HasLOS, bool, ADDR_PlayerHasLOS, TESObjectREFR*, UInt32* unk)

Actor* GetCombatTarget(Actor* actor)
{
	Actor* ref = NULL;
	UInt32 handle;

	if (actor->IsInCombat())
	{
		handle = actor->combatTargetRefHandle;
		if (handle != *g_invalidRefHandle)
			LookupREFRByHandle(&handle, (TESObjectREFR**)&ref);
	}

	return ref;
}


bool IsPlayerTeammate(Actor* actor)
{
	return (actor->flags1 & actor->kFlags_IsPlayerTeammate) != 0;
}


bool IsPlayerFollower(Actor* actor)
{
	return actor->IsInFaction((TESFaction*)LookupFormByID(0x05C84E));
}

