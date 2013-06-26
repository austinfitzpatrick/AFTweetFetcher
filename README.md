AFTweetFetcher
==============

Simple class for retrieving tweets from twitter using their new 1.1 API without requiring the user to authenticate or have a twitter account stored on their device.  I felt that accessing the most recent public tweets made by a given account should not require the user to have their credentials stored but as of the v1.1 API some authentication is required even for basic requests.  This class allows you to authenticate at an application level rather than a user level.  You can read about application-level authentication here:  https://dev.twitter.com/docs/auth/application-only-auth

Requirements
------------

This class currently only supports iOS 5.0 and up because it leverages changes made to NSURLConnection in iOS 5.0.  Support for older versions of iOS could be added in the future using ASIHTTPRequest.

This class requires you to have an application registered with twitter.  When viewing your application in twitter's developer area you should see the following information (blacked out for this example):

![screenshot of twitter control panel showing consumer key](http://i.imgur.com/xNczrn1.png)

Take note of your Consumer key and Consumer secret, they will serve as your authentication for accessing the twitter API.

Example Use
-----------

Here is the most basic usage using the block syntax to retrieve a single tweet.

    NSString *myConsumerKey = @""; //set this to your consumer key from twitter
    NSString *myConsumerSecret = @""; //set this to your consumer secret from twitter
    [AFTweetFetcher setConsumerKey:myConsumerKey andConsumerSecret:myConsumerSecret];
    [AFTweetFetcher getMostRecentTweetFor:@"NASA" then:^(*AFTweet tweet){
	//do whatever you'd like to do with the tweet here.
        NSLog(@"%@ - %@ on %@", tweet.text, tweet.author, tweet.postDate);
    }];

You can also retrieve multiple tweets at once:

    NSString *myConsumerKey = @""; //set this to your consumer key from twitter
    NSString *myConsumerSecret = @""; //set this to your consumer secret from twitter
    [AFTweetFetcher setConsumerKey:myConsumerKey andConsumerSecret:myConsumerSecret];
    [AFTweetFetcher get:3 mostRecentTweetsFor:@"NASA" then:^(*NSArray tweets){
	//do whatever you'd like to do with the tweets here.
        NSLog(@"%@", tweets);
    }];

You can also use a delegate instead of the block syntax:

    NSString *myConsumerKey = @""; //set this to your consumer key from twitter
    NSString *myConsumerSecret = @""; //set this to your consumer secret from twitter
    [AFTweetFetcher setConsumerKey:myConsumerKey andConsumerSecret:myConsumerSecret];
    [AFTweetFetcher setDelegate:self];
    [AFTweetFetcher get:3 mostRecentTweetsFor:@"NASA"]; //block not required

AFTweet Properties
------------------

The AFTweet object that is returned by calls to retrieve tweets has the following readonly public properties:

* text (an `NSString` containing the full text of the tweet)
* postDate (an `NSDate` representing the date and time the tweet as posted)
* account (an `NSString` containing the account name)
* permalink (an `NSURL` pointing at the tweet)
* mediaURL (an `NSURL` pointing at any media attached to the tweet)
* idNumber (an `NSString` representing the tweet's unique ID number)

The full dictionary parsed from the JSON returned by twitter is also available in case one of these convenience properties doesn't meet your requirements.

* fullDictionary (an `NSDictionary` created from the JSON returned by twitter)