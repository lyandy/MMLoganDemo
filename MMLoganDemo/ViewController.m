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
    for (int i = 0; i < 10; i++) {
        //行为日志
        [MMLogan eventLogType:MMLoganTypeAction forLabel:[NSString stringWithFormat:@"click button %d", _count++]];
    }
}

- (IBAction)allFilesInfo:(id)sender
{
    self.filesInfo.text = [MMLogan allFilesInfo];
}

- (IBAction)uploadFile:(id)sender
{
    [MMLogan uploadFileCompletion:^(NSError *error, BOOL result) {
        dispatch_async(dispatch_get_main_queue(), ^{
            UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:result == YES ? @"成功" : @"失败" message:error.localizedDescription delegate:nil cancelButtonTitle:@"好的" otherButtonTitles:nil, nil];
            [alertView show];
        });
    }];
}



@end
