Self-Contained Components for iOS
=================================

Two-file (.h / .m) useful components and utility classes that are dead-easy to drop into your iOS projects.

License: MIT (free for any use, no attribution required).


ATPagingView
------------

ATPagingView is a wrapper around UIScrollView in (horizontal) paging
mode, with an API similar to UITableView.

You provide the page views by implementing two delegate methods:

    - (NSInteger)numberOfPagesInPagingView:(ATPagingView *)pagingView {
    	return 10;
    }

    - (UIView *)viewForPageInPagingView:(ATPagingView *)pagingView atIndex:(NSInteger)index {
    	UIView *view = [pagingView dequeueReusablePage];
    	if (view == nil) {
    		view = [[[DemoPageView alloc] init] autorelease];
    	}
    	return view;
    }

You are also notified when the user navigates between pages:

    - (void)currentPageDidChangeInPagingView:(ATPagingView *)pagingView {
    	self.navigationItem.title = [NSString stringWithFormat:@"%d of %d", pagingView.currentPageIndex+1, pagingView.pageCount];
    }

You can use ATPagingView directly or derive your view controller from
ATPagingViewController.

ATPagingViewController is similar to UITableViewController and:

* defines `loadView` to create ATPagingView automatically,
* sets itself as a delegate of ATPagingView,
* calls `reloadPages` in `viewWillAppear:` if the paging view is empty,
* additionally it forwards orientation events to the paging view (see below).

If you want to use ATPagingView without ATPagingViewController, you
need to:

* provide your delegate object using the `delegate` property,
* call `reloadPages` to populate the view,
* if you want to support rotation, you need to invoke
  `willAnimateRotation` and `didRotate` methods from your view
  controller:

      - (void)willAnimateRotationToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation duration:(NSTimeInterval)duration {
      	[self.pagingView willAnimateRotation];
      }

      - (void)didRotateFromInterfaceOrientation:(UIInterfaceOrientation)fromInterfaceOrientation {
      	[self.pagingView didRotate];
      }
