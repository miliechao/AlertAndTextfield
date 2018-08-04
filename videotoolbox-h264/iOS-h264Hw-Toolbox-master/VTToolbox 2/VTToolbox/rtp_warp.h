#ifndef _rtp_WARP_H_
#define _rtp_WARP_H_ 


#ifdef __cplusplus
extern "C" {
#endif 


void * RtpInit();
int Rtpstart(void * rtpstat,
		uint8 * arg_json, int arg_json_len,uint8 * pVideoAVCSPS,int spslen,
		uint8 * pVideoAVCPPS,int ppslen);

int Rtpstop(void * rtpstat);
int Rtpclean(void * rtpstat);
int Rtppush(void * rtpstat, uint8 * pData, int nSize) ;
int ios_rtp_push(void * rtpstat, uint8 * m_h264Buf,int buflen,uint8 * head,int headlen);

#ifdef __cplusplus
}
#endif 
 
#endif

