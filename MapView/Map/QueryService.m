//
//  QueryService.m
//  MapView
//
//  Created by iclient on 13-6-25.
//
//

#import "QueryService.h"
#import "QueryResult.h"

@implementation QueryService

-(id) init:(NSString*)strUrl
{
    BOOL bAscii = true;
    for(int i=0; i< [strUrl length];i++){
        int a = [strUrl characterAtIndex:i];
        if( a > 0x4e00 && a < 0x9fff)
        {
            bAscii = false;
            break;
        }
    }
    
    if (bAscii == false) {
        strUrl =  [strUrl stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
    }
    
    strQueryUrl = [[NSString alloc] initWithString:strUrl];
    
    NSString *strEnd = [strQueryUrl substringFromIndex:[strQueryUrl length]-1];
    strQueryUrl = [strQueryUrl stringByAppendingString:[strEnd isEqualToString:@"/"]?@"queryResults.json?":@"/queryResults.json?"];
    
    return self;
}

-(void) processAsync:(QueryParameters*)params
{
    if (params == NULL) {
        return;
    }

    
    NSString* strJsonParams = [self getJsonParameters:params];
    
    //strJsonParams =[strJsonParams stringByAddingPercentEscapesUsingEncoding:NSASCIIStringEncoding];
    //NSLog(@"%@",strJsonParams);
    NSString* strHttpUrl = [[NSString alloc] initWithString:strQueryUrl];
    if(params.retainCount == true)
    {
        strHttpUrl = [strHttpUrl stringByAppendingString:@"returnContent=true"];
    }else{
        strHttpUrl = [strHttpUrl stringByAppendingFormat:@"strHttpUrl=%@",params.returnCustomResult?@"true":@"false"];
    }
    
    //第一步，创建url
    NSURL *url = [NSURL URLWithString:strHttpUrl];
    //第二步，创建请求
    NSMutableURLRequest *request = [[NSMutableURLRequest alloc]initWithURL:url cachePolicy:NSURLRequestUseProtocolCachePolicy timeoutInterval:10];
    [request setHTTPMethod:@"POST"];
    NSData *data = [strJsonParams dataUsingEncoding:NSUTF8StringEncoding];
    [request setHTTPBody:data];
    //第三步，连接服务器
    [[NSURLConnection alloc]initWithRequest:request delegate:self];
}

-(QueryParameters*) getQueryParameters:(QueryParameters*)params
{
    QueryParameters* mparams = [[QueryParameters alloc] init];
    mparams.customParams = params.customParams;
    mparams.expectCount = params.expectCount;
    mparams.networkType = params.networkType;
    mparams.queryOption = params.queryOption;
    mparams.queryParams = params.queryParams;
    mparams.startRecord = params.startRecord;
    mparams.holdTime = params.holdTime;
    
    /*
    NSMutableArray *mparams = [[NSMutableArray alloc] init];
    
    NSDictionary *dict = [NSDictionary dictionaryWithObjectsAndKeys:
                          [NSString stringWithFormat:@"%f", [[points objectAtIndex:i] CGPointValue].x], @"x",
                          [NSString stringWithFormat:@"%f", [[points objectAtIndex:i] CGPointValue].y], @"y",
                          nil];
    
    arrayOfPoints addObject:dict];
    */
    
    return mparams;
}

- (void)connection:(NSURLConnection *)connection didReceiveResponse:(NSURLResponse *)response
{
    
    NSHTTPURLResponse *res = (NSHTTPURLResponse *)response;
    
    //NSLog(@"%@",[res allHeaderFields]);
    
    data = [[NSMutableData alloc] initWithCapacity:0];
}

-(void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)smdata
{
    [data appendData:smdata];
}

-(void)connectionDidFinishLoading:(NSURLConnection *)connection
{
    NSString *receiveStr = [[NSString alloc]initWithData:data encoding:NSUTF8StringEncoding];
    //NSLog(@"%@",receiveStr);
    
    QueryResult* qs = [[QueryResult alloc] init];
    [qs fromJson:receiveStr];
    //NSLog(@"dict1:%d",[[[qs.recordsets objectAtIndex:0] features] count]);
    NSMutableDictionary* dict = [[NSMutableDictionary alloc] init];
    [dict setObject:qs forKey:@"QueryResult"];
    
    
    //NSLog(@"dict1:%d",[[[qs.recordsets objectAtIndex:0] features] count]);
    
    [[NSNotificationCenter defaultCenter] postNotificationName:@"processCompleted" object:nil userInfo:dict];
    /*
    if ([JSON objectForKey:@"succeed"]) {
        [[NSNotificationCenter defaultCenter] postNotificationName:@"processFailed" object:nil userInfo:JSON];
    } else {
        [[NSNotificationCenter defaultCenter] postNotificationName:@"processCompleted" object:nil userInfo:JSON];
    }
     */
}

-(void)connection:(NSURLConnection *)connection
 didFailWithError:(NSError *)error
{
    NSLog(@"%@",[error localizedDescription]);
}

@end
