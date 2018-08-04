/********************************************************************
created:	2008/06/23	
filename: 	main.c
author:		xcl

purpose:	testbed for h264 decoder
*********************************************************************/


#include "opt.h"
#include "avcodec.h"
#include "channel_layout.h"
#include "common.h"
#include "imgutils.h"
#include "mathematics.h"
#include "samplefmt.h"
#define INBUF_SIZE 4096

#include <stdio.h>
#include <wchar.h>

#include "VideoDecoder.h"

#define PI 3.14159265358979323846

#ifdef HAVE_AV_CONFIG_H
#undef HAVE_AV_CONFIG_H
#endif

#define INBUF_SIZE 4096
typedef struct 
{
    struct AVCodec *codec;			  // Codec
    struct AVCodecContext *c;		  // Codec Context
    int frame_count;
    struct AVFrame *picture;		  // Frame
    AVPacket avpkt;
    
    int iWidth;
    int iHeight;
    int inSize;
    int comsumedSize;
    int got_picture;
	uint8_t inbuf[INBUF_SIZE + FF_INPUT_BUFFER_PADDING_SIZE];
	uint8_t *inbuf_ptr;
	char buf[1024];
	//DSPContext dsp;
}X264_Decoder_Handle;

void pgm_save2(unsigned char *buf,int wrap, int xsize,int ysize,uint8_t *pDataOut)
{
	int i;
	for(i=0;i<ysize;i++)
	{
		memcpy(pDataOut+i*xsize, buf + /*(ysize-i)*/i * wrap, xsize);
	}

}
X264_H VideoDecoder_Init()
{
    //LOGI("VideoDecoder_Init\n");
	X264_Decoder_Handle *pHandle = (X264_Decoder_Handle *)malloc(sizeof(X264_Decoder_Handle));
	if (pHandle == NULL)
		return 0;

	avcodec_register_all();
    av_init_packet(&(pHandle->avpkt));
    pHandle->codec = avcodec_find_decoder(AV_CODEC_ID_H264);
    if (!pHandle->codec) {
        //LOGE("Codec not found\n");
        return -1;
    }
    pHandle->c = avcodec_alloc_context3(pHandle->codec);
    //LOGI("avcodec_alloc_context3\n");
    if (!pHandle->c) {
        //LOGE("Could not allocate video codec context\n");
        return -1;
    }
    
    if(pHandle->codec->capabilities&CODEC_CAP_TRUNCATED)
        pHandle->c->flags|= CODEC_FLAG_TRUNCATED; //* we do not send complete frames
    
    if (avcodec_open2(pHandle->c, pHandle->codec, NULL) < 0) {
        //LOGE("Could not open codec\n");
        return -1;
    }
    pHandle->picture = avcodec_alloc_frame();
    if (!pHandle->picture) {
        //LOGE("Could not allocate video frame\n");
        //exit(1);
    }
    //LOGI("avcodec_open2\n");
    pHandle->frame_count = 0;
	return (X264_H)pHandle;
	//return 0;
}
int VideoDecoder_Decode(X264_H dwHandle, uint8_t *pDataIn, int nInSize, uint8_t *pDataOut, int nOutSize, int *nWidth, int *nHeight)//nOutSizeŒ™±£¥Ê ‰≥ˆ ˝æ›ƒ⁄¥Êµƒ¥Û–°
{
	X264_Decoder_Handle *pHandle;
	//*i_frame_size = 0;
	if (dwHandle == 0)
	{
		return -1;
	}
	pHandle = (X264_Decoder_Handle *)dwHandle;


	//pHandle->inbuf_ptr = pDataIn;
	//pHandle->inSize = nInSize;
    pHandle->avpkt.size = nInSize;
    pHandle->avpkt.data = pDataIn;
	while (pHandle->avpkt.size > 0) {
        //LOGI("avcodec_decode_video2\n");
		//pHandle->outSize = avcodec_decode_video2(pHandle->c, pHandle->picture, &pHandle->got_picture,
		//	pHandle->inbuf_ptr, pHandle->inSize);
        pHandle->comsumedSize = avcodec_decode_video2(pHandle->c, pHandle->picture, &pHandle->got_picture, &(pHandle->avpkt));
		if (pHandle->comsumedSize < 0) {
            
			//LOGE("Error while decoding frame InSize = %d   comsumedSize = %d\n", pHandle->avpkt.size,pHandle->comsumedSize);
			//exit(1);
			return -1;
		}
		if (pHandle->got_picture) {
			//printf("saving frame %3d\n", pHandle->frame);
			fflush(stdout);

			/* the picture is allocated by the decoder. no need to
			free it */
			*nWidth = pHandle->c->width;
			*nHeight = pHandle->c->height;
			if(nOutSize >= (pHandle->c->width)*(pHandle->c->height)*3/2)
			{
				pgm_save2(pHandle->picture->data[0], pHandle->picture->linesize[0],pHandle->c->width, pHandle->c->height,pDataOut);
				pgm_save2(pHandle->picture->data[1], pHandle->picture->linesize[1],pHandle->c->width/2, pHandle->c->height/2,pDataOut +pHandle->c->width * pHandle->c->height);
				pgm_save2(pHandle->picture->data[2], pHandle->picture->linesize[2],pHandle->c->width/2, pHandle->c->height/2,pDataOut +pHandle->c->width * pHandle->c->height*5/4);
			}

			pHandle->frame_count++;
		}
        if (pHandle->avpkt.data) {
            pHandle->avpkt.size -= pHandle->comsumedSize;
            pHandle->avpkt.data += pHandle->comsumedSize;
        }
	}
	if(nOutSize < (pHandle->c->width)*(pHandle->c->height)*3/2)
	{
		return -1;
	}
	return 0;
}
void VideoDecoder_UnInit(X264_H dwHandle)
{
	X264_Decoder_Handle *pHandle;
	//*i_frame_size = 0;
	if (dwHandle == 0)
	{
		return;
	}
	pHandle = (X264_Decoder_Handle *)dwHandle;
	avcodec_close(pHandle->c);
	//av_free(pHandle->c);
	free(pHandle->picture);
	return;
}
