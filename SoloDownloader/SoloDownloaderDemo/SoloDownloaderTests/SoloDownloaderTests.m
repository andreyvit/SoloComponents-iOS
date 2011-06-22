
#import "SoloDownloaderTests.h"
#import "SoloDownloader.h"


@implementation SoloDownloaderTests

- (NSArray *)sampleImages {
    return [NSArray arrayWithObjects:
            @"4962672823_0db01eca31_o", @"4962673061_dcbd7df69f_o", @"4962688983_73bbd15072_o", 
            @"4962691003_43372e83f5_o", @"4962707651_135464c58d_o", @"4963248346_b3a1d409cf_o", 
            @"5222933819_1ae7e1be4d_o", @"5223637293_3f1cb9425d_o", @"5259632129_f98a64d10b_o", 
            @"5259633117_548673b31e_o", @"5259646731_9ca849779d_o", @"5295545803_0d48d3f795_o", 
            @"5296139002_0cbe274f31_o", nil];
}

- (void)xtestSuccessfulDownloadWithOperation {
    NSString *fileName = [[self sampleImages] objectAtIndex:0];
    NSURL *url = [NSURL URLWithString:[NSString stringWithFormat:@"http://solo-components-testing.s3.amazonaws.com/photoset/%@.jpg", fileName]];
    NSString *localPath = [NSTemporaryDirectory() stringByAppendingPathComponent:[NSString stringWithFormat:@"%@.jpg", fileName]];
    [[NSFileManager defaultManager] removeItemAtPath:localPath error:nil];
    
    SoloDownloadOperation *operation = [[[SoloDownloadOperation alloc] initWithURL:url path:localPath] autorelease];
    operation.verbose = YES;
    [operation start];
    
    NSLog(@"Waiting for download to finish...");
    while (![operation isFinished]) {
        CFRunLoopRunInMode(kCFRunLoopDefaultMode, 1.0, YES);
    }
    
    long size = [[[[NSFileManager defaultManager] attributesOfItemAtPath:localPath error:nil] objectForKey:NSFileSize] longValue];
    STAssertEquals(size, 835365l, @"Size wrong after downloading");
    
    UIImage *image = [UIImage imageWithContentsOfFile:localPath];
    STAssertNotNil(image, @"Failed to load the downloaded image");
    STAssertEquals(image.size.width, 2592.0f, @"Image width mismatch");
    STAssertEquals(image.size.height, 1944.0f, @"Image heght mismatch");
}

- (void)testSuccessfulDownloadWithTask {
    NSString *fileName = [[self sampleImages] objectAtIndex:0];
    NSURL *url = [NSURL URLWithString:[NSString stringWithFormat:@"http://solo-components-testing.s3.amazonaws.com/photoset/%@.jpg", fileName]];
    NSString *localPath = [NSTemporaryDirectory() stringByAppendingPathComponent:[NSString stringWithFormat:@"%@.jpg", fileName]];
    [[NSFileManager defaultManager] removeItemAtPath:localPath error:nil];
    
    SoloDownloadTask *task = [[[SoloDownloadTask alloc] initWithURL:url destinationPath:localPath interimPath:nil] autorelease];
    task.verbose = YES;
    [task.operation start];
    
    NSLog(@"Waiting for download to finish...");
    while (!task.finished) {
        CFRunLoopRunInMode(kCFRunLoopDefaultMode, 1.0, YES);
    }
    
    long size = [[[[NSFileManager defaultManager] attributesOfItemAtPath:localPath error:nil] objectForKey:NSFileSize] longValue];
    STAssertEquals(size, 835365l, @"Size wrong after downloading");
    
    UIImage *image = [UIImage imageWithContentsOfFile:localPath];
    STAssertNotNil(image, @"Failed to load the downloaded image");
    STAssertEquals(image.size.width, 2592.0f, @"Image width mismatch");
    STAssertEquals(image.size.height, 1944.0f, @"Image heght mismatch");
}

@end
