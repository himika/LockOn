
#pragma once

#define HookRelCall(addr, fn)					\
	HookMaker<addr> hmrc_##addr;			    \
	hmrc_##addr.Install(fn)

#define HookVFunc(vptr, n, fn)					\
	HookMakerVFunc<vptr, n> hmvf_##vptr_##n;	\
	hmvf_##vptr_##n.Install(fn)


template<typename T>
static void __declspec(naked) hook_RelCall(void)
{
	__asm
	{
		push	ecx
		lea		ecx, dword ptr [esp+4]
		push	ecx
		call	[T::callback]
		add		esp, 4
		pop		ecx
		
		jmp		[T::addr]
	}
}

template<UInt32 n>
class HookMaker
{
public:
	typedef void (*FnCallback)(UInt32*, UInt32);

	static UInt32       addr;
	static FnCallback   callback;

	HookMaker() {}

	void Install(FnCallback fnCallback)
	{
		addr = (n + *((UInt32 *)(n + 1)) + 5);
		callback = fnCallback;

		void (*a)(void) = hook_RelCall<HookMaker>;
		WriteRelCall(n, (UInt32)a);
	}
};

template<UInt32 n>
UInt32 HookMaker<n>::addr;

template<UInt32 n>
void (*HookMaker<n>::callback)(UInt32*, UInt32);



template<UInt32 vptr, UInt32 n>
class HookMakerVFunc
{
public:
	typedef void (*FnCallback)(UInt32*, UInt32);

	static UInt32       addr;
	static FnCallback   callback;

	HookMakerVFunc() {}

	void Install(FnCallback fnCallback)
	{
		UInt32* p = &((UInt32*)vptr)[n];

		addr = *p;
		callback = fnCallback;

		void (*a)(void) = hook_RelCall<HookMakerVFunc>;
		SafeWrite32((UInt32)p, (UInt32)a);
	}
};

template<UInt32 vptr, UInt32 n>
UInt32 HookMakerVFunc<vptr, n>::addr;

template<UInt32 vptr, UInt32 n>
void (*HookMakerVFunc<vptr, n>::callback)(UInt32*, UInt32);
