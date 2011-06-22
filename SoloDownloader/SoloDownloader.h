//
// SoloDownloader 0.1
// http://solo-components.com/
//
// Copyright 2011 Andrey Tarantsov. Distributed under the MIT license.
//
#import <Foundation/Foundation.h>

@class SoloDownloadJob;
@class SoloDownloadTask;
@class SoloDownloadOperation;


@interface SoloDownloadJob



@end


// SoloDownloadTask manages downloading of a single file from the given URL
// to the given local path.
//
// Reponsibilities:
// * computes the progress so far
// * creates and manages an NSOperation to do the actual downloading
@interface SoloDownloadTask : NSObject {
@private
    NSURL       *_url;
    NSString    *_destinationPath;
    NSString    *_interimPath;

    SoloDownloadOperation *_operation;
    
    unsigned long long _progress;
    NSError     *_lastError;

    BOOL         _verbose;
    BOOL         _progressKnown;
    BOOL         _finished;
}

- (id)initWithURL:(NSURL *)url destinationPath:(NSString *)destinationPath interimPath:(NSString *)interimPath;

@property(nonatomic) BOOL verbose;

@property(nonatomic, readonly) BOOL finished;
@property(nonatomic, readonly) unsigned long long progress;

@property(nonatomic, readonly, retain) NSOperation *operation;

@end


@interface SoloDownloadOperation : NSOperation {
@private
    NSURL       *_url;
    NSString    *_path;

    NSError     *_error;
    
    unsigned long long _progress;
    NSMutableData     *_receivedData;
    NSURLConnection   *_connection;

    BOOL _verbose;
    BOOL _isFinished;
    BOOL _isExecuting;
}

- (id)initWithURL:(NSURL *)url path:(NSString *)path;

@property(nonatomic) BOOL verbose;
@property(nonatomic, readonly) NSError *error;

@end
