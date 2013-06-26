//
//  AFTweetFetcherDelegate.h
//
//  Created by Austin J Fitzpatrick on 3/14/13.
//
//

#import <Foundation/Foundation.h>
#import "AFTweetTypes.h"
@class AFTweet;

@protocol AFTweetFetcherDelegate <NSObject>

-(void) tweetRetrieved:(AFTweet*) tweet;
-(void) multipleTweetsRetrieved:(NSArray*) tweets;

@optional

-(void) twitterRespondedWithErrorCode:(AFTweetErrorCode) errorCode;

@end
