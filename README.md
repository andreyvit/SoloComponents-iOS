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


ATArrayView
-----------

A container that arranges its items in rows and columns similar to the
thumbnails screen in Photos.app, the API is modeled after UITableView.

Enjoy the familiar delegate methods:

    - (NSInteger)numberOfItemsInArrayView:(ATArrayView *)arrayView {
    	return 97;
    }

    - (UIView *)viewForItemInArrayView:(ATArrayView *)arrayView atIndex:(NSInteger)index {
    	DemoItemView *itemView = (DemoItemView *) [arrayView dequeueReusableItem];
    	if (itemView == nil) {
    		itemView = [[[DemoItemView alloc] init] autorelease];
    	}
    	return itemView;
    }

There's ATArrayViewController which further reduces the amount of
boilerplate code you have to write. Similar to UITableViewController,
it:

* overrides `loadView` to create ATArrayView automatically,
* sets itself as a delegate of the array view,
* calls `reloadItems` in `viewWillAppear:` if the array view is empty.
