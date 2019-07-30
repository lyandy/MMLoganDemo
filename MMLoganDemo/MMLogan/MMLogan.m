//
//  MMLogan.m
//  MMLoganDemo
//
//  Created by 李扬 on 2019/7/30.
//  Copyright © 2019 李扬. All rights reserved.
//

#import "MMLogan.h"
#import "logan.h"

uint32_t __max_upload_reversed_date; // 日志上传文件最大过期时间
NSString *__logan_upload_dir;

@interface Logan : NSObject

#if OS_OBJECT_USE_OBJC
@property (nonatomic, strong) dispatch_queue_t loganQueue;
#else
@property (nonatomic, assign) dispatch_queue_t loganQueue;
#endif

+ (instancetype)logan;
+ (NSString *)loganLogDirectory;
+ (NSInteger)getDaysFrom:(NSDate *)serverDate To:(NSDate *)endDate;

@end

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
    
    __logan_upload_dir = @"logan_upload"; // logan上传日志文件夹
    __max_upload_reversed_date = 7; // 日志上传文件最大过期时间 七天
    // 删除过期的 logan_upload 文件夹下的e文件
    [self deleteOutdatedUploadFiles];
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
    // 1. 将当前的 mmap 的数据刷入文件
    loganFlush();
    //2. 在 loganQueue 队列通过 apply 将 LoganLoggerv3 根目录下的所有日志文件 移动到 logan_upload 目录
    NSString *fromDir = [Logan loganLogDirectory];
    NSString *toDir = [self loganUploadDirectory];
    NSFileManager *fileManager = [NSFileManager defaultManager];
    [fileManager createDirectoryAtPath:toDir withIntermediateDirectories:YES attributes:nil error:nil];
    NSArray *fromFileNamesArr = [[[[NSFileManager defaultManager] contentsOfDirectoryAtPath:[Logan loganLogDirectory] error:nil] filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"SELF CONTAINS[cd] '-'"]] sortedArrayUsingSelector:@selector(compare:)]; //[c]不区分大小写 , [d]不区分发音符号即没有重音符号 , [cd]既不区分大小写，也不区分发音符号
    dispatch_apply(fromFileNamesArr.count, [Logan logan].loganQueue, ^(size_t index) {
        NSString *fileName = fromFileNamesArr[index];
        NSString *fromFullpath = [fromDir stringByAppendingPathComponent:fileName];
        NSString *toFileName = [NSString stringWithFormat:@"%@_%lld", fileName, @([[NSDate date] timeIntervalSince1970]).longLongValue];
        NSString *toFullpath = [toDir stringByAppendingPathComponent:toFileName];
        // 剪切
        [fileManager moveItemAtPath:fromFullpath toPath:toFullpath error:nil];
    });
    
    // 3. 遍历数据上传文件
    NSArray *uploadFileNamesArr = [fileManager contentsOfDirectoryAtPath:toDir error:nil];
    [uploadFileNamesArr enumerateObjectsUsingBlock:^(id  _Nonnull fileName, NSUInteger idx, BOOL * _Nonnull stop) {
        NSString *filePath = [toDir stringByAppendingPathComponent:fileName];
        NSString *urlStr = [NSString stringWithFormat:@"http://127.0.0.1:3000/logupload?name=%@", [filePath lastPathComponent]];
        NSURL *url = [NSURL URLWithString:urlStr];
        NSMutableURLRequest *req = [[NSMutableURLRequest alloc] initWithURL:url cachePolicy:NSURLRequestReloadIgnoringCacheData timeoutInterval:60];
        [req setHTTPMethod:@"POST"];
        [req addValue:@"binary/octet-stream" forHTTPHeaderField:@"Content-Type"];
        NSURL *fileUrl = [NSURL fileURLWithPath:filePath];
        NSURLSessionUploadTask *task = [[NSURLSession sharedSession] uploadTaskWithRequest:req fromFile:fileUrl completionHandler:^(NSData *_Nullable data, NSURLResponse *_Nullable response, NSError *_Nullable error) {
            if (error == nil)
            {
                // 4. 上传成功后删除本地 logan_upload 目录下文件
                [self deleteLoganUploadFile:fileName];
            }
        }];
        [task resume];
    }];
}

+ (void)deleteOutdatedUploadFiles
{
    NSFileManager *fileManager = [NSFileManager defaultManager];
    NSArray *uploadFileNamesArr = [fileManager contentsOfDirectoryAtPath:[self loganUploadDirectory] error:nil];
    __block NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
    NSString *dateFormatString = @"yyyy-MM-dd";
    [formatter setDateFormat:dateFormatString];
    [uploadFileNamesArr enumerateObjectsUsingBlock:^(NSString *_Nonnull fileName, NSUInteger idx, BOOL *_Nonnull stop) {
        NSString *dateStr = [fileName componentsSeparatedByString:@"_"].firstObject;

        // 检查长度
        if (dateStr.length != (dateFormatString.length))
        {
            [self deleteLoganUploadFile:fileName];
            return;
        }
        
        // 转化为日期
        dateStr = [dateStr substringToIndex:dateFormatString.length];
        NSDate *date = [formatter dateFromString:dateStr];
        NSString *todayStr = loganTodaysDate();
        NSDate *todayDate = [formatter dateFromString:todayStr];
        if (!date || [Logan getDaysFrom:date To:todayDate] >= __max_upload_reversed_date)
        {
            // 删除过期文件
            [self deleteLoganUploadFile:fileName];
        }
    }];
}


+ (NSString *)loganUploadDirectory
{
    static NSString *dir = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        dir = [[Logan loganLogDirectory] stringByAppendingPathComponent:__logan_upload_dir];
    });
    return dir;
}

+ (void)deleteLoganUploadFile:(NSString *)name
{
    dispatch_async([Logan logan].loganQueue, ^{
        NSFileManager *fileManager = [NSFileManager defaultManager];
        [fileManager removeItemAtPath:[[self loganUploadDirectory] stringByAppendingPathComponent:name] error:nil];
    });
}


@end
