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


typedef enum {
    SoloDownloadJobStateNeverStarted,
    SoloDownloadJobStatePaused,
    SoloDownloadJobStateRunning,
    SoloDownloadJobStateFinished,
    SoloDownloadJobStateFailed
} SoloDownloadJobState;

@interface SoloDownloadJob : NSObject {
    NSMutableArray        *_tasks;
    NSOperationQueue      *_operationQueue;

    unsigned long long     _currentSize;
    unsigned long long     _totalSize;

    BOOL                   _initialProgressComputed;
    NSError               *_lastError;
    NSInteger              _tasksEnqueued;
    NSInteger              _tasksFinished;
}

@property(nonatomic, retain) NSOperationQueue *operationQueue;  // creates the queue on first read if not previously set

@property(nonatomic, readonly) unsigned long long currentSize;
@property(nonatomic) unsigned long long totalSize;
@property(nonatomic, readonly) NSError *lastError;
@property(nonatomic, readonly) SoloDownloadJobState state;

@property(nonatomic, readonly) NSArray *tasks;
- (void)addTask:(SoloDownloadTask *)task;

- (void)start;
- (void)stop;

@end


// SoloDownloadTask manages downloading of a single file from the given URL
// to the given local path.
//
// A file is downloaded into interimPath, and then moved into destinationPath
// once it is finished. The presence of file at destinationPath is used to
// judge whether the download has already been finished.
//
// Reponsibilities:
// * computes the progress so far, and checks if the file has been fully downloaded
// * creates and manages an NSOperation to do the actual downloading
// * tracks whether its operation is enqueued or not, to avoid race conditions in 'upstream' code

@interface SoloDownloadTask : NSObject {
@private
    NSURL       *_url;
    NSString    *_destinationPath;
    NSString    *_interimPath;

    SoloDownloadOperation *_operation;

    unsigned long long _progress;
    NSError     *_lastError;

    BOOL         _queued;
    void       (^_completionHandler)();
    BOOL         _verbose;
    BOOL         _progressKnown;
    BOOL         _finished;
}

- (id)initWithURL:(NSURL *)url destinationPath:(NSString *)destinationPath interimPath:(NSString *)interimPath;
- (id)initWithURL:(NSURL *)url destinationPath:(NSString *)destinationPath;

@property(nonatomic) BOOL verbose;

@property(nonatomic, readonly) NSURL *url;
@property(nonatomic, readonly) NSString *destinationPath;
@property(nonatomic, readonly) NSString *interimPath;

@property(nonatomic, readonly) BOOL queued;
@property(nonatomic, readonly) BOOL finished;
@property(nonatomic, readonly) NSError *lastError;
@property(nonatomic, readonly) unsigned long long progress;

// only use this to run the operation manually; see [addToQueue] for NSOperationQueue usage
@property(nonatomic, readonly, retain) NSOperation *operation;

- (void)addToQueue:(NSOperationQueue *)queue;
- (void)cancel;

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
