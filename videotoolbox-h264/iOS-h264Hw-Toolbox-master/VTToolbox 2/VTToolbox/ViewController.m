//
//  ViewController.m
//  h264v1
//
//  Created by Ganvir, Manish on 3/31/15.
//  Copyright (c) 2015 Ganvir, Manish. All rights reserved.
//

#import "ViewController.h"
#import "H264HwEncoderImpl.h"
#import "AACEncoder.h"
#include "btype.h"
#include "rtp_warp.h"
#include "rtprecv_warp.h"
#include "VideoDecoder.h"
#include "colorconvert.h"


#define CAPTURE_FRAMES_PER_SECOND		20
#define SAMPLE_RATE                     44100
#define AUDIOCHANNEL  1

#define YUV_FRAME_SIZE 2000
#define FRAME_WIDTH
#define NUMBEROFRAMES 300
#define DURATION 12

#define VIDEOWIDTH  640
#define VIDEOHEIGHT 480


#define HOST  @"192.168.1.33"
#define PORT  2610

@interface ViewController ()
{
    H264HwEncoderImpl *h264Encoder;
    AVCaptureSession *captureSession;
    bool startCalled;
    AVCaptureVideoPreviewLayer *previewLayer;
    NSString *h264File;
    int fd;
    NSFileHandle *fileHandle;
    AVCaptureConnection* _videoConnection;
    
    AVCaptureAudioDataOutput* _audioOutput;
    dispatch_queue_t _audioQueue;
    AVCaptureConnection* _audioConnection;
    
    AVCaptureDeviceInput *inputDevice;
    
    void *init;
    
    BOOL isFirstTime;
    
    NSString *ipStr;
    NSString *maskStr;
    
    int _tempAudioTimeStamp;
    int _tempVideoTimeStamp;
    long long currentTime;
    
    NSMutableData *_data;
    NSMutableData *_tempHeadData;
    
    int SPSPPSSuccess;
    
    NSString *FilePath;
    FILE *_imgFileHandle;
}
@property (weak, nonatomic) IBOutlet UIButton *StartStopButton;
@property (nonatomic, strong) AACEncoder *aacEncoder;

@end

@implementation ViewController

int mTrans=0x0F0F0F0F;

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    h264Encoder = [H264HwEncoderImpl alloc];
    [h264Encoder initWithConfiguration];
    startCalled = true;
    
    isFirstTime = YES;
    
//    init = RtpInit();
    
    [self getIPAddress];
    
    _data = [[NSMutableData alloc] init];
    _tempHeadData = [[NSMutableData alloc] init];
    
    const char bytes[] = "\x00\x00\x00\x01";
    size_t length = (sizeof bytes) - 1; //string literals have implicit trailing '\0'
    _tempHeadData = [NSMutableData dataWithBytes:bytes length:length];
    
    SPSPPSSuccess = 0;
    
    NSString *bundlePath = [[NSBundle mainBundle] bundlePath];
    FilePath = [bundlePath stringByAppendingPathComponent: @"320x240.264"];
    _imgFileHandle =NULL;


}


- (void) setupAudioCapture {
    _aacEncoder = [[AACEncoder alloc] init];
    // create capture device with video input
    
    /*
     * Create audio connection
     */
    AVCaptureDevice *audioDevice = [AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeAudio];
    
    NSError *error = nil;
    AVCaptureDeviceInput *audioInput = [[AVCaptureDeviceInput alloc] initWithDevice:audioDevice error:&error];
    if (error) {
        NSLog(@"Error getting audio input device: %@", error.description);
    }
    if ([captureSession canAddInput:audioInput]) {
        [captureSession addInput:audioInput];
    }
    
    _audioQueue = dispatch_queue_create("Audio Capture Queue", DISPATCH_QUEUE_SERIAL);
    _audioOutput = [[AVCaptureAudioDataOutput alloc] init];


    [_audioOutput setSampleBufferDelegate:self queue:_audioQueue];
    if ([captureSession canAddOutput:_audioOutput]) {
        [captureSession addOutput:_audioOutput];
    }
    _audioConnection = [_audioOutput connectionWithMediaType:AVMediaTypeAudio];
//    [_hlsWriter addAudioStreamWithSampleRate:SAMPLE_RATE];
    

}


- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

// Called when start/stop button is pressed
- (IBAction)OnStartStop:(id)sender {

    if (startCalled)
    {
        _tempAudioTimeStamp = 0;
        _tempVideoTimeStamp = 0;
        currentTime = [[self getCurentTime] longLongValue];

        [self startCamera];
        startCalled = false;
        [_StartStopButton setTitle:@"Stop" forState:UIControlStateNormal];
//        [self CameraToggleButtonPressed:nil];
    }
    else
    {
        [_StartStopButton setTitle:@"Start" forState:UIControlStateNormal];
        startCalled = true;
        [self stopCamera];
        [h264Encoder End];
    }
    
}

- (AVCaptureDevice *) CameraWithPosition:(AVCaptureDevicePosition) Position
{
    NSArray *Devices = [AVCaptureDevice devicesWithMediaType:AVMediaTypeVideo];
    for (AVCaptureDevice *Device in Devices)
    {
        if ([Device position] == Position)
        {
            return Device;
        }
    }
    return nil;
}

- (IBAction)CameraToggleButtonPressed:(id)sender
{
    if ([[AVCaptureDevice devicesWithMediaType:AVMediaTypeVideo] count] > 1)        //Only do if device has multiple cameras
    {
        NSError *error;
        AVCaptureDeviceInput *NewVideoInput;
        AVCaptureDevicePosition position = [[inputDevice device] position];

        if (position == AVCaptureDevicePositionBack)
        {
            NewVideoInput = [[AVCaptureDeviceInput alloc] initWithDevice:[self CameraWithPosition:AVCaptureDevicePositionFront] error:&error];
        }

        else if (position == AVCaptureDevicePositionFront)
        {
            NewVideoInput = [[AVCaptureDeviceInput alloc] initWithDevice:[self CameraWithPosition:AVCaptureDevicePositionBack] error:&error];
        }
        
        if (NewVideoInput != nil)
        {

            [captureSession beginConfiguration];
            [captureSession removeInput:inputDevice];
            if ([captureSession canAddInput:NewVideoInput])
            {
                [captureSession addInput:NewVideoInput];
                inputDevice = NewVideoInput;
            }
            else
            {
                [captureSession addInput:inputDevice];
            }
            
            //Set the connection properties again
//            [self CameraSetOutputProperties];
            
            
            [captureSession commitConfiguration];
        }
    }
}

