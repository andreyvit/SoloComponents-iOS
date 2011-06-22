//
//  Copyright 2011 Andrey Tarantsov. Distributed under the MIT license.
//
//  ATPagingView official version 1.1.
//

#import <Foundation/Foundation.h>

@protocol ATPagingViewDelegate;

// A wrapper around UIScrollView in (horizontal) paging mode, with an
// API similar to UITableView.
//
// Adds the following features on top of UIScrollView:
//
// * API in terms of pages
// * automatic management of page view loading and unloading
// * expected rotation behavior with smooth animation
// * configurable gap between pages
// * configurable preloading of next/previous yet-invisible pages

@interface ATPagingView : UIView {
    // subviews
    UIScrollView *_scrollView;

    // properties
    id<ATPagingViewDelegate> _delegate;
    CGFloat _gapBetweenPages;
    NSInteger _pagesToPreload;

    // state
    NSInteger _pageCount;
    NSInteger _currentPageIndex;
    NSInteger _firstLoadedPageIndex;
    NSInteger _lastLoadedPageIndex;
    NSMutableSet *_recycledPages;
    NSMutableSet *_visiblePages;

    NSInteger _previousPageIndex;

    BOOL _rotationInProgress;
    BOOL _scrollViewIsMoving;
    BOOL _recyclingEnabled;
}

@property(nonatomic, assign) IBOutlet id<ATPagingViewDelegate> delegate;

@property(nonatomic, assign) CGFloat gapBetweenPages;  // default is 20

@property(nonatomic, assign) NSInteger pagesToPreload;  // number of invisible pages to keep loaded to each side of the visible pages, default is 1

@property(nonatomic, readonly) NSInteger pageCount;     // cached number of pages

@property(nonatomic, assign) NSInteger currentPageIndex;  // set to navigate to another page
@property(nonatomic, assign, readonly) NSInteger previousPageIndex; // only for reading inside currentPageDidChangeInPagingView

@property(nonatomic, assign, readonly) NSInteger firstVisiblePageIndex;
@property(nonatomic, assign, readonly) NSInteger lastVisiblePageIndex;

@property(nonatomic, assign, readonly) NSInteger firstLoadedPageIndex;   // == firstVisiblePageIndex if pagesToPreload==0, otherwise could be less
@property(nonatomic, assign, readonly) NSInteger lastLoadedPageIndex;    // == lastVisiblePageIndex  if pagesToPreload==0, otherwise could be greater

@property(nonatomic, assign, readonly) BOOL moving;  // YES if scrolling or decelerating at the moment

@property(nonatomic, assign) BOOL recyclingEnabled; // set to NO to always allocate new page views for new pages, default is YES

- (void)reloadData;  // must be called at least once to display something

- (UIView *)viewForPageAtIndex:(NSUInteger)index;  // nil if not loaded

- (UIView *)dequeueReusablePage;  // nil if none available, always nil if recyclingEnabled==NO

// Rotation hooks. Call from your view controller to allow for better rotation logic.
- (void)willAnimateRotation;  // call this from willAnimateRotationToInterfaceOrientation:duration:
- (void)didRotate;  // call this from didRotateFromInterfaceOrientation:

@end


@protocol ATPagingViewDelegate <NSObject>

@required

- (NSInteger)numberOfPagesInPagingView:(ATPagingView *)pagingView;

- (UIView *)viewForPageInPagingView:(ATPagingView *)pagingView atIndex:(NSInteger)index;

@optional

- (void)currentPageDidChangeInPagingView:(ATPagingView *)pagingView;

- (void)pagesDidChangeInPagingView:(ATPagingView *)pagingView;

// a good place to start and stop background processing
- (void)pagingViewWillBeginMoving:(ATPagingView *)pagingView;
- (void)pagingViewDidEndMoving:(ATPagingView *)pagingView;

@end


@interface ATPagingViewController : UIViewController <ATPagingViewDelegate> {
    ATPagingView *_pagingView;
}

@property(nonatomic, retain) IBOutlet ATPagingView *pagingView;

@end
