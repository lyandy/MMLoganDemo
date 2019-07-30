//
//  MMLogan.h
//  MMLoganDemo
//
//  Created by 李扬 on 2019/7/30.
//  Copyright © 2019 李扬. All rights reserved.
//

#import <Foundation/Foundation.h>

// 示例 Type
typedef enum : NSUInteger {
    MMLoganTypeAction = 1,  //用户行为日志
    MMLoganTypeNetwork = 2, //网络级日志
} MMLoganType;

@interface MMLogan : NSObject

// 初始化log
+ (void)initLog;
// 初始化log 带有AES加密key和iv
// 默认开启控制台日志输出，默认7天删除日志文件和上传日志文件
+ (void)initLogWithAES_Key:(NSData *)key iv:(NSData *)iv;

// 设置控制台是否输出日志
+ (void)setConsoleLogEnabled:(BOOL)enbaled;

// 打点
+ (void)eventLogType:(MMLoganType)eventType forLabel:(NSString *)label;

// 获取日志文件信息：日期和大小
+ (NSString *)allFilesInfo;

// 上传日志文件
+ (void)uploadLoganFile;

@end
