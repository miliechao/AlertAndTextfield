//
//  PLAudioStreamingConfiguration.h
//  PLAudioStreamingKit
//
//  Created on 15/4/28.
//  Copyright (c) 2015年 Pili Engineering, Qiniu Inc. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "PLTypeDefines.h"
#import "PLMacroDefines.h"

@interface PLAudioStreamingConfiguration : NSObject

@property (nonatomic, assign, readonly) PLStreamingAudioBitRate audioBitRate;   // alwyas PLStreamingAudioBitRate_128Kbps ready now
@property (nonatomic, assign, readonly) NSUInteger audioSampleRate; // always 44100 ready now

+ (instancetype)defaultConfiguration;
+ (instancetype)configurationWithAudioBitRate:(PLStreamingAudioBitRate)audioBitRate;

@end
