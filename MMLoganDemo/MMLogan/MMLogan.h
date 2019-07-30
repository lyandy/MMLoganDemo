//
//  MMLogan.h
//  MMLoganDemo
//
//  Created by 李扬 on 2019/7/30.
//  Copyright © 2019 李扬. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef enum : NSUInteger {
    MMLoganTypeAction = 1,  //用户行为日志
    MMLoganTypeNetwork = 2, //网络级日志
} MMLoganType;

@interface MMLogan : NSObject

+ (void)initLog;

+ (void)initLogWithAES_Key:(NSData *)key iv:(NSData *)iv;

+ (void)setConsoleLogEnabled:(BOOL)enbaled;

+ (void)eventLogType:(MMLoganType)eventType forLabel:(NSString *)label;

+ (NSString *)allFilesInfo;

+ (void)uploadFileCompletion:(void(^)(NSError *error, BOOL result))completion;

@end
