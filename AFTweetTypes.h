//
//  AFTweetTypes.h
//
//  Created by Austin J Fitzpatrick on 3/15/13.
//
//
@class AFTweet;

typedef void (^AFSingleTweetBlock)(AFTweet* tweet);
typedef void (^AFMultipleTweetBlock)(NSArray* tweets);

typedef enum {
    kAFTweetNoError = 0,
    kAFTweetErrorCouldNotAuthenticate = 32,
    kAFTweetErrorDoesNotExist = 34,
    kAFTweetErrorRateLimitExceed = 88,
    kAFTweetErrorInvalidToken = 89,
    kAFTweetErrorOverCapacity = 130,
    kAFTweetErrorInternalError = 131,
    kAFTweetErrorCouldNotAuthenticateTimestamp = 135,
    kAFTweetErrorBadAuthenticationData = 215
} AFTweetErrorCode;
