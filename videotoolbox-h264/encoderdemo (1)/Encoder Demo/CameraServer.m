//
//  CameraServer.m
//  Encoder Demo
//
//  Created by Geraint Davies on 19/02/2013.
//  Copyright (c) 2013 GDCL http://www.gdcl.co.uk/license.htm
//

#import "CameraServer.h"
#import "AVEncoder.h"
#import "RTSPServer.h"

static CameraServer* theServer;

@interface CameraServer  () <AVCaptureVideoDataOutputSampleBufferDelegate>
{
    AVCaptureSession* _session;
    AVCaptureVideoPreviewLayer* _preview;
    AVCaptureVideoDataOutput* _output;
    dispatch_queue_t _captureQueue;
    
    AVAssetWriter *videoWriter;
    AVCaptureVideoDataOutput *videoOutput;
    AVAssetWriterInput *videoWriterInput;
    AVCaptureAudioDataOutput *audioOutput;
    AVAssetWriterInput *audioWriterInput;
    AVAssetWriterInputPixelBufferAdaptor *adaptor;
    
    AVEncoder* _encoder;
    
    RTSPServer* _rtsp;
}
@end


@implementation CameraServer

+ (void) initialize
{
    // test recommended to avoid duplicate init via subclass
    if (self == [CameraServer class])
    {
        theServer = [[CameraServer alloc] init];
    }
}

+ (CameraServer*) server
{
    return theServer;
}

- (void) startup
{
    if (_session == nil)
    {
        NSLog(@"Starting up server");
        
        [self initVideoAudioWriter];
        
        // create capture device with video input
        _session = [[AVCaptureSession alloc] init];
        AVCaptureDevice* dev = [AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeVideo];
        AVCaptureDeviceInput* input = [AVCaptureDeviceInput deviceInputWithDevice:dev error:nil];
        [_session addInput:input];
        
        // create an output for YUV output with self as delegate
        _captureQueue = dispatch_queue_create("uk.co.gdcl.avencoder.capture", DISPATCH_QUEUE_SERIAL);
        _output = [[AVCaptureVideoDataOutput alloc] init];
        [_output setSampleBufferDelegate:self queue:_captureQueue];
        NSDictionary* setcapSettings = [NSDictionary dictionaryWithObjectsAndKeys:
                                        [NSNumber numberWithInt:kCVPixelFormatType_420YpCbCr8BiPlanarVideoRange], kCVPixelBufferPixelFormatTypeKey,
                                        nil];
        _output.videoSettings = setcapSettings;
        [_session addOutput:_output];
        
        // create an encoder
        _encoder = [AVEncoder encoderForHeight:480 andWidth:720];
        [_encoder encodeWithBlock:^int(NSArray* data, double pts) {
            if (_rtsp != nil)
            {
                _rtsp.bitrate = _encoder.bitspersecond;
                [_rtsp onVideoData:data time:pts];
            }
            return 0;
        } onParams:^int(NSData *data) {
            _rtsp = [RTSPServer setupListener:data];
            return 0;
        }];
        
        // start capture and a preview layer
        [_session startRunning];
        
        
        _preview = [AVCaptureVideoPreviewLayer layerWithSession:_session];
        _preview.videoGravity = AVLayerVideoGravityResizeAspectFill;
    }
}

- (void) captureOutput:(AVCaptureOutput *)captureOutput didOutputSampleBuffer:(CMSampleBufferRef)sampleBuffer fromConnection:(AVCaptureConnection *)connection
{
    // pass frame to encoder
         [_encoder encodeFrame:sampleBuffer];
    
//    CVPixelBufferRef pixelBuffer = (CVPixelBufferRef)CMSampleBufferGetImageBuffer(sampleBuffer);
    
    
//    static int frame = 0;
//    
//    CMTime lastSampleTime = CMSampleBufferGetPresentationTimeStamp(sampleBuffer);
//    
//    if( frame == 0 && videoWriter.status != AVAssetWriterStatusWriting  )
//        
//    {
//        
//        [videoWriter startWriting];
//        
//        [videoWriter startSessionAtSourceTime:lastSampleTime];
//        
//    }
//    
//    if (captureOutput == videoOutput){
//        if( videoWriter.status > AVAssetWriterStatusWriting ){
//            NSLog(@"Warning: writer status is %ld", (long)videoWriter.status);
//            
//            if( videoWriter.status == AVAssetWriterStatusFailed )
//                
//                NSLog(@"Error: %@", videoWriter.error);
//            
//            return;
//        }
//        
//        if ([videoWriterInput isReadyForMoreMediaData])
//            
//            //            if (![videoWriterInput appendSampleBuffer:sampleBuffer]) {
//            //                NSLog(@"Unable to write to video input");
//            //            }else{
//            NSLog(@"already write vidio");
//        //            }
//    }else if (captureOutput == audioOutput){
//        
//        if( videoWriter.status > AVAssetWriterStatusWriting ){
//            
//            NSLog(@"Warning: writer status is %ld", (long)videoWriter.status);
//            
//            if( videoWriter.status == AVAssetWriterStatusFailed )
//                
//                NSLog(@"Error: %@", videoWriter.error);
//        }
//        return;
//        
//    }
//    
//    if ([audioWriterInput isReadyForMoreMediaData]){
//        
//        //        if( ![audioWriterInput appendSampleBuffer:sampleBuffer] )
//        //
//        //            NSLog(@"Unable to write to audio input");
//        //
//        //        else
//        
//        NSLog(@"already write audio");
//        
//    }
////    if(frame == FrameCount){
////        
////        [self closeVideoWriter];
////        
////    }
//    
//    frame ++;
    
}