- (void) startCamera
{
    // make input device
    
    NSError *deviceError;
    
    NSArray *devices = [AVCaptureDevice devicesWithMediaType:AVMediaTypeVideo];
    
    AVCaptureDevice *cameraDevice = [devices firstObject];
    
    inputDevice = [AVCaptureDeviceInput deviceInputWithDevice:cameraDevice error:&deviceError];
    
    // make output device
    
    AVCaptureVideoDataOutput *outputDevice = [[AVCaptureVideoDataOutput alloc] init];
    
    NSString* key = (NSString*)kCVPixelBufferPixelFormatTypeKey;
    
    NSNumber* val = [NSNumber
                     numberWithUnsignedInt:kCVPixelFormatType_32BGRA];
    NSDictionary* videoSettings =
    [NSDictionary dictionaryWithObject:val forKey:key];
    
    NSError *error;
    [cameraDevice lockForConfiguration:&error];
    if (error == nil) {
        
        NSLog(@"cameraDevice.activeFormat.videoSupportedFrameRateRanges IS %@",[cameraDevice.activeFormat.videoSupportedFrameRateRanges objectAtIndex:0]);
        
        if (cameraDevice.activeFormat.videoSupportedFrameRateRanges){
            
            [cameraDevice setActiveVideoMinFrameDuration:CMTimeMake(1, CAPTURE_FRAMES_PER_SECOND)];
            [cameraDevice setActiveVideoMaxFrameDuration:CMTimeMake(1, CAPTURE_FRAMES_PER_SECOND)];
        }
    }else{
        // handle error2
    }
    [cameraDevice unlockForConfiguration];
    
    
    // Start the session running to start the flow of data

    outputDevice.videoSettings = videoSettings;
    
    [outputDevice setSampleBufferDelegate:self queue:dispatch_get_main_queue()];
    
    // initialize capture session
    
    captureSession = [[AVCaptureSession alloc] init];
    captureSession.sessionPreset = AVCaptureSessionPresetHigh;

    [captureSession addInput:inputDevice];
    [captureSession addOutput:outputDevice];
    
    // begin configuration for the AVCaptureSession
    [captureSession beginConfiguration];
    
    // picture resolution
    [captureSession setSessionPreset:[NSString stringWithString:AVCaptureSessionPreset640x480]];
    
    _videoConnection = [outputDevice connectionWithMediaType:AVMediaTypeVideo];
    [self setRelativeVideoOrientation];
    
    //Set landscape (if required)
    if ([_videoConnection isVideoOrientationSupported])
    {
        AVCaptureVideoOrientation orientation = AVCaptureVideoOrientationLandscapeRight;		//<<<<<SET VIDEO ORIENTATION IF LANDSCAPE
        [_videoConnection setVideoOrientation:orientation];
    }
    
//    //Set frame rate (if requried)
//    CMTimeShow(connection.videoMinFrameDuration);
//    CMTimeShow(connection.videoMaxFrameDuration);
//    
//    if (connection.supportsVideoMinFrameDuration)
//        connection.videoMinFrameDuration = CMTimeMake(1, CAPTURE_FRAMES_PER_SECOND);
//    if (connection.supportsVideoMaxFrameDuration)
//        connection.videoMaxFrameDuration = CMTimeMake(1, CAPTURE_FRAMES_PER_SECOND);
//    
//    CMTimeShow(connection.videoMinFrameDuration);
//    CMTimeShow(connection.videoMaxFrameDuration);

    NSNotificationCenter* notify = [NSNotificationCenter defaultCenter];
    
    [notify addObserver:self
               selector:@selector(statusBarOrientationDidChange:)
                   name:@"StatusBarOrientationDidChange"
                 object:nil];
    
    
    [captureSession commitConfiguration];
    
    // make preview layer and add so that camera's view is displayed on screen
    
    previewLayer = [AVCaptureVideoPreviewLayer    layerWithSession:captureSession];
    [previewLayer setVideoGravity:AVLayerVideoGravityResizeAspect];

    previewLayer.frame = self.view.bounds;
//    [self.view.layer addSublayer:previewLayer];
    
    // go!
    
//    AVCaptureDevice *audioDev = [AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeAudio];
//    if (audioDev == nil)
//    {
//        NSLog(@"Couldn't create audio capture device");
//        return ;
//    }
//    
//    // create mic device
//    AVCaptureDeviceInput *audioIn = [AVCaptureDeviceInput deviceInputWithDevice:audioDev error:&error];
//    if (error != nil)
//    {
//        NSLog(@"Couldn't create audio input");
//        return ;
//    }
//    
//    
//    // add mic device in capture object
//    if ([captureSession canAddInput:audioIn] == NO)
//    {
//        NSLog(@"Couldn't add audio input");
//        return ;
//    }
//    [captureSession addInput:audioIn];
//    // export audio data
//    AVCaptureAudioDataOutput *audioOutput = [[AVCaptureAudioDataOutput alloc] init];
//    [audioOutput setSampleBufferDelegate:self queue:dispatch_get_main_queue()];
//    if ([captureSession canAddOutput:audioOutput] == NO)
//    {
//        NSLog(@"Couldn't add audio output");
//        return ;
//    }
//    [captureSession addOutput:audioOutput];
//    [audioOutput connectionWithMediaType:AVMediaTypeAudio];

    [self setupAudioCapture];
    
    [captureSession startRunning];
    
    NSFileManager *fileManager = [NSFileManager defaultManager];
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *documentsDirectory = [paths objectAtIndex:0];
    
    h264File = [documentsDirectory stringByAppendingPathComponent:@"test.h264"];
    [fileManager removeItemAtPath:h264File error:nil];
    [fileManager createFileAtPath:h264File contents:nil attributes:nil];
    
    // Open the file using POSIX as this is anyway a test application
    //fd = open([h264File UTF8String], O_RDWR);
    fileHandle = [NSFileHandle fileHandleForWritingAtPath:h264File];
    
    [h264Encoder initEncode:VIDEOWIDTH height:VIDEOHEIGHT];
    h264Encoder.delegate = self;
    
}


- (void)statusBarOrientationDidChange:(NSNotification*)notification {
    [self setRelativeVideoOrientation];
}

