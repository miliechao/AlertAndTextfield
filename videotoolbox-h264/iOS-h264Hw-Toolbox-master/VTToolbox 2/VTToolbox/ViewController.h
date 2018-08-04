//
//  ViewController.h
//  h264v1
//
//  Created by Ganvir, Manish on 3/31/15.
//  Copyright (c) 2015 Ganvir, Manish. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "H264HwEncoderImpl.h"

#include <ifaddrs.h>
#include <arpa/inet.h>



@import AVFoundation;

@interface ViewController : UIViewController <AVCaptureVideoDataOutputSampleBufferDelegate,AVCaptureAudioDataOutputSampleBufferDelegate,H264HwEncoderImplDelegate>


@end

