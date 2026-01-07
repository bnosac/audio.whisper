#define WIN32_LEAN_AND_MEAN
#include <windows.h>

// For static libgcc, we need to provide DllEntryPoint
extern "C" {
  BOOL WINAPI DllMain(HINSTANCE hinstDLL, DWORD fdwReason, LPVOID lpvReserved);
  
  // Alias DllMain as DllEntryPoint for static CRT
  BOOL WINAPI DllEntryPoint(HINSTANCE hinstDLL, DWORD fdwReason, LPVOID lpvReserved) 
    __attribute__((alias("DllMain")));
}

BOOL WINAPI DllMain(HINSTANCE hinstDLL, DWORD fdwReason, LPVOID lpvReserved) {
  return TRUE;
}