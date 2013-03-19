//
//  AFTweetFetcher.m
//  JunoQuest
//
//  Created by Austin J Fitzpatrick on 3/14/13.
//
//

#import "AFTweetFetcher.h"
#import "AFTweet.h"

@interface AFTweetFetcher ()

/**
 *  Implementation of this base64Encode function from:
 *  http://stackoverflow.com/a/3411653/197431
 */

+(NSString*) _base64Encode:(NSData*) dataToEncode;
/**
 *  Some methods require a delegate be set, if there isn't one
 *  we throw them here so that we don't have to repeat the exception.
 *
 *  All methods require OAuth credentials set, raise an exception if they dont
 *  set them first.
 */
+(void) raiseNoDelegateException;
+(void) raiseNoOAuthException;

/**
 *  Before we can do much we need a bearer token.  This will let us retrieve it then continue with
 *  what we wanted to do.
 */
+(void) _requestBearerTokenThen:(void(^)()) block;

/**
 *  Find the URL for the twitter API to retrieve #{number} of tweets for the account
 *  with the username #{account}
 */
+(NSURL*) _urlForAccount:(NSString*) account andNumber:(NSInteger) number;

/**
 *  Once we have a valid bearer token we can proceed fetching the required tweets
 */
+(void) _getMostRecentTweetWithValidBearerTokenFor:(NSString *)account then:(AFSingleTweetBlock)block;
+(void) _get:(NSInteger) number mostRecentTweetWithValidBearerTokenFor:(NSString *)account then:(AFMultipleTweetBlock)block;

/**
 *  When we get a response we should check it for the Twitter errors.
 *  Returns true when the bearer token has expired.
 */
+(AFTweetErrorCode) _checkResponseForErrors:(NSDictionary*) responseJSON;

@end


@implementation AFTweetFetcher

static id<AFTweetFetcherDelegate> _delegate = nil;

static NSString *_consumerKey;      //provided by twitter
static NSString *_consumerSecret;   //provided by twitter
static NSString *_combinedKey;      //created by combining the above

static NSString *_bearerToken = nil;      //retrieved from twitter

static NSMutableURLRequest *_tokenRequest;  //the request for the token - we'll store it so we can call it whenever the token expires

static NSInteger attempts = 0; //keep track of repeated attempts

static NSInteger const kMaxAttempts = 3;

#pragma mark - mandatory setup functions

+(void) setConsumerKey:(NSString*) consumerKey andConsumerSecret:(NSString*) consumerSecret{
    
    //twitter recommends URL Escaping the strings even though they wont change given the current format of them.
    _consumerKey = [consumerKey stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
    _consumerSecret = [consumerSecret stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
    
    //the combined authentication key is "CONSUMER_KEY:CONSUMER_SECRET" run through base64 encoding.
    //we'll use NSData instead of NSString here so that we can feed it directly to the HTTPRequest later.
    _combinedKey = [AFTweetFetcher _base64Encode:[[NSString stringWithFormat:@"%@:%@", _consumerKey, _consumerSecret] dataUsingEncoding:NSUTF8StringEncoding]];
 
    NSMutableURLRequest *urlRequest = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:@"https://api.twitter.com/oauth2/token"]];
    [urlRequest setHTTPMethod:@"POST"];
    [urlRequest setValue:[NSString stringWithFormat:@"Basic %@", _combinedKey] forHTTPHeaderField:@"Authorization"];
    [urlRequest setValue:[NSString stringWithFormat:@"application/x-www-form-urlencoded;charset=UTF-8"] forHTTPHeaderField:@"Content-Type"];
    [urlRequest setHTTPBody:[@"grant_type=client_credentials" dataUsingEncoding:NSUTF8StringEncoding]];
    
    _tokenRequest = urlRequest;
    
}

#pragma mark - block syntax related functions

+(void) getMostRecentTweetFor:(NSString *)account then:(AFSingleTweetBlock)block{
    
    if (_bearerToken == nil){
        [self _requestBearerTokenThen:^{
            [AFTweetFetcher _getMostRecentTweetWithValidBearerTokenFor:account then:block];
        }];
    }
    else{
        [AFTweetFetcher _getMostRecentTweetWithValidBearerTokenFor:account then:block];
    }
}


+(void) get:(NSInteger) number mostRecentTweetsFor:(NSString *)account then:(AFMultipleTweetBlock)block{
    if (_bearerToken == nil){
        [self _requestBearerTokenThen:^{
            [AFTweetFetcher _get: number mostRecentTweetWithValidBearerTokenFor:account then:block];
        }];
    }
    else{
        [AFTweetFetcher _get: number mostRecentTweetWithValidBearerTokenFor:account then:block];
    }
}

#pragma mark - block syntax additional phases (private)

+(void) _getMostRecentTweetWithValidBearerTokenFor:(NSString *)account then:(AFSingleTweetBlock)block{
    NSMutableURLRequest *urlRequest = [NSMutableURLRequest requestWithURL:[AFTweetFetcher _urlForAccount:account andNumber:1]];
    [urlRequest setValue:[NSString stringWithFormat:@"Bearer %@", _bearerToken] forHTTPHeaderField:@"Authorization"];
    
    [NSURLConnection sendAsynchronousRequest:urlRequest queue:[NSOperationQueue mainQueue] completionHandler:^(NSURLResponse *response, NSData *data, NSError *error){
        if (error != nil) {
            NSLog(@"%@", error);
            return;
        };
        NSArray *array = (NSArray*) [NSJSONSerialization JSONObjectWithData:data options:0 error:nil];
        AFTweetErrorCode errorCode = [AFTweetFetcher _checkResponseForErrors:(NSDictionary*) array];
        if (errorCode != kAFTweetNoError){
            if (errorCode == kAFTweetErrorInvalidToken){
                //the bearer token was out of date...
                //lets try again...
                if (attempts >= kMaxAttempts){
                    if ([_delegate respondsToSelector:@selector(twitterRespondedWithErrorCode:)]){
                        [_delegate twitterRespondedWithErrorCode:errorCode]; //tell the delegate about the error (if they care...)
                    }
                    return;
                }
                attempts++;
                [AFTweetFetcher getMostRecentTweetFor:account then:block];
                
                
            }
            if (errorCode == kAFTweetErrorInternalError){
                //"internal error" - lets try a maximum of 3 times.
                if (attempts >= kMaxAttempts) {
                    if ([_delegate respondsToSelector:@selector(twitterRespondedWithErrorCode:)]){
                        [_delegate twitterRespondedWithErrorCode:errorCode]; //tell the delegate about the error (if they care...)
                    }
                    return;
                }
                attempts++;
                [AFTweetFetcher _getMostRecentTweetWithValidBearerTokenFor:account then:block];
            }
            if ([_delegate respondsToSelector:@selector(twitterRespondedWithErrorCode:)]){
                [_delegate twitterRespondedWithErrorCode:errorCode]; //tell the delegate about the error (if they care...)
            }
            return;
        }
        
        AFTweet *tweet = [AFTweet tweetFromJSON:array[0]];
        //we got through so set attempts back to 0;
        attempts = 0;
        [_delegate tweetRetrieved:tweet];
        block(tweet);
    }];
    
}

+(void) _get:(NSInteger)number mostRecentTweetWithValidBearerTokenFor:(NSString *)account then:(AFMultipleTweetBlock)block{
    NSMutableURLRequest *urlRequest = [NSMutableURLRequest requestWithURL:[AFTweetFetcher _urlForAccount:account andNumber:number]];
    [urlRequest setValue:[NSString stringWithFormat:@"Bearer %@", _bearerToken] forHTTPHeaderField:@"Authorization"];
    
    [NSURLConnection sendAsynchronousRequest:urlRequest queue:[NSOperationQueue mainQueue] completionHandler:^(NSURLResponse *response, NSData *data, NSError *error){
        if (error != nil) {
            NSLog(@"%@", error);
            return;
        };
        NSArray *array = (NSArray*) [NSJSONSerialization JSONObjectWithData:data options:0 error:nil];

        //this "bad cast" is caught on the other side.
        AFTweetErrorCode errorCode = [AFTweetFetcher _checkResponseForErrors:(NSDictionary*) array];
        if (errorCode != kAFTweetNoError){
            if (errorCode == kAFTweetErrorInvalidToken){
                //the bearer token was out of date...
                //lets try again...
                if (attempts >= kMaxAttempts){
                    if ([_delegate respondsToSelector:@selector(twitterRespondedWithErrorCode:)]){
                        [_delegate twitterRespondedWithErrorCode:errorCode]; //tell the delegate about the error (if they care...)
                    }
                    return;
                }
                attempts++;
                [AFTweetFetcher get:number mostRecentTweetsFor:account then:block];
                

            }
            if (errorCode == kAFTweetErrorInternalError){
                //"internal error" - lets try a maximum of 3 times.
                if (attempts >= kMaxAttempts) {
                    if ([_delegate respondsToSelector:@selector(twitterRespondedWithErrorCode:)]){
                        [_delegate twitterRespondedWithErrorCode:errorCode]; //tell the delegate about the error (if they care...)
                    }
                    return;
                }
                attempts++;
                [AFTweetFetcher _get:number mostRecentTweetWithValidBearerTokenFor:account then:block];
            }
            if ([_delegate respondsToSelector:@selector(twitterRespondedWithErrorCode:)]){
                [_delegate twitterRespondedWithErrorCode:errorCode]; //tell the delegate about the error (if they care...)
            }
            return;
        }

        NSMutableArray *tweets = [NSMutableArray array];
        [array enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop){
            [tweets addObject:[AFTweet tweetFromJSON:obj]];
        }];
        
        //reset attempts since we got through
        attempts = 0;
        
        [_delegate multipleTweetsRetrieved:tweets]; //inform the delegate if one is listening...
        block(tweets); //call the block
    }];
}


#pragma mark - delegate syntax related functions

+(void) setDelegate:(id<AFTweetFetcherDelegate>)delegate{
    _delegate = delegate;   //just set the delegate, nothing fancy here.
}

