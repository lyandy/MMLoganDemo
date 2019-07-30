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
    dispatch_async(dispatch_get_global_queue(0, 0), ^{
        for (int i = 0; i < 10000; i++) {
            //行为日志
            usleep(500000);
            [MMLogan eventLogType:MMLoganTypeAction forLabel:[NSString stringWithFormat:@"click button %d", _count++]];
        }
    });
}

- (IBAction)allFilesInfo:(id)sender
{
    self.filesInfo.text = [MMLogan allFilesInfo];
}

- (IBAction)uploadFile:(id)sender
{
    [MMLogan uploadLoganFile];
}



@end
