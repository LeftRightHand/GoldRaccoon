//
//  GRCreateDirectoryRequest.m
//  GoldRaccoon
//  v1.0.1
//
//  Created by Valentin Radu on 8/23/11.
//  Copyright 2011 Valentin Radu. All rights reserved.
//
//  Modified and/or redesigned by Lloyd Sargent to be ARC compliant.
//  Copyright 2012 Lloyd Sargent. All rights reserved.
//
//  Modified and redesigned by Alberto De Bortoli.
//  Copyright 2013 Alberto De Bortoli. All rights reserved.
//

#import "GRCreateDirectoryRequest.h"
#import "GRListingRequest.h"

@interface GRCreateDirectoryRequest () <GRRequestDelegate, GRRequestDataSource>

@property NSString *fullPath;

@end

@implementation GRCreateDirectoryRequest

//@synthesize listrequest;

- (NSString *)path
{
    // the path will always point to a directory, so we add the final slash to it (if there was one before escaping/standardizing, it's *gone* now)
    NSString *directoryPath = [super path];
    if (![directoryPath hasSuffix: @"/"]) {
        directoryPath = [directoryPath stringByAppendingString:@"/"];
    }
    if (!self.fullPath) {
        self.fullPath = directoryPath;
    }
    return directoryPath;
}

- (void)start
{
    if ([self hostnameForRequest:self] == nil) {
        self.error = [[GRError alloc] init];
        self.error.errorCode = kGRFTPClientHostnameIsNil;
        [self.delegate requestFailed:self];
        return;
    }
    
    // we first list the directory to see if our folder is up already
    self.listrequest = [[GRListingRequest alloc] initWithDelegate:self datasource:self];
    self.listrequest.path = [self.path stringByDeletingLastPathComponent];
    [self.listrequest start];
}

- (NSArray *)fetchFirstLastRoot:(NSArray *)components {
    NSMutableArray *data = [NSMutableArray arrayWithArray:components];
    NSString *last = data.lastObject;
    if ([last isEqualToString:@"/"]) {
        [data removeLastObject];
    }
    NSString *first = data.firstObject;
    if ([first isEqualToString:@"/"]) {
        [data removeObjectAtIndex:0];
    }
    return data;
}

- (void)fecthLastComponent {
    
//    if ([self.path isEqualToString:self.fullPath]) {
//
//    }

//    BOOL isLastPathComponent = NO;
    NSString *currentLastPathComponent = [[self.path lastPathComponent] stringByTrimmingCharactersInSet:[NSCharacterSet characterSetWithCharactersInString:@"/"]];
     NSString *fullLastPath = [[self.fullPath lastPathComponent] stringByTrimmingCharactersInSet:[NSCharacterSet characterSetWithCharactersInString:@"/"]];
    if ([currentLastPathComponent isEqualToString:fullLastPath]) {
        [self.streamInfo streamComplete:self];
    } else {
        NSArray *currentComponents = [self.path pathComponents];
        currentComponents = [self fetchFirstLastRoot:currentComponents];
        
        NSArray *components = [self.fullPath pathComponents];
        components = [self fetchFirstLastRoot:components];
       
        NSInteger index = currentComponents.count;
        self.path = [NSString stringWithFormat:@"%@%@", self.path, components[index]];
        [self start];
    }
//    if (self.listrequest.filesInfo.count == 0) {
//        [self.streamInfo streamError:self errorCode:kGRFTPClientCantOverwriteDirectory];
//        return;
//    }
//    for (NSDictionary *dict in self.listrequest.filesInfo) {
//
//        NSString *resourceName = [dict objectForKey:kCFFTPResourceName];
//        NSLog(@"resourceName: %@", resourceName);
//        if ([resourceName isEqualToString:currentLastPathComponent]) {
//            if (isLastPathComponent) {
//                [self.streamInfo streamComplete:self];
//            } else {
//
//            }
//        }
//    }
//    NSArray *currentPath = [self.path pathComponents];
//
//    NSInteger index = currentPath.count - 1;
//    if (fullPaht.count > index) {
//        NSString *path = fullPaht[index];
//        path = [NSString stringWithFormat:@"%@%@", self.path, path];
//        self.path = path;
//        [self start];
//    } else {
//        [self.streamInfo streamError:self errorCode:kGRFTPClientCantOverwriteDirectory];
//    }
}


#pragma mark - GRRequestDelegate

- (void)requestCompleted:(GRRequest *)request
{
    NSString *directoryName = [[self.path lastPathComponent] stringByTrimmingCharactersInSet:[NSCharacterSet characterSetWithCharactersInString:@"/"]];
    
/*
 addRequestForCreateFailError Domain=com.albertodebortoli.goldraccoon Code=-1000 "(null)" UserInfo={message=Can't overwrite directory!} 7
 2019-05-05 10:55:04.517706+0800 GoldRaccoon[3413:178853] requestsManager:didFailRequest:withError:
 Error Domain=com.albertodebortoli.goldraccoon Code=-1000 "(null)" UserInfo={message=Can't overwrite directory!}
 */
    if ([self.listrequest fileExists:directoryName]) {
        [self.streamInfo streamError:self errorCode:kGRFTPClientCantOverwriteDirectory];
    } else {
        // open the write stream and check for errors calling delegate methods
        // if things fail. This encapsulates the streamInfo object and cleans up our code.
        [self.streamInfo openWrite:self];
    }
}


- (void)requestFailed:(GRRequest *)request
{
    if (request.path.length > 0 && request.error.errorCode == kGRFTPServerFileNotAvailable) {
        self.path = request.path;
        [self start];
    } else {
        [self.delegate requestFailed:request];
    }
    
}

- (BOOL)shouldOverwriteFile:(NSString *)filePath forRequest:(id<GRDataExchangeRequestProtocol>)request
{
    return NO;
}

#pragma mark - GRRequestDataSource

- (NSString *)hostnameForRequest:(id<GRRequestProtocol>)request
{
    return [self.dataSource hostnameForRequest:request];
}

- (NSString *)usernameForRequest:(id<GRRequestProtocol>)request
{
    return [self.dataSource usernameForRequest:request];
}

- (NSString *)passwordForRequest:(id<GRRequestProtocol>)request
{
    return [self.dataSource passwordForRequest:request];
}

#pragma mark - NSStreamDelegate

- (void)stream:(NSStream *)theStream handleEvent:(NSStreamEvent)streamEvent
{
    switch (streamEvent) {
        // XCode whines about this missing - which is why it is here
        case NSStreamEventNone:
        case NSStreamEventHasBytesAvailable:
        case NSStreamEventHasSpaceAvailable: {
            break;
        }
            
        case NSStreamEventOpenCompleted: {
            self.didOpenStream = YES;
            break;
        }

        case NSStreamEventErrorOccurred: {
            // perform callbacks and close out streams
            [self.streamInfo streamError:self errorCode:[GRError errorCodeWithError:[theStream streamError]]];
            break;
        }
            
        case NSStreamEventEndEncountered: {
            // perform callbacks and close out streams
//            NSDictionary *dict = self.listrequest.filesInfo.lastObject;
//            NSLog(@"%@", [dict objectForKey:kCFFTPResourceName]);
//            [self.streamInfo streamComplete:self];
            [self fecthLastComponent];
            break;
        }
            
        default:
            break;
    }
}

@end
