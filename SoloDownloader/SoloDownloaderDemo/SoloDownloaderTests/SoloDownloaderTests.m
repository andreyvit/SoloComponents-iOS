
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

- (NSURL *)URLForImageNamed:(NSString *)fileName {
    return [NSURL URLWithString:[NSString stringWithFormat:@"http://solo-components-testing.s3.amazonaws.com/photoset/%@.jpg", fileName]];
}

- (NSString *)localPathForImageNamed:(NSString *)fileName {
    return [NSTemporaryDirectory() stringByAppendingPathComponent:[NSString stringWithFormat:@"%@.jpg", fileName]];
}

- (void)runWhile:(BOOL (^)())condition {
    NSLog(@"Waiting for download to finish...");
    while (condition()) {
        CFRunLoopRunInMode(kCFRunLoopDefaultMode, 1.0, YES);
    }
}

- (void)verifyImageAt:(NSString *)localPath bytes:(long)expectedBytes size:(CGSize)expectedSize {
    long size = [[[[NSFileManager defaultManager] attributesOfItemAtPath:localPath error:nil] objectForKey:NSFileSize] longValue];
    STAssertEquals(size, expectedBytes, @"Size wrong after downloading");

    UIImage *image = [UIImage imageWithContentsOfFile:localPath];
    STAssertNotNil(image, @"Failed to load the downloaded image");
    STAssertEquals(image.size.width, expectedSize.width, @"Image width mismatch");
    STAssertEquals(image.size.height, expectedSize.height, @"Image heght mismatch");
}


- (void)xtestSuccessfulDownloadWithOperation {
    NSString *fileName = [[self sampleImages] objectAtIndex:0];
    NSURL *url = [self URLForImageNamed:fileName];
    NSString *localPath = [self localPathForImageNamed:fileName];
    [[NSFileManager defaultManager] removeItemAtPath:localPath error:nil];

    SoloDownloadOperation *operation = [[[SoloDownloadOperation alloc] initWithURL:url path:localPath] autorelease];
    operation.verbose = YES;
    [operation start];

    [self runWhile:^() { return [operation isFinished]; }];

    [self verifyImageAt:localPath bytes:835365 size:CGSizeMake(2592, 1944)];
}

- (void)xtestSuccessfulDownloadWithTask {
    NSString *fileName = [[self sampleImages] objectAtIndex:0];
    NSURL *url = [self URLForImageNamed:fileName];
    NSString *localPath = [self localPathForImageNamed:fileName];
    [[NSFileManager defaultManager] removeItemAtPath:localPath error:nil];

    SoloDownloadTask *task = [[[SoloDownloadTask alloc] initWithURL:url destinationPath:localPath interimPath:nil] autorelease];
    task.verbose = YES;
    [task.operation start];

    NSLog(@"Waiting for download to finish...");
    while (!task.finished) {
        CFRunLoopRunInMode(kCFRunLoopDefaultMode, 1.0, YES);
    }

    [self verifyImageAt:localPath bytes:835365 size:CGSizeMake(2592, 1944)];
}

- (void)testSuccessfulDownloadWithJob {
    SoloDownloadJob *job = [[[SoloDownloadJob alloc] init] autorelease];

    NSInteger count = 0;
    for (NSString *fileName in [self sampleImages]) {
        NSURL *url = [self URLForImageNamed:fileName];
        NSString *localPath = [self localPathForImageNamed:fileName];
        [[NSFileManager defaultManager] removeItemAtPath:localPath error:nil];

        SoloDownloadTask *task = [[[SoloDownloadTask alloc] initWithURL:url destinationPath:localPath interimPath:nil] autorelease];
        task.verbose = YES;
        [job addTask:task];
    }

    [job.operationQueue setMaxConcurrentOperationCount:6];
    [job start];

    [self runWhile:^() { return (BOOL) (job.state == SoloDownloadJobStateRunning); }];

    [self verifyImageAt:[[job.tasks objectAtIndex:0] destinationPath] bytes:835365 size:CGSizeMake(2592, 1944)];
    [self verifyImageAt:[[job.tasks objectAtIndex:1] destinationPath] bytes:412502 size:CGSizeMake(2048, 1444)];
    [self verifyImageAt:[[job.tasks objectAtIndex:2] destinationPath] bytes:744121 size:CGSizeMake(2592, 1944)];
    [self verifyImageAt:[[job.tasks objectAtIndex:3] destinationPath] bytes:626528 size:CGSizeMake(2592, 1944)];
    [self verifyImageAt:[[job.tasks objectAtIndex:4] destinationPath] bytes:1071877 size:CGSizeMake(2592, 1944)];
    [self verifyImageAt:[[job.tasks objectAtIndex:5] destinationPath] bytes:276225 size:CGSizeMake(1536, 1024)];
    [self verifyImageAt:[[job.tasks objectAtIndex:6] destinationPath] bytes:1021929 size:CGSizeMake(2640, 1980)];
    [self verifyImageAt:[[job.tasks objectAtIndex:7] destinationPath] bytes:1005329 size:CGSizeMake(2800, 1867)];
    [self verifyImageAt:[[job.tasks objectAtIndex:8] destinationPath] bytes:1224028 size:CGSizeMake(1944, 2592)];
    [self verifyImageAt:[[job.tasks objectAtIndex:9] destinationPath] bytes:1082475 size:CGSizeMake(1944, 2592)];
    [self verifyImageAt:[[job.tasks objectAtIndex:10] destinationPath] bytes:1433206 size:CGSizeMake(1944, 2592)];
    [self verifyImageAt:[[job.tasks objectAtIndex:11] destinationPath] bytes:2000798 size:CGSizeMake(2592, 1944)];
    [self verifyImageAt:[[job.tasks objectAtIndex:12] destinationPath] bytes:2108314 size:CGSizeMake(2592, 1944)];
}

@end