- (void)setRelativeVideoOrientation {
      switch ([[UIDevice currentDevice] orientation]) {
        case UIInterfaceOrientationPortrait:
#if defined(__IPHONE_8_0) && __IPHONE_OS_VERSION_MAX_ALLOWED >= __IPHONE_8_0
        case UIInterfaceOrientationUnknown:
#endif
            _videoConnection.videoOrientation = AVCaptureVideoOrientationPortrait;
    
            break;
        case UIInterfaceOrientationPortraitUpsideDown:
            _videoConnection.videoOrientation =
            AVCaptureVideoOrientationPortraitUpsideDown;
            break;
        case UIInterfaceOrientationLandscapeLeft:
            _videoConnection.videoOrientation = AVCaptureVideoOrientationLandscapeLeft;
            break;
        case UIInterfaceOrientationLandscapeRight:
            _videoConnection.videoOrientation = AVCaptureVideoOrientationLandscapeRight;
            break;
        default:
            break;
    }
}
- (void) stopCamera
{

    [captureSession stopRunning];
    [previewLayer removeFromSuperlayer];
    //close(fd);
    [fileHandle closeFile];
    fileHandle = NULL;
    
    // 获取程序Documents目录路径
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory,NSUserDomainMask, YES);
    NSString *documentsDirectory = [paths objectAtIndex:0];
    
    NSMutableString * path = [[NSMutableString alloc]initWithString:documentsDirectory];
    [path appendString:@"/AACFile"];
    
    [_data writeToFile:path atomically:YES];
    
    int i1 = Rtpstop(init);
    
    if (i1 != 0) {
        NSLog(@"Stop error! return = %d",i1);
    }
    
    int i2 = Rtpclean(init);
    
    if (i2 != 0) {
        NSLog(@"Clean error! return = %d",i2);
    }

}
-(void) captureOutput:(AVCaptureOutput*)captureOutput didOutputSampleBuffer:(CMSampleBufferRef)sampleBuffer fromConnection:(AVCaptureConnection*)connection

{
    
//    CMTime pts = CMSampleBufferGetPresentationTimeStamp(sampleBuffer);
//    double dPTS = (double)(pts.value) / pts.timescale;

//    NSLog(@"DPTS is %f",dPTS);
    
    //CVImageBufferRef imageBuffer = CMSampleBufferGetImageBuffer( sampleBuffer );
    
    //CGSize imageSize = CVImageBufferGetEncodedSize( imageBuffer );
    
    // also in the 'mediaSpecific' dict of the sampleBuffer
    if (connection == _videoConnection) {
        [h264Encoder encode:sampleBuffer];
//        NSLog(@"1");
    } else if (connection == _audioConnection) {
//        NSLog(@"2");
        
        [_aacEncoder encodeSampleBuffer:sampleBuffer completionBlock:^(NSData *encodedData, NSError *error) {
            if (encodedData) {
                
//                NSLog(@"Encoded data (%d): %@", encodedData.length, encodedData.description);
                
                [_data appendData:encodedData];
                
                uint8 *tempData = (uint8 *)[encodedData bytes];

                _tempAudioTimeStamp = (int)([[self getCurentTime] longLongValue] - currentTime);

                
//                NSLog(@"_tempAudioTimieStamp is %d",_tempAudioTimeStamp);

                if (SPSPPSSuccess >= 1000) {
//                    int i = Rtppush(init, tempData, (int)[encodedData length]);
//                    if (i != 0) {
//                        NSLog(@"Push Audio error! return = %d",i);
//                    }
                }

            } else {
                NSLog(@"Error encoding AAC: %@", error);
            }
        }];

    }
    
}


#pragma mark -  H264HwEncoderImplDelegate delegare

- (void)gotSpsPps:(NSData*)sps pps:(NSData*)pps
{

    const char bytes[] = "\x00\x00\x00\x01";
    size_t length = (sizeof bytes) - 1; //string literals have implicit trailing '\0'
    NSData *ByteHeader = [NSData dataWithBytes:bytes length:length];
    [fileHandle writeData:ByteHeader];
    [fileHandle writeData:sps];
    [fileHandle writeData:ByteHeader];
    [fileHandle writeData:pps];
    
    if (isFirstTime) {
        
        const char bytes[] = "\x00\x00\x00\x01";
        size_t length = (sizeof bytes) - 1; //string literals have implicit trailing '\0'

        NSData *tempData = [NSData dataWithBytes:bytes length:length];
        
        [_tempHeadData appendData:sps];
        [_tempHeadData appendData:tempData];
        [_tempHeadData appendData:pps];
        [_tempHeadData appendData:tempData];

        [self pushSPS:sps PPS:pps];
        isFirstTime = NO;
    }
}


