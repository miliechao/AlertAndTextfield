#ifndef __OPUS_ENC_API_H__
#define __OPUS_ENC_API_H__
#include "btype.h"
#ifdef __cplusplus
extern "C" {
#endif
 
#define PCM_FRAME_SIZE 1920

typedef struct OPUS_HEADER_
{
	uint32 terminal_flag : 4;
	uint32 sampling_rate : 3;
	uint32  channels : 2;
	
	uint32 frame_size :3;
	uint32 bitrate_bps :3;
	uint32 fec_flag : 1;
	uint32 dxt_flag : 1;
	
	uint32 packet_loss_perc :4;
	uint32 complexity : 4;
	
	uint32 unused1:7;

	int frame_num;
	int src_audio_len;
	int dst_audio_len;
	long long audio_time;
	long long date;
} OPUS_HEADER;

enum {
	OPUS_INIT_MALLOC_ERROR = 1,	
	OPUS_INIT_OPT_MALLOC_ERROR,
	OPUS_INIT_INIT_ERROR,
	OPUS_INIT_ARGV_ERROR,
	OPUS_INIT_HEADER_MALLOC_ERROR
};

void * opus_ios_enc_init (int sample_rate, int channel, int bitrate_bps, int fec ,int vbr,int complexity,int app,int *error);

int    opus_ios_enc_encode (void * vctx, uint8 * pbuf, int buflen, uint8 EOS, uint8 * output, int * outlen);
int    opus_enc_clean (void * vctx);

int get_audio_head_len(void);
int opus_get_enc_framenum    (void * vctx);
int opus_get_enc_inputbytes  (void * vctx);
int opus_get_enc_outputbytes (void * vctx);
int opus_get_enc_duration    (void * vctx);
int build_audio_head(void * vctx,uint8  *ch,int terminal_flag,long long audio_time,long long date);


/*decode*/

int read_frame_len(void * vctx,uint8  *ch);
int get_audio_head(void * vctx,uint8  *ch);


int get_opus_audio_len(void * vctx);

int get_pcm_audio_len(void * vctx);


int get_audio_creation_time(void * vctx);


int get_audio_creation_terminal(void * vctx);


int get_audio_opus_frame_num(void * vctx);

int get_audio_opus_frame_size(void * vctx);

int opus_ios_dec_decode (void * vctx, uint8 * pbuf, int buflen,  uint8 * output, int * outlen);
void * opus_ios_dec_init (int sample_rate, int channel, int *error);
int opus_dec_clean (void * vctx);


 
#ifdef __cplusplus
}
#endif
 
#endif
