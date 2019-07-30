//
//  ViewController.m
//  MMLoganDemo
//
//  Created by 李扬 on 2019/7/30.
//  Copyright © 2019 李扬. All rights reserved.
//

#import "ViewController.h"
#import "MMLogan.h"

@interface ViewController ()

@property (nonatomic, assign) int count;
@property (weak, nonatomic) IBOutlet UITextView *filesInfo;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
}

- (IBAction)lllog:(id)sender
{
    // 模拟日志记录
    dispatch_async(dispatch_get_global_queue(0, 0), ^{
        for (int i = 0; i < 10000; i++) {
            //行为日志
            usleep(500000);
            [MMLogan eventLogType:MMLoganTypeAction forLabel:[NSString stringWithFormat:@"click button %d", self->_count++]];
        }
    });
}

- (IBAction)allFilesInfo:(id)sender
{
    // 显示日志信息：名称和大小
    self.filesInfo.text = [MMLogan allFilesInfo];
}

- (IBAction)uploadFile:(id)sender
{
    // 日志上传
    [MMLogan uploadLoganFile];
}



@end