+(void) getMostRecentTweetFor:(NSString *)account{
    if (_delegate == nil) [AFTweetFetcher raiseNoDelegateException]; //this syntax requires a delegate!
    [AFTweetFetcher getMostRecentTweetFor:account then:^(AFTweet* tweet){}]; //call the same function with an empty block
}
+(void) get:(NSInteger) number mostRecentTweetsFor:(NSString *)account{
    if (_delegate == nil) [AFTweetFetcher raiseNoDelegateException]; //this syntax requires a delegate!
    [AFTweetFetcher get:number mostRecentTweetsFor:account then:^(NSArray* tweets){}]; //call the same function with an empty block
}

#pragma mark - private and utility functions

+(NSURL*) _urlForAccount:(NSString*) account andNumber:(NSInteger) number{
    return [NSURL URLWithString:[NSString stringWithFormat:@"https://api.twitter.com/1.1/statuses/user_timeline.json?count=%d&screen_name=%@", number, account]];
}

+(void) _requestBearerTokenThen:(void(^)()) block{
    if (_tokenRequest == nil) [AFTweetFetcher raiseNoOAuthException];
    [NSURLConnection sendAsynchronousRequest:_tokenRequest queue:[NSOperationQueue mainQueue] completionHandler:^(NSURLResponse *response, NSData *data, NSError *error){
        if (error != nil) {
            NSLog(@"%@", error);
            return;
        };
        NSDictionary *responseJSON = [NSJSONSerialization JSONObjectWithData:data options:0 error:nil];
        [AFTweetFetcher _checkResponseForErrors:responseJSON];
        _bearerToken = [responseJSON valueForKey:@"access_token"];
        block();
    }];
}

+(AFTweetErrorCode) _checkResponseForErrors:(NSDictionary*) responseJSON{
    AFTweetErrorCode errorCode = kAFTweetNoError;
    if (![responseJSON isKindOfClass:[NSDictionary class]]){
        //if the response is an array instead of a dictionary twitter didn't give us any errors.
        return errorCode;
    }
    
    NSArray *errors = [responseJSON objectForKey:@"errors"];
    for (NSDictionary* dictionary in errors){
        NSLog(@"Twitter Returned Error: %@", [dictionary objectForKey:@"message"]);
        errorCode = [[dictionary objectForKey:@"code"] intValue];
    }
    
    if (errorCode == kAFTweetErrorInvalidToken){
        _bearerToken = nil;
    }
    
    return errorCode;;
    
}

+(NSString *)_base64Encode:(NSData *)data{
    //Point to start of the data and set buffer sizes
    int inLength = [data length];
    int outLength = ((((inLength * 4)/3)/4)*4) + (((inLength * 4)/3)%4 ? 4 : 0);
    const char *inputBuffer = [data bytes];
    char *outputBuffer = malloc(outLength);
    outputBuffer[outLength] = 0;
    
    //64 digit code
    static char Encode[] = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/";
    
    //start the count
    int cycle = 0;
    int inpos = 0;
    int outpos = 0;
    char temp;
    
    //Pad the last to bytes, the outbuffer must always be a multiple of 4
    outputBuffer[outLength-1] = '=';
    outputBuffer[outLength-2] = '=';
    
    /* http://en.wikipedia.org/wiki/Base64
     Text content   M           a           n
     ASCII          77          97          110
     8 Bit pattern  01001101    01100001    01101110
     
     6 Bit pattern  010011  010110  000101  101110
     Index          19      22      5       46
     Base64-encoded T       W       F       u
     */
    
    
    while (inpos < inLength){
        switch (cycle) {
            case 0:
                outputBuffer[outpos++] = Encode[(inputBuffer[inpos]&0xFC)>>2];
                cycle = 1;
                break;
            case 1:
                temp = (inputBuffer[inpos++]&0x03)<<4;
                outputBuffer[outpos] = Encode[temp];
                cycle = 2;
                break;
            case 2:
                outputBuffer[outpos++] = Encode[temp|(inputBuffer[inpos]&0xF0)>> 4];
                temp = (inputBuffer[inpos++]&0x0F)<<2;
                outputBuffer[outpos] = Encode[temp];
                cycle = 3;
                break;
            case 3:
                outputBuffer[outpos++] = Encode[temp|(inputBuffer[inpos]&0xC0)>>6];
                cycle = 4;
                break;
            case 4:
                outputBuffer[outpos++] = Encode[inputBuffer[inpos++]&0x3f];
                cycle = 0;
                break;
            default:
                cycle = 0;
                break;
        }
    }
    NSString *pictemp = [NSString stringWithUTF8String:outputBuffer];
    free(outputBuffer);
    return pictemp;
}

+(void) raiseNoDelegateException{
    [NSException raise:@"No Delegate Set" format:@"Getting the most recent tweets without using the then: block syntax requires a delegate be set first."];
}

+(void) raiseNoOAuthException{
    [NSException raise:@"You must set your OAuth Credentials first." format:@"Use the +(void) setConsumerKey:(NSString*) consumerKey andConsumerSecret:(NSString*) consumerSecret before attempting to retrieve any tweets"];
}

@end
