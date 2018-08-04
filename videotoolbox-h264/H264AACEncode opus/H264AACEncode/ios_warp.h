#ifndef _IOS_WARP_H_
#define _IOS_WARP_H_ 


struct ENCODER_PARAM;
typedef unsigned char    BYTE;

#ifdef __cplusplus
extern "C" {
#endif 

#include "btype.h"
    
void * LiveInit();

int Livestart(void * livestat,
		uint8 * arg_json, int arg_json_len,uint8 * pVideoAVCSPS,int spslen,
		uint8 * pVideoAVCPPS,int ppslen) ;

int Livestop_jni(void * livestat); 

int Liveclean(void * livestat);

int Livepush(void * livestat, int nMediaType, uint8 * pData, int nSize, int nStamp, int nKeyFrame, int nCTOff); 


#ifdef __cplusplus
}
#endif 
 
#endif

