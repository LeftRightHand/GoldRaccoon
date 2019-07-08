https://github.com/albertodebortoli/GoldRaccoon

``` objective-c
- (IBAction)createDirectoryButton:(id)sender
{
    
    NSString *uuid = [[NSUUID UUID] UUIDString];
    NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
    [formatter setDateFormat:@"yyyyMMdd"];
    NSString *str = [formatter stringFromDate:[NSDate date]];
    NSString *path = [NSString stringWithFormat:@"img/%@/", str];
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
```
