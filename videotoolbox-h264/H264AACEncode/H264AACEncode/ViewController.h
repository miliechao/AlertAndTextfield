//
//  ViewController.h
//  H264AACEncode
//
//  Created by ZhangWen on 15/10/14.
//  Copyright © 2015年 Zhangwen. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <AVFoundation/AVFoundation.h>
#import "AACEncoder.h"
#import "H264Encoder.h"


@interface ViewController : UIViewController <AVCaptureVideoDataOutputSampleBufferDelegate,AVCaptureAudioDataOutputSampleBufferDelegate,H264EncoderDelegate>


@end