- (void)pushSPS:(NSData *)sps PPS:(NSData *)pps
{
    NSLog(@"3");
    NSString *jsonStr = [NSString stringWithFormat:@"{\"szOutputHost\":%@,\"bVideoEnable\":1,\"ullStartTime\":%lld,\"nAudioChannels\":%d,\"nAudioSamplesPerSec\":%d,\"nOutputQueueSize\":1024,\"nVideoFPS\":%d,\"nVideoHeight\":%d,\"nVideoWidth\":%d,\"bAudioEnable\":1,\"nAudioAACObjectType\":2,\"usOutputPort\":%d,\"IP\":\"%@\",\"Mask\":\"%@\",}",HOST,[[self getCurentTime] longLongValue], AUDIOCHANNEL,SAMPLE_RATE, CAPTURE_FRAMES_PER_SECOND,VIDEOHEIGHT,VIDEOWIDTH,PORT,ipStr,maskStr];
    
    const char *arg_json=[jsonStr UTF8String];
    
    SPSPPSSuccess = Rtpstart(init, (uint8 *)arg_json, (int)[jsonStr lengthOfBytesUsingEncoding:NSUTF8StringEncoding], (uint8 *)[sps bytes], (int)[sps length], (uint8 *)[pps bytes], (int)[pps length]);
    if (SPSPPSSuccess != 0) {
        NSLog(@"Start error! return = %d",SPSPPSSuccess);
    }

    NSString *temopIP = @"192.168.1.23";
    
    int i = StartReceive((char *)[temopIP UTF8String],PORT,PORT, (char *)&ReceiveCallBack, 0);
    if (i != 0) {
        NSLog(@"error is %d",i);
    }
}

int ReceiveCallBack  (unsigned char * buffer, int bufferLen)
{
    NSLog(@"data is %s",buffer);
    return 0;
}

- (void)decodeAndShow : (char*) pFrameRGB length:(int)len nWidth:(int)nWidth nHeight:(int)nHeight
{
    
    
    //NSLog(@"decode ret = %d readLen = %d\n", ret, nFrameLen);
    if(len > 0)
    {
        CGBitmapInfo bitmapInfo = kCGBitmapByteOrderDefault;
        CFDataRef data = CFDataCreateWithBytesNoCopy(kCFAllocatorDefault, (UInt8 *)pFrameRGB, nWidth*nHeight*3,kCFAllocatorNull);
        CGDataProviderRef provider = CGDataProviderCreateWithCFData(data);
        CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
        
        CGImageRef cgImage = CGImageCreate(nWidth,
                                           nHeight,
                                           8,
                                           24,
                                           nWidth*3,
                                           colorSpace,
                                           bitmapInfo,
                                           provider,
                                           NULL,
                                           YES,
                                           kCGRenderingIntentDefault);
        CGColorSpaceRelease(colorSpace);
        //UIImage *image = [UIImage imageWithCGImage:cgImage];
        UIImage* image = [[UIImage alloc]initWithCGImage:cgImage];   //crespo modify 20111020
        CGImageRelease(cgImage);
        CGDataProviderRelease(provider);
        CFRelease(data);
        [self performSelectorOnMainThread:@selector(updateView:) withObject:image waitUntilDone:YES];
        //[image release];
    }
    
    return;
}

