
#ifndef __KE_BTYPE_H__
#define __KE_BTYPE_H__



#ifndef UNIX
#define UNIX
/*#ifndef _DEBUG
  #define _DEBUG 
  #endif*/
#endif

#ifndef WINDOWS
#define WINDOWS
#endif

#undef WINDOWS

#ifdef WINDOWS
#pragma comment(lib,"Ws2_32.lib")
#include <winsock2.h>
#include <ws2tcpip.h>
#include <windows.h>

#ifndef inline
#define inline _inline
#endif
#endif

#ifdef _ANDROID
#ifdef _M_DEBUG
#include <android/log.h>
#define v_printf(...) __android_log_print(ANDROID_LOG_DEBUG, "RJPIN", __VA_ARGS__)
#else
#define v_printf(...) 
#endif
#endif //#ifdef _ANDROID

#ifndef v_printf
#ifdef _M_DEBUG
#define v_printf(...) printf(__VA_ARGS__)
#else
#define v_printf(...) 
#endif
#endif //#ifndef v_printf

#include <limits.h>
#include <stdio.h>
#include <time.h>
#include <sys/timeb.h>
#include <string.h>
#include <stdlib.h>
#include <assert.h>

#ifdef UNIX
#include <ctype.h>
#include <stdint.h>
#include <unistd.h>
#include <sys/types.h>
#ifdef _ANDROID
#include <asm/io.h>
#endif
#include <sys/socket.h>
#include <netinet/in.h>
#include <arpa/inet.h>
#include <sys/time.h>
#include <sys/un.h>
#include <sys/stat.h>
#include <fcntl.h>
#include <errno.h>
#ifndef _ANDROID
extern int errno;
#endif
#endif

#ifndef ANDROID
#define MSG_NOSIGNAL MSG_HAVEMORE
#endif

typedef unsigned long long  uint64;
typedef long long           sint64;
typedef long long           int64;
typedef unsigned long       ulong;
typedef unsigned int        uint32;
typedef int                 sint32;
typedef int                 int32;
typedef unsigned short int  uint16;
typedef short int           sint16;
typedef short int           int16;
#ifdef _ANDROID
typedef char                uint8;
#else
typedef unsigned char       uint8;
#endif
typedef char                sint8;
typedef char                int8;


#define isBigEndian()   ((*(unsigned short *) ("KE") >> 8) == 'K')

#define rol(x,n) ( ((x) << (n)) | ((x) >> (32-(n))) )
#define rol2(x,n)( ((x) << (n)) | ((x) >> (64-(n))) )
#define swap2(b) ( ((uint16)(b)<<8)|((uint16)(b)>>8) )
#define swap4(b) ( (rol((uint32)(b), 24) & 0xff00ff00) | (rol((uint32)(b), 8) & 0x00ff00ff) )
#define swap8(b) ( (rol2((uint64)(b),8 )&0x000000FF000000FFULL) | \
                   (rol2((uint64)(b),24)&0x0000FF000000FF00ULL) | \
                   (rol2((uint64)(b),40)&0x00FF000000FF0000ULL) | \
                   (rol2((uint64)(b),56)&0xFF000000FF000000ULL) )

#ifndef min
#define min(x,y)  ((x) <= (y)?(x):(y))
#endif
#ifndef max
#define max(x,y)  ((x) >= (y)?(x):(y))
#endif
#ifndef htonll
#define htonll(b) ( isBigEndian()?(b):swap8(b) )
#endif
#ifndef ntohll
#define ntohll(b) ( isBigEndian()?(b):swap8(b) )
#endif

#ifndef ULONG_MAX
#define  ULONG_MAX   (-1)UL 
#endif
#ifndef  TRUE
#define  TRUE               1
#endif
#ifndef  FALSE
#define  FALSE              0
#endif



#define TRANSAPI

#ifdef UNIX
    #ifndef SLEEP 
    #define SLEEP(x) usleep((x)*1000)
    #endif

    #ifndef SOCKET
    #define SOCKET int
    #endif

    #ifndef INVALID_SOCKET
    #define INVALID_SOCKET   -1
    #endif

    #ifndef WSAGetLastError
    #define WSAGetLastError() errno
    #endif

    #ifndef closesocket
    #define closesocket close
    #endif

    #ifndef OutputDebugString
    #define OutputDebugString printf
    #endif

    #ifndef SOCKET_ERROR
    #define SOCKET_ERROR -1
    #endif

#endif /* end if UNIX */



#ifdef WINDOWS
    #ifndef pthread_mutex_t
    #define pthread_mutex_t CRITICAL_SECTION
    #endif 

    #ifndef pthread_mutex_unlock
    #define pthread_mutex_unlock(a) LeaveCriticalSection((a))
    #endif 

    #ifndef pthread_mutex_lock
    #define pthread_mutex_lock(a) EnterCriticalSection((a))
    #endif 

    #ifndef pthread_mutex_init
    #define pthread_mutex_init(a, b) InitializeCriticalSection((a))
    #endif 

    #ifndef pthread_mutex_destroy
    #define pthread_mutex_destroy(a) DeleteCriticalSection((a))
    #endif 

    #ifndef SLEEP 
    #define SLEEP Sleep
    #endif

    #ifndef strcasecmp
    #define strcasecmp _stricmp
    #endif

    #ifndef srandom
    #define srandom srand
    #endif

    #ifndef random
    #define random rand
    #endif

    #ifndef strncasecmp
    #define strncasecmp _strnicmp
    #endif

    #ifndef snprintf
    #define snprintf _snprintf
    #endif

    #define MSG_NOSIGNAL 0
    /*
    #if defined(_TRANSLIB_)
        #define TRANSAPI _declspec(dllexport)
    #else
        #define TRANSAPI _declspec(dllimport)
    #endif
    */

    #if _MSC_VER < 1300
    #define strtoll(p,e,b) ((*(e)=(char*)(p)+(((b)== 0)?strspn((p),"0123456789"):0)),_atoi64(p))
    #else
    #define strtoll(p, e, b) _strtoi64(p, e, b) 
    #endif

    #ifndef strtoull
    #define strtoull strtoul
    #endif

#ifndef strcpy
#define strcpy winstrcpy
#endif

int gettimeofday(struct timeval *tv, struct timezone *tz);

#pragma warning(disable : 4996)
#pragma warning(disable : 4244)
#pragma warning(disable : 4133)
#pragma warning(disable : 4267)

#endif /* endif WINDOWS */

#ifdef __cplusplus
extern "C" {
#endif

uint8 * winstrcpy (uint8 * dst, uint8 * src);

uint8 toASCIICH(uint8 ch);
#define toASCII(ch) toASCIICH((uint8)(ch))


#ifdef __cplusplus
}
#endif

#endif

