//
//  MMLogan.m
//  MMLoganDemo
//
//  Created by 李扬 on 2019/7/30.
//  Copyright © 2019 李扬. All rights reserved.
//

#import "MMLogan.h"
#import "logan.h"
#import <sys/xattr.h>

@implementation MMLogan

+ (void)initLog
{
    NSData *keydata = [@"0123456789012345" dataUsingEncoding:NSUTF8StringEncoding];
    NSData *ivdata = [@"0123456789012345" dataUsingEncoding:NSUTF8StringEncoding];
    
    [self initLogWithAES_Key:keydata iv:ivdata];
}

+ (void)initLogWithAES_Key:(NSData *)key iv:(NSData *)iv
{
    uint64_t file_max = 10 * 1024 * 1024; // 日志最大大小 10M
    loganInit(key, iv, file_max);
    // 将日志输出至控制台
    loganUseASL(YES);
}

+ (void)setConsoleLogEnabled:(BOOL)enbaled
{
    loganUseASL(enbaled);
}

/**
 用户行为日志
 
 @param eventType 事件类型
 @param label 描述
 */
+ (void)eventLogType:(MMLoganType)eventType forLabel:(NSString *)label
{
    NSMutableString *s = [NSMutableString string];
    [s appendFormat:@"%d\t", (int)eventType];
    [s appendFormat:@"%@\t", label];
    logan(eventType, s);
}

+ (NSString *)allFilesInfo
{
    NSDictionary *files = loganAllFilesInfo();
    
    NSMutableString *str = [[NSMutableString alloc] init];
    for (NSString *k in files.allKeys) {
        [str appendFormat:@"文件日期 %@，大小 %@byte\n", k, [files objectForKey:k]];
    }
    
    return [str copy];
}

+ (void)uploadLoganFile
{
    [self uploadLoganFileWithDate:loganTodaysDate()];
}

+ (void)uploadLoganFileWithDate:(NSString *)date
{
    loganUploadFilePath(date, ^(NSString *_Nullable filePath) {
        if (filePath == nil)
        {
            return;
        }
        NSString *urlStr = [NSString stringWithFormat:@"http://127.0.0.1:3000/logupload?name=%@", [filePath lastPathComponent]];
        NSMutableURLRequest *req = [[NSMutableURLRequest alloc] initWithURL:[NSURL URLWithString:urlStr] cachePolicy:NSURLRequestReloadIgnoringCacheData timeoutInterval:60];
        [req setHTTPMethod:@"POST"];
        [req addValue:@"binary/octet-stream" forHTTPHeaderField:@"Content-Type"];
        NSURL *fileUrl = [NSURL fileURLWithPath:filePath];
        NSURLSessionUploadTask *task = [[NSURLSession sharedSession] uploadTaskWithRequest:req fromFile:fileUrl completionHandler:^(NSData *_Nullable data, NSURLResponse *_Nullable response, NSError *_Nullable error) {
            if (error == nil)
            {
                NSLog(@"上传完成");
            }
            else
            {
                NSLog(@"上传失败 error:%@", error);
            }
        }];
        [task resume];
    });
}

@end
