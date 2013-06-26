//
//  AFTweet.m
//
//  Created by Austin J Fitzpatrick on 3/14/13.
//
//

#import "AFTweet.h"

@interface AFTweet ()
@property (nonatomic, strong) NSString* text;
@property (nonatomic, strong) NSDate* postDate;
@property (nonatomic, strong) NSString* account;
@property (nonatomic, strong) NSURL* permalink;
@property (nonatomic, strong) NSURL* mediaURL;
@property (nonatomic, strong) NSDictionary* fullDictionary;
@property (nonatomic, strong) NSString *idNumber;
@end

static NSDateFormatter *_dateFormatter = nil; //cache the date formatter at a static level so we dont have to create it everytime

@implementation AFTweet

+(AFTweet*) tweetFromJSON:(NSDictionary *)dictionaryJSON{
    AFTweet *tweet = [[AFTweet alloc] init];
    
    tweet.text = [dictionaryJSON objectForKey:@"text"];
    NSString *postDateString = [dictionaryJSON objectForKey:@"created_at"];
    if (_dateFormatter == nil) _dateFormatter = [[NSDateFormatter alloc] init];
    [_dateFormatter setDateFormat:@"eee MMM dd HH:mm:ss ZZZZ yyyy"];
    tweet.postDate = [_dateFormatter dateFromString:postDateString];
    tweet.fullDictionary = dictionaryJSON;
    tweet.mediaURL = [NSURL URLWithString:(NSString*) [[[dictionaryJSON objectForKey:@"entities"] objectForKey:@"media"][0] objectForKey:@"expanded_url"]];
    tweet.account = [[dictionaryJSON objectForKey:@"user"] objectForKey:@"screen_name"];
    tweet.idNumber = [dictionaryJSON objectForKey:@"id"];

    tweet.permalink = [NSURL URLWithString:[NSString stringWithFormat:@"http://twitter.com/%@/status/%@", tweet.account, tweet.idNumber]];
    return tweet;
}

-(NSString*) description{
    return [NSString stringWithFormat:@"[Tweet: %@ - %@ (%@)", self.text, self.account, self.mediaURL];
}

@end
