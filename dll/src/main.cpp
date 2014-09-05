#include <skse.h>
#include <skse/PluginAPI.h>
#include <skse/PapyrusVM.h>
#include <skse/GameEvents.h>
#include <skse/GameData.h>
#include <shlobj.h>

#include "Hooks.h"
#include "Events.h"
#include "Papyrus.h"
#include "Scaleform.h"

IDebugLog gLog;

class LockOnPlugin : public SKSEPlugin
{
public:
	LockOnPlugin()
	{
		gLog.OpenRelative(CSIDL_MYDOCUMENTS, "\\My Games\\Skyrim\\SKSE\\skse_LockOn.log");
	}

	virtual bool InitInstance()
	{
		SetName("lockon plugin");
		SetVersion(2);

		if (!Requires("hmkLockOn.esp"))
			return false;

		_MESSAGE("hmkLockOn.esp OK");

		if (!Requires(kSKSEVersion_1_7_0))
		{
			_MESSAGE("ERROR: your skse version is too old");
			return false;
		}
		
		if (!Requires(SKSEScaleformInterface::kInterfaceVersion, SKSEPapyrusInterface::kInterfaceVersion))
		{
			_MESSAGE("ERROR: interfaces are too old");
			return false;
		}

		return true;
	}

	virtual bool OnLoad()
	{
		GetInterface<SKSEScaleformInterface>()->Register("lockon", Scaleform::RegisterCallback);
		Hooks::Init();
		
		return true;
	}

	virtual void OnModLoaded()
	{
		DataHandler* dhnd = DataHandler::GetSingleton();
		if (dhnd->LookupModByName("hmkLockOn.esp") != NULL)
		{
			Papyrus::Init();
			Events::Init();
		}
		else
		{
			_MESSAGE("warning: hmkLockOn.esp is not active.");
		}
	}

} thePlugin;
