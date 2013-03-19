//
//  AFTweet.h
//
//  Created by Austin J Fitzpatrick on 3/14/13.
//
//  Used by the AFTweetFetcher class to return a tweet including the postdate, text, and account
//  from which it was posted.
//

#import <Foundation/Foundation.h>

@interface AFTweet : NSObject

@property (nonatomic, strong, readonly) NSString* text; //the text of the tweet
@property (nonatomic, strong, readonly) NSDate* postDate; //the datetime when it was posted
@property (nonatomic, strong, readonly) NSString* account; //account name that posted the tweet
@property (nonatomic, strong, readonly) NSURL* permalink; //permalink to the tweet itself
@property (nonatomic, strong, readonly) NSURL* mediaURL; //URL to the first item of media attached
@property (nonatomic, strong, readonly) NSString *idNumber; //the tweet's ID number is useful for generating links

/**
 *  The entire JSON dictionary is available incase one of the provided helper properties doesn't meet
 *  your needs for the Tweet.
 */
@property (nonatomic, strong, readonly) NSDictionary* fullDictionary; //the entire JSON dictionary is available incase

/**
 *  Takes the JSON as twitter returns it and creates a tweet object
 */
+(AFTweet*) tweetFromJSON:(NSDictionary*) dictionaryJSON;

@end
