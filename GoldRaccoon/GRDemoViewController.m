//
//  GRDemoViewController.m
//  GoldRaccoon
//
//  Created by Alberto De Bortoli on 02/07/2013.
//  Copyright (c) 2013 Alberto De Bortoli. All rights reserved.
//

#import "GRDemoViewController.h"
#import "GRRequestsManager.h"
#import "GRRequest.h"

@interface GRDemoViewController () <GRRequestsManagerDelegate, UITextFieldDelegate>
@property (weak, nonatomic) IBOutlet UIImageView *imageVIew;

@property (nonatomic, assign) NSInteger index;

@property (nonatomic, strong) GRRequestsManager *requestsManager;
@property (nonatomic, strong) IBOutlet UITextField *hostnameTextField;
@property (nonatomic, strong) IBOutlet UITextField *usernameTextField;
@property (nonatomic, strong) IBOutlet UITextField *passwordTextField;

- (IBAction)listingButton:(id)sender;
- (IBAction)createDirectoryButton:(id)sender;
- (IBAction)deleteDirectoryButton:(id)sender;
- (IBAction)deleteFileButton:(id)sender;
- (IBAction)uploadFileButton:(id)sender;
- (IBAction)downloadFileButton:(id)sender;

@end

@implementation GRDemoViewController

- (IBAction)listingButton:(id)sender
{
    [self _setupManager];
    [self.requestsManager addRequestForListDirectoryAtPath:@"appimg/LotteryChat/Chat/2019430/"];
    [self.requestsManager startProcessingRequests];
}

- (IBAction)createDirectoryButton:(id)sender
{
    
    NSString *uuid = [[NSUUID UUID] UUIDString];
    NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
    [formatter setDateFormat:@"yyyyMMdd"];
    NSString *str = [formatter stringFromDate:[NSDate date]];
    NSString *path = [NSString stringWithFormat:@"appimg/LotteryChat/Chat/%@/", str];
    NSString *uploadPath = [NSString stringWithFormat:@"%@%@.jpg", path, uuid];
    [self _setupManager];
    NSString *bundlePath = [[NSBundle mainBundle] pathForResource:@"Image_01.jpg" ofType:nil];
    NSData *data =  UIImagePNGRepresentation([UIImage imageNamed:@"imy.jpg"]);
    
    [self.requestsManager addRequestForCreateDirectoryAtPath:path sucess:^(GRRequest *request) {
        [self upload:uploadPath filePath:bundlePath data:data];;
    } failed:^(GRRequest *request, NSError *error) {
        if (request.error.errorCode == kGRFTPClientCantOverwriteDirectory) {
            [self upload:uploadPath filePath:bundlePath data:data];
        }
    }];
    [self.requestsManager startProcessingRequests];
}

- (IBAction)deleteDirectoryButton:(id)sender
{
    [self _setupManager];
    [self.requestsManager addRequestForDeleteDirectoryAtPath:@"appimg/LotteryChat/Chat/2019431/"];
    [self.requestsManager startProcessingRequests];
}

- (IBAction)deleteFileButton:(id)sender
{
    [self _setupManager];
    [self.requestsManager addRequestForDeleteFileAtPath:@"dir/file.txt"];
    [self.requestsManager startProcessingRequests];
}

- (void)upload:(NSString *)path filePath:(NSString *)filePath data:(NSData *)data {
    if (data) {
        [self.requestsManager addRequestForUploadFileAtData:data toRemotePath:path progress:^(float percent) {
            NSLog(@"progress: %f", percent);
        } sucess:^(GRRequest *request) {
            NSLog(@"sucess: %ld", request.totalBytesSent);
        } failed:^(GRRequest *request, NSError *error) {
             NSLog(@"failed: %@", error);
        }];
    } else {
        [self.requestsManager addRequestForUploadFileAtLocalPath:filePath toRemotePath:path progress:^(float percent) {
            NSLog(@"progress: %f", percent);
        } sucess:^(GRRequest *request) {
            NSLog(@"sucess: %ld", request.totalBytesSent);
        } failed:^(GRRequest *request, NSError *error) {
            NSLog(@"failed: %@", error);
        }];
    }
    [self.requestsManager startProcessingRequests];
}

