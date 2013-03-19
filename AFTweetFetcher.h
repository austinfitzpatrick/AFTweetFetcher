//
//  AFTweetFetcher.h
//
//  Created by Austin J Fitzpatrick on 3/14/13.
//
//  Given a Twitter application's OAuthToken and OAuthSecret this class
//  will retrieve a given number of tweets for display and use in your
//  app.  The upside to this class versus SLRequest is that the user
//  does not need to authenticate with twitter.
//
//  This class uses twitter's new v1.1 API: https://dev.twitter.com/docs/api/1.1
//

#import <Foundation/Foundation.h>
#import "AFTweetFetcherDelegate.h"
#import "AFTweetTypes.h"
@class AFTweet;



@interface AFTweetFetcher : NSObject

/**
 *  You will typically call this method first providing the consumerKey and consumerSecret from
 *  your twitter app's control panel.  Without these the app can't connect to anything.
 */
+(void) setConsumerKey:(NSString*) consumerKey andConsumerSecret:(NSString*) consumerSecret;

/**
 *  A delegate is optional if you use the block syntax to retrieve tweets but can be used
 *  if you prefer a delegate approach.
 */
+(void) setDelegate:(id<AFTweetFetcherDelegate>) delegate;

/**
 *  Retrieves the most recent tweet for the given account then calls the callback passing
 *  a single tweet object.
 */
+(void) getMostRecentTweetFor:(NSString*) account then:(AFSingleTweetBlock) block;

/**
 *  Retrieves the most recent #{number} tweets for the given account then calls the callback passing
 *  an array of tweet objects.
 */
+(void) get:(NSInteger) numberOfTweets mostRecentTweetsFor:(NSString*) account then:(AFMultipleTweetBlock) block;

/**
 *  Calling getMostRecentTweetFor:(NSString*) account without a then-block will require a delegate
 *  be set in order to pass the resulting tweet somewhere useful.
 */
+(void) getMostRecentTweetFor:(NSString*) account;

/**
 *  Calling get:(NSInteger) number MostRecentTweetFor:(NSString*) account without a then-block will require a delegate
 *  be set in order to pass the resulting tweets somewhere useful.
 */
+(void) get:(NSInteger) numberOfTweets mostRecentTweetsFor:(NSString*) account;


@end

