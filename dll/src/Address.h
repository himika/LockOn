
#pragma once

#if SKSE_VERSION_RELEASEIDX >= 40
// RUNTIME_VERSION_1_9_32_0
#define ADDR_OnCombat							0x006E3FD8
#define ADDR_UnkCellInfo						0x012E32E8
#define ADDR_PlayerHasLOS						0x007371A0
#define ADDR_OnCameraMove						0x0074F311
#define ADDR_SetAngleZ							0x006A8910
#define ADDR_SetAngleX							0x006AE540
#define ADDR_GetRefObjectFromHandle				0x004951F0
#define ADDR_LookupSharedPtrByHandle			0x004951F0
#define ADDR_VMClassRegistry_NewArray			0x00C49670
#define ADDR_bInvertYValues						0x0127B928
#elif SKSE_VERSION_RELEASEIDX == 39
// RUNTIME_VERSION_1_9_29_0
#error 対応していないバージョンです。
#elif SKSE_VERSION_RELEASEIDX == 38
#error 対応していないバージョンです。
#elif SKSE_VERSION_RELEASEIDX >= 31
// RUNTIME_VERSION_1_8_151_0
#define ADDR_UnkCellInfo						0x012E24E8
#define ADDR_PlayerHasLOS						0x00736CE0
#define ADDR_OnCameraMove						0x0074F461
#define ADDR_SetAngleZ							0x006A84F0
#define ADDR_SetAngleX							0x006AE200
#define ADDR_GetRefObjectFromHandle				0x0065EA40
#define ADDR_LookupSharedPtrByHandle			0x0065EA40
#define ADDR_VMClassRegistry_NewArray			0x00C488D0
#define ADDR_bInvertYValues						0x0127AC28
#else
#error 対応していないバージョンです。
#endif