- (IBAction)uploadFileButton:(id)sender
{
   
//    [self.requestsManager addRequestForUploadFileAtLocalPath:bundlePath toRemotePath:@"appimg/LotteryChat/Chat/2019430/Image_01.jpg"];
   
}

- (IBAction)downloadFileButton:(id)sender
{
    [self _setupManager];
    NSString *documentsDirectoryPath = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) lastObject];
    NSString *localFilePath = [documentsDirectoryPath stringByAppendingPathComponent:@"IMG_2327.JPG"];
    NSLog(@"%@", localFilePath);
/*
 /Users/ios/Library/Developer/CoreSimulator/Devices/3AB19A6F-E9B6-469B-8F5E-5F59C5112A1D/data/Containers/Data/Application/92279CF8-5F3E-4155-9CCE-43156C37CDC3/Documents/DownloadedFile.txt
 */
    [self.requestsManager addRequestForDownloadFileAtRemotePath:@"appimg/LotteryChat/Chat/2019430/IMG_2327.jpg" toLocalPath:localFilePath progress:^(float percent) {
        NSLog(@"%f", percent);
    } sucess:^(GRRequest *request) {
        self.imageVIew.image = [UIImage imageWithContentsOfFile:localFilePath];
    } failed:^(GRRequest *request, NSError *error) {
        NSLog(@"download failed %@", error);
    }];
    [self.requestsManager startProcessingRequests];
}

#pragma mark - Private Methods

- (void)_setupManager
{
    self.requestsManager = [[GRRequestsManager alloc] initWithHostname:[self.hostnameTextField text]
                                                                  user:[self.usernameTextField text]
                                                              password:[self.passwordTextField text]];
    self.requestsManager.delegate = self;
}

#pragma mark - UITextFieldDelegate

- (BOOL)textFieldShouldReturn:(UITextField *)textField
{
    [textField resignFirstResponder];
    return YES;
}

#pragma mark - GRRequestsManagerDelegate
/*
@brief调用，通知委托某个给定请求已被调度。
@param requestsManager请求管理器。
@param请求请求。
*/
- (void)requestsManager:(id<GRRequestsManagerProtocol>)requestsManager didScheduleRequest:(id<GRRequestProtocol>)request
{
    NSLog(@"requestsManager:didScheduleRequest:");
}

/**
@brief调用，通知委托某个给定列表请求已完成。
@param requestsManager请求管理器。
@param请求请求。
@param列出一个包含给定目录内容的数组。
*/
- (void)requestsManager:(id<GRRequestsManagerProtocol>)requestsManager didCompleteListingRequest:(id<GRRequestProtocol>)request listing:(NSArray *)listing
{
    NSLog(@"requestsManager:didCompleteListingRequest:listing: \n%@", listing);
}

- (void)requestsManager:(id<GRRequestsManagerProtocol>)requestsManager didCompleteDeleteRequest:(id<GRRequestProtocol>)request
{
    NSLog(@"requestsManager:didCompleteDeleteRequest:");
}

//- (void)requestsManager:(id<GRRequestsManagerProtocol>)requestsManager didCompletePercent:(float)percent forRequest:(id<GRRequestProtocol>)request
//{
//    NSLog(@"requestsManager:didCompletePercent:forRequest: %f", percent);
//}

//- (void)requestsManager:(id<GRRequestsManagerProtocol>)requestsManager didCompleteUploadRequest:(id<GRDataExchangeRequestProtocol>)request
//{
//    NSLog(@"requestsManager:didCompleteUploadRequest:");
//}

- (void)requestsManager:(id<GRRequestsManagerProtocol>)requestsManager didCompleteDownloadRequest:(id<GRDataExchangeRequestProtocol>)request
{
    NSLog(@"requestsManager:didCompleteDownloadRequest: ");
}

//- (void)requestsManager:(id<GRRequestsManagerProtocol>)requestsManager didFailWritingFileAtPath:(NSString *)path forRequest:(id<GRDataExchangeRequestProtocol>)request error:(NSError *)error
//{
//    NSLog(@"requestsManager:didFailWritingFileAtPath:forRequest:error: \n %@", error);
//}

//- (void)requestsManager:(id<GRRequestsManagerProtocol>)requestsManager didFailRequest:(id<GRRequestProtocol>)request withError:(NSError *)error
//{
//    NSLog(@"requestsManager:didFailRequest:withError: \n %@", error);
//}

@end