-(void)updateView:(UIImage*)newImage
{
    NSLog(@"显示新画面");
//    VideoView.image = newImage;
}
- (void)decode:(id)sender
{
    NSLog(@"start");
    
    _imgFileHandle =fopen([FilePath UTF8String],"rb");
    
    if (_imgFileHandle != NULL)
    {
        NSLog(@"File Exist");
        X264_H handle = VideoDecoder_Init();
        int iTemp=0;
        int nalLen;
        int bytesRead = 0;
        int NalBufUsed=0;
        int SockBufUsed=0;
        
        bool bFirst=true;
        bool bFindPPS=true;
        
        char  SockBuf[2048];
        char  NalBuf[40980]; // 40k
        char  buffOut[115200];
        char  rgbBuffer[230400];
        int outSize, nWidth, nHeight;
        outSize = 115200;
        memset(SockBuf,0,2048);
        memset(buffOut,0,115200);
        InitConvtTbl();
        do {
            bytesRead = fread(SockBuf, 1, 2048, _imgFileHandle);
            NSLog(@"bytesRead  = %d", bytesRead);
            if (bytesRead<=0) {
                break;
            }
            SockBufUsed = 0;
            while (bytesRead - SockBufUsed > 0) {
                nalLen = MergeBuffer(NalBuf, NalBufUsed, SockBuf, SockBufUsed, bytesRead-SockBufUsed);
                NalBufUsed += nalLen;
                SockBufUsed += nalLen;
                
                while(mTrans == 1)
                {
                    mTrans = 0xFFFFFFFF;
                    
                    if(bFirst==true) // the first start flag
                    {
                        bFirst = false;
                    }
                    else  // a complete NAL data, include 0x00000001 trail.
                    {
                        if(bFindPPS==true) // true
                        {
                            if( (NalBuf[4]&0x1F) == 7 )
                            {
                                bFindPPS = false;
                            }
                            else
                            {
                                NalBuf[0]=0;
                                NalBuf[1]=0;
                                NalBuf[2]=0;
                                NalBuf[3]=1;
                                
                                NalBufUsed=4;
                                
                                break;
                            }
                        }
                        
                        //	decode nal
                        iTemp = VideoDecoder_Decode(handle, NalBuf, NalBufUsed, buffOut,  outSize, &nWidth, &nHeight);
                        if(iTemp == 0)
                        {
                            i420_to_rgb24(buffOut, rgbBuffer, nWidth, nHeight);
                            flip(rgbBuffer, nWidth, nHeight);
                            [self decodeAndShow:rgbBuffer length:nWidth*nHeight*3 nWidth:nWidth nHeight:nHeight];
                            //nFrameCount++;
                        }
                        else
                        {
                            //Log.e("DecoderNal", "DecoderNal iTemp <= 0");
                        }
                        
                        //if(iTemp>0)
                        //postInvalidate();  //使用postInvalidate可以直接在线程中更新界面    // postInvalidate();
                    }
                    
                    NalBuf[0]=0;
                    NalBuf[1]=0;
                    NalBuf[2]=0;
                    NalBuf[3]=1;
                    
                    NalBufUsed=4;
                }
            }
            
            //int nRet = VideoDecoder_Decode(handle, buff, nReadBytes, buffOut,  outSize, &nWidth, &nHeight);
            NSLog(@"nDecodeRet = %d  nWidth = %d  nHeight = %d", iTemp, nWidth, nHeight);
        } while (bytesRead>0);
        
        fclose(_imgFileHandle);
        
    }
    
}

int MergeBuffer(char* NalBuf, int NalBufUsed, char* SockBuf, int SockBufUsed, int SockRemain)
{//把读取的数剧分割成NAL块
    int  i=0;
    char Temp;
    
    for(i=0; i<SockRemain; i++)
    {
        Temp  =SockBuf[i+SockBufUsed];
        NalBuf[i+NalBufUsed]=Temp;
        
        mTrans <<= 8;
        mTrans  |= Temp;
        
        if(mTrans == 1) // 找到一个开始字
        {
            i++;
            break;
        }
    }
    
    return i;
}
void flip(char *pRGBBuffer, int nWidth, int nHeight)
{
    char temp[nWidth*3];
    for (int i = 0; i<nHeight/2; i++) {
        memcpy(temp, pRGBBuffer + i*nWidth*3, nWidth*3);
        memcpy(pRGBBuffer + i*nWidth*3, pRGBBuffer + (nHeight - i - 1)*nWidth*3, nWidth*3);
        memcpy(pRGBBuffer + (nHeight - i - 1)*nWidth*3, temp, nWidth*3);
    }
    /*
     for (int i = 0; i<nHeight/2; i++) {
     memcpy(temp, pRGBBuffer + i*nWidth + nWidth*nHeight, nWidth);
     memcpy(pRGBBuffer + i*nWidth + nWidth*nHeight, pRGBBuffer + (nHeight - i - 1)*nWidth + nWidth*nHeight, nWidth);
     memcpy(pRGBBuffer + (nHeight - i - 1)*nWidth + nWidth*nHeight, temp, nWidth);
     }
     for (int i = 0; i<nHeight/2; i++) {
     memcpy(temp, pRGBBuffer + i*nWidth + nWidth*nHeight*2, nWidth);
     memcpy(pRGBBuffer + i*nWidth + nWidth*nHeight*2, pRGBBuffer + (nHeight - i - 1)*nWidth + nWidth*nHeight*2, nWidth);
     memcpy(pRGBBuffer + (nHeight - i - 1)*nWidth + nWidth*nHeight*2, temp, nWidth);
     }
     */
    
}

