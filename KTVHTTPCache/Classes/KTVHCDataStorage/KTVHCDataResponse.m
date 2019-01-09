//
//  KTVHCDataResponse.m
//  KTVHTTPCache
//
//  Created by Single on 2017/8/24.
//  Copyright © 2017年 Single. All rights reserved.
//

#import "KTVHCDataResponse.h"
#import "KTVHCLog.h"

@implementation KTVHCDataResponse

- (instancetype)initWithURL:(NSURL *)URL headers:(NSDictionary *)headers
{
    if (self = [super init])
    {
        KTVHCLogAlloc(self);
        _URL = URL;
        _headers = headers;
        NSMutableDictionary * headersWithoutRangeAndLength = [headers mutableCopy];
        [headersWithoutRangeAndLength removeObjectsForKeys:[self withoutHeaderKeys]];
        headersWithoutRangeAndLength = [self replaceContentEncodings:headersWithoutRangeAndLength];
        _headersWithoutRangeAndLength = headersWithoutRangeAndLength;
        _contentType = [self headerValueWithKey:@"Content-Type"];
        _currentLength = [self headerValueWithKey:@"Content-Length"].longLongValue;
        _range = KTVHCRangeWithResponseHeaderValue([self headerValueWithKey:@"Content-Range"], &_totalLength);
        KTVHCLogDataResponse(@"%p Create data response\nURL : %@\nHeaders : %@\nheadersWithoutRangeAndLength : %@\ncontentType : %@\ntotalLength : %lld\ncurrentLength : %lld", self, self.URL, self.headers, self.headersWithoutRangeAndLength, self.contentType, self.totalLength, self.currentLength);
    }
    return self;
}

- (void)dealloc
{
    KTVHCLogDealloc(self);
}

- (NSString *)headerValueWithKey:(NSString *)key
{
    NSString * value = [self.headers objectForKey:key];
    if (!value)
    {
        value = [self.headers objectForKey:[key lowercaseString]];
    }
    return value;
}

- (NSArray <NSString *> *)withoutHeaderKeys
{
    static NSArray * obj = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        obj = @[@"Content-Length",
                @"content-length",
                @"Content-Range",
                @"content-range"];
    });
    return obj;
}

- (NSArray <NSString *> *)withoutContentEncoding
{
    static NSArray * ces = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        ces = @[@"Content-Encoding",
                @"Content-encoding",
                @"content-Encoding",
                @"content-encoding"];
    });
    return ces;
}

- (NSMutableDictionary *)replaceContentEncodings:(NSMutableDictionary *)headers
{
    // Content-Encoding should replace with 'identity'
    // because NSURLResponse data is decompressed.
    [headers removeObjectsForKeys:[self withoutContentEncoding]];
    headers[@"Content-Encoding"] = @"identity";
    return headers;
}

- (KTVHCDataResponse *)responseWithRange:(KTVHCRange)range
{
    if (!KTVHCEqualRanges(self.range, range))
    {
        NSDictionary * headers = KTVHCRangeFillToResponseHeaders(range, self.headers, self.totalLength);
        KTVHCDataResponse * obj = [[KTVHCDataResponse alloc] initWithURL:self.URL headers:headers];
        return obj;
    }
    return self;
}

@end