-(void) initVideoAudioWriter

{
    
    CGSize size = CGSizeMake(480, 320);
    
    
    
    
    
    NSString *betaCompressionDirectory = [NSHomeDirectory()stringByAppendingPathComponent:@"Documents/Movie.mp4"];
    
    
    
    NSError *error = nil;
    
    
    
    unlink([betaCompressionDirectory UTF8String]);
    
    
    
    //----initialize compression engine
    
    videoWriter = [[AVAssetWriter alloc] initWithURL:[NSURL fileURLWithPath:betaCompressionDirectory]
                        
                                                 fileType:AVFileTypeQuickTimeMovie
                        
                                                    error:&error];
    
    NSParameterAssert(videoWriter);
    
    if(error)
        
        NSLog(@"error = %@", [error localizedDescription]);
    
    NSDictionary *videoCompressionProps = [NSDictionary dictionaryWithObjectsAndKeys:
                                           
                                           [NSNumber numberWithDouble:128.0*1024.0],AVVideoAverageBitRateKey,
                                           
                                           nil ];
    
    
    
    NSDictionary *videoSettings = [NSDictionary dictionaryWithObjectsAndKeys:AVVideoCodecH264, AVVideoCodecKey,
                                   
                                   [NSNumber numberWithInt:size.width], AVVideoWidthKey,
                                   
                                   [NSNumber numberWithInt:size.height],AVVideoHeightKey,videoCompressionProps, AVVideoCompressionPropertiesKey, nil];
    
    videoWriterInput = [AVAssetWriterInput assetWriterInputWithMediaType:AVMediaTypeVideo outputSettings:videoSettings];
    
    
    
    NSParameterAssert(videoWriterInput);
    
    
    
    videoWriterInput.expectsMediaDataInRealTime = YES;
    
    
    
    NSDictionary *sourcePixelBufferAttributesDictionary = [NSDictionary dictionaryWithObjectsAndKeys:
                                                           
                                                           [NSNumber numberWithInt:kCVPixelFormatType_32ARGB], kCVPixelBufferPixelFormatTypeKey, nil];
    
    
    
    adaptor = [AVAssetWriterInputPixelBufferAdaptor assetWriterInputPixelBufferAdaptorWithAssetWriterInput:videoWriterInput sourcePixelBufferAttributes:sourcePixelBufferAttributesDictionary];
    
    NSParameterAssert(videoWriterInput);
    
    NSParameterAssert([videoWriter canAddInput:videoWriterInput]);
    
    
    
    if ([videoWriter canAddInput:videoWriterInput])
        
        NSLog(@"I can add this input");
    
    else
        
        NSLog(@"i can't add this input");
    
    
    
    // Add the audio input
    
    AudioChannelLayout acl;
    
    bzero( &acl, sizeof(acl));
    
    acl.mChannelLayoutTag = kAudioChannelLayoutTag_Mono;
    
    
    
    NSDictionary* audioOutputSettings = nil;
    
    //    audioOutputSettings = [ NSDictionary dictionaryWithObjectsAndKeys:
    
    //                           [ NSNumber numberWithInt: kAudioFormatAppleLossless ], AVFormatIDKey,
    
    //                           [ NSNumber numberWithInt: 16 ], AVEncoderBitDepthHintKey,
    
    //                           [ NSNumber numberWithFloat: 44100.0 ], AVSampleRateKey,
    
    //                           [ NSNumber numberWithInt: 1 ], AVNumberOfChannelsKey,
    
    //                           [ NSData dataWithBytes: &acl length: sizeof( acl ) ], AVChannelLayoutKey,
    
    //                           nil ];
    
//    audioOutputSettings = [ NSDictionary dictionaryWithObjectsAndKeys:
    
//                           [ NSNumber numberWithInt: kAudioFormatMPEG4AAC ], AVFormatIDKey,
    
//                           [ NSNumber numberWithInt:64000], AVEncoderBitRateKey,
    
//                           [ NSNumber numberWithFloat: 44100.0 ], AVSampleRateKey,
    
//                           [ NSNumber numberWithInt: 1 ], AVNumberOfChannelsKey,
    
//                           [ NSData dataWithBytes: &acl length: sizeof( acl ) ], AVChannelLayoutKey,
    
//                           nil ];
    
    
    
    audioWriterInput = [AVAssetWriterInput
                         
                         assetWriterInputWithMediaType: AVMediaTypeAudio
                         
                         outputSettings: audioOutputSettings ];
    
    
    
    audioWriterInput.expectsMediaDataInRealTime = YES;
    
    // add input
    
    [videoWriter addInput:audioWriterInput];
    
    [videoWriter addInput:videoWriterInput];
    
}


- (void) shutdown
{
    NSLog(@"shutting down server");
    if (_session)
    {
        [_session stopRunning];
        _session = nil;
    }
    if (_rtsp)
    {
        [_rtsp shutdownServer];
    }
    if (_encoder)
    {
        [ _encoder shutdown];
    }
}

- (NSString*) getURL
{
    NSString* ipaddr = [RTSPServer getIPAddress];
    NSString* url = [NSString stringWithFormat:@"rtsp://%@/", ipaddr];
    return url;
}

- (AVCaptureVideoPreviewLayer*) getPreviewLayer
{
    return _preview;
}

@end
