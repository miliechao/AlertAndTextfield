#define X264_H int


#ifdef __cplusplus
extern "C" {
#endif
	X264_H VideoDecoder_Init();
	int    VideoDecoder_Decode(X264_H dwHandle,uint8_t *pDataIn, int nInSize, uint8_t *pDataOut, int nOutSize, int *nWidth, int *nHeight);
	void   VideoDecoder_UnInit(X264_H dwHandle);
#ifdef __cplusplus
}
#endif