# FlickrByMe
A sample iOS app showing how to use the Flickr REST API to show photos that were tagged geographically close to the user.

# Requirements

1. Create an new iOS or Android application.
2. The application must be universal (iPhone & iPad for iOS -or- phone & tablet for Android).
3. Call the Flickr API and pull in a list of photos for the users current location.
4. Display the photos in some form of a list (table, collection/grid, whatever).
5. Allow photos in the list to be tapped which will display the photo full screen in a new view. 5a. When on smaller phone sized devices display the photo full screen, cropping parts of the photo is expected and perfectly OK. Do not show any text that may have accompanied the photo, only show the photo.
6. When on a tablet sized device display the photo with a max size of 500x500 and anchored to the top of the view with any necessary padding needed to align the top of the photo below any nav/tool bars. Below the photo, add the text comment that accompanied the photo from the Flickr API. The text should not truncate, it should always show the full text regardless of the amount of text.
7. Incorporate some sort of animation.
8. There are no restrictions of 3rd party libraries, use what ever you would normally use to complete these tasks.
9. Have fun with it! Add anything else you think could complement your project and show off your skills.
10. Send us a link to the github/bitbucket repo when you're done.

# Implementation Notes

- Use of paging combined with the UICollectionViewDataSource delegation to download in batches as the user scrolls deeper.  Without this you would either a) have to download a huge set of photos all at once or b) limit the collection to a static size -- neither of which is good.
- Asynchronous image loading combined with a concurrent NSOperationQueue to get images loading in parallel.
- Use of an NSCache for storing the most recently used photos.  This allows the user to reverse direction when scrolling and be able to immediately see the previous photos.
- Use of layout constraints in conjunction with size classes to alter the layout when using iPhone vs iPad.
- Basic examples of UIView animation to achieve alpha and translation animations.

# Usage

- Requires iOS 8.4+
- If you did not grant the location access permission just turn it on in the system settings and then return to the app.  Since it's not a real-world app this is not coached with a UI.
- If you are running on the simulator make sure you have it setup to provide a real location.  Easiest thing is to just select the "Debug --> Location --> Apple" 