- (void)gotEncodedData:(NSData*)data isKeyFrame:(BOOL)isKeyFrame
{

   // [data writeToFile:h264File atomically:YES];
    //write(fd, [data bytes], [data length]);
    if (fileHandle != NULL)
    {
        const char bytes[] = "\x00\x00\x00\x01";
        size_t length = (sizeof bytes) - 1; //string literals have implicit trailing '\0'
        NSData *ByteHeader = [NSData dataWithBytes:bytes length:length];
        
        
        NSData *UnitHeader;
        if(isKeyFrame)
        {
            char header[2];
            header[0] = '\x65';
            UnitHeader = [NSData dataWithBytes:header length:1];
//            framecount = 1;
        }
        else
        {
            char header[4];
            header[0] = '\x41';
            //header[1] = '\x9A';
            //header[2] = framecount;
            UnitHeader = [NSData dataWithBytes:header length:1];
//            framecount++;
        }
        
        
        [fileHandle writeData:ByteHeader];
        //[fileHandle writeData:UnitHeader];
        [fileHandle writeData:data];
        
        uint8 *tempData = (uint8 *)[data bytes];
        uint8 *tempHeadData = (uint8 *)[_tempHeadData bytes];
    
        
        _tempVideoTimeStamp = (int)([[self getCurentTime] longLongValue] - currentTime);
        
//        NSLog(@"_tempVideoTimeStamp is %d",_tempVideoTimeStamp);

        if (SPSPPSSuccess >= 0) {
//            int i = Rtppush(init, tempData, (int)[data length]);
//            if (i != 0) {
//                NSLog(@"Push video error! return = %d",i);
//            }
            
            int i = ios_rtp_push(init, tempData, (int)[data length], tempHeadData, (int)[_tempHeadData length]);
            if (i != 0) {
                NSLog(@"Push video error! return = %d",i);
            }

            
        }
    }
}


- (NSString *)getIPAddress
{
    NSString *address = @"error";
    struct ifaddrs *interfaces = NULL;
    struct ifaddrs *temp_addr = NULL;
    int success = 0;
    // retrieve the current interfaces - returns 0 on success
    success = getifaddrs(&interfaces);
    if (success == 0)
    {
        // Loop through linked list of interfaces
        temp_addr = interfaces;
        while(temp_addr != NULL)
        {
            if(temp_addr->ifa_addr->sa_family == AF_INET)
            {
                // Check if interface is en0 which is the wifi connection on the iPhone
                if([[NSString stringWithUTF8String:temp_addr->ifa_name] isEqualToString:@"en0"])
                {
                    //address = [NSString stringWithUTF8String:inet_ntoa(((struct sockaddr_in *)temp_addr->ifa_netmask)->sin_addr)];
                    NSLog(@"子网掩码:%@",[NSString stringWithUTF8String:inet_ntoa(((struct sockaddr_in *)temp_addr->ifa_netmask)->sin_addr)]);
                    NSLog(@"本地IP:%@",[NSString stringWithUTF8String:inet_ntoa(((struct sockaddr_in *)temp_addr->ifa_addr)->sin_addr)]);
                    NSLog(@"广播地址:%@",[NSString stringWithUTF8String:inet_ntoa(((struct sockaddr_in *)temp_addr->ifa_dstaddr)->sin_addr)]);
                    ipStr = [NSString stringWithUTF8String:inet_ntoa(((struct sockaddr_in *)temp_addr->ifa_addr)->sin_addr)];
                    maskStr = [NSString stringWithUTF8String:inet_ntoa(((struct sockaddr_in *)temp_addr->ifa_netmask)->sin_addr)];
                }
            }
            
            temp_addr = temp_addr->ifa_next;
        }
    }
    // Free memory
    freeifaddrs(interfaces);
    return address;
}


-(NSString *)getCurentTime
{
    NSDate* dat = [NSDate dateWithTimeIntervalSinceNow:0];
    NSTimeInterval a=[dat timeIntervalSince1970];
    NSString *timeString = [NSString stringWithFormat:@"%f", a * 1000];
    return timeString;
}

@end
