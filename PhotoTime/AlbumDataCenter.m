
//
//  AlbumDataCenter.m
//  PhotoTime
//
//  Created by Peter Shih on 4/25/11.
//  Copyright 2011 Seven Minute Labs. All rights reserved.
//

#import "AlbumDataCenter.h"
#import "Album.h"
#import "Album+Serialize.h"
#import "PSProgressCenter.h"
#import "PSAlertCenter.h"

static dispatch_queue_t _coreDataSerializationQueue = nil;

@implementation AlbumDataCenter

+ (void)initialize {
  _coreDataSerializationQueue = dispatch_queue_create("com.sevenminutelabs.albumCoreDataSerializationQueue", NULL);
}

- (id)init {
  self = [super init];
  if (self) {
    _parseIndex = 0;
    _totalAlbumsToParse = 0;
    _pendingRequestsToParse = 0;
    _requestsToParse = [[NSMutableArray alloc] initWithCapacity:1];
  }
  return self;
}

#pragma mark -
#pragma mark Prepare Request
- (void)getAlbums {
  //  curl -F "batch=[ {'method': 'GET', 'name' : 'get-friends', 'relative_url': 'me/friends', 'omit_response_on_success' : true}, {'method': 'GET', 'name' : 'get-albums', 'depends_on':'get-friends', 'relative_url': 'albums?ids=me,{result=get-friends:$.data..id}&fields=id,from,name,description,type,created_time,updated_time,cover_photo,count&limit=100', 'omit_response_on_success' : false} ]" https://graph.facebook.com
  
  /*
   curl -F "access_token=D1LgK2fmX11PjBMtys6iI68Kei67r5jPCuB24sf1IrM.eyJpdiI6InFjQ0FPbHVQRDl0b3hzMGZZVWFiSGcifQ.jKiEolLuK1lIgKOnC7Q5_iYWrv-4VEKD-X-zREhyn7r8h2ROyuOJ8yDWn5usdvcbDjkerlvTYVX5A1q3KEKPDSABn0i3nK9pC5KmX9S0clAoV6yv8AGvrBy6NXRleCoJ" -F "batch=[ {'method': 'GET', 'name' : 'get-friends', 'relative_url': 'me/friends?fields=id,name', 'omit_response_on_success' : true}, {'method': 'GET', 'depends_on':'get-friends', 'relative_url': 'albums?ids={result=get-friends:$.data[0:199:1].id}&fields=id,from,name,description,type,created_time,updated_time,cover_photo,count&limit=0', 'omit_response_on_success' : false}, {'method': 'GET', 'depends_on':'get-friends', 'relative_url': 'albums?ids={result=get-friends:$.data[200:399:1].id}&fields=id,from,name,description,type,created_time,updated_time,cover_photo,count&limit=0', 'omit_response_on_success' : false}, {'method': 'GET', 'depends_on':'get-friends', 'relative_url': 'albums?ids={result=get-friends:$.data[400:599:1].id}&fields=id,from,name,description,type,created_time,updated_time,cover_photo,count&limit=0', 'omit_response_on_success' : false}, {'method': 'GET', 'depends_on':'get-friends', 'relative_url': 'albums?ids={result=get-friends:$.data[600:799:1].id}&fields=id,from,name,description,type,created_time,updated_time,cover_photo,count&limit=0', 'omit_response_on_success' : false}, {'method': 'GET', 'depends_on':'get-friends', 'relative_url': 'albums?ids={result=get-friends:$.data[800:999:1].id}&fields=id,from,name,description,type,created_time,updated_time,cover_photo,count&limit=0', 'omit_response_on_success' : false}, {'method': 'GET', 'depends_on':'get-friends', 'relative_url': 'albums?ids={result=get-friends:$.data[1000:1199:1].id}&fields=id,from,name,description,type,created_time,updated_time,cover_photo,count&limit=0', 'omit_response_on_success' : false} ]"
   */
  
  /*
   Multiqueries FQL
   https://api.facebook.com/method/fql.multiquery?format=json&queries=
   
   {"query1":"SELECT uid2 FROM friend WHERE uid1 = me()", "query2":"SELECT aid,owner,cover_pid,name,description,location,size,type,modified_major,created,modified,can_upload FROM album WHERE owner IN (SELECT uid2 FROM #query1)"}
   
   */
  
  
  /*
   {'query1':'SELECT aid,owner,cover_pid,name FROM album WHERE owner = me()','query2':'SELECT src_big FROM photo WHERE pid IN (SELECT cover_pid FROM #query1)'}
   */
  
  // Reset pending requests
  _pendingRequestsToParse = 0;
  
  // reset counters
  _parseIndex = 0;
  _totalAlbumsToParse = 0;
  
  // Show progress indicator if this is the first time
  if (![[NSUserDefaults standardUserDefaults] boolForKey:@"hasDownloadedAlbums"]) {
//    [[PSProgressCenter defaultCenter] setMessage:@"Downloading Albums"];
//    [[PSProgressCenter defaultCenter] showProgress];
  }
  
  // This is retarded... if the user has more than batchSize friends, we'll just fire off multiple requests
  NSURL *albumsUrl = [NSURL URLWithString:[NSString stringWithFormat:@"https://api.facebook.com/method/fql.multiquery"]];
  
  // Apply since if exists
  NSDate *sinceDate = [[NSUserDefaults standardUserDefaults] valueForKey:@"albums.since"];
  NSTimeInterval since = [sinceDate timeIntervalSince1970] - SINCE_SAFETY_NET;
    
  // Get batch size/count
  NSArray *friends = [[[NSUserDefaults standardUserDefaults] dictionaryForKey:@"facebookFriends"] allKeys];
  NSInteger batchSize = 150;
  NSInteger batchCount = ceil((CGFloat)[friends count] / (CGFloat)batchSize);
  NSRange range;
  
  // ME
  NSMutableDictionary *queries = [NSMutableDictionary dictionary];
  NSMutableDictionary *params = [NSMutableDictionary dictionary];
  [params setValue:@"json" forKey:@"format"];
  [queries setValue:[NSString stringWithFormat:@"SELECT aid,object_id,cover_pid,owner,name,description,location,size,type,modified_major,created,modified,can_upload FROM album WHERE owner = me() AND modified_major > %0.0f", since] forKey:@"query1"];
  [queries setValue:[NSString stringWithFormat:@"SELECT aid,src_big FROM photo WHERE pid IN (SELECT cover_pid FROM #query1)"] forKey:@"query2"];

  [params setValue:[queries JSONRepresentation] forKey:@"queries"];
  
//  _pendingRequestsToParse++;
  [self sendRequestWithURL:albumsUrl andMethod:POST andHeaders:nil andParams:params andUserInfo:[NSDictionary dictionaryWithObject:@"me" forKey:@"albumRequestType"]];
  
  // FRIENDS
  for (int i=0; i<batchCount; i++) {
    NSMutableDictionary *friendQueries = [NSMutableDictionary dictionary];
    NSMutableDictionary *friendParams = [NSMutableDictionary dictionary];
    [friendParams setValue:@"json" forKey:@"format"];
    
    NSInteger remainingFriends = [friends count] - (i * batchSize);
    NSInteger length = (batchSize > remainingFriends) ? remainingFriends : batchSize;
    range = NSMakeRange(i * batchSize, length);
    NSArray *batchFriends = [friends subarrayWithRange:range];
    
    [friendQueries setValue:[NSString stringWithFormat:@"SELECT aid,object_id,owner,cover_pid,name,description,location,size,type,modified_major,created,modified,can_upload FROM album WHERE owner IN (%@) AND modified_major > %0.0f", [batchFriends componentsJoinedByString:@","], since] forKey:@"query1"];
    [friendQueries setValue:[NSString stringWithFormat:@"SELECT aid,src_big FROM photo WHERE pid IN (SELECT cover_pid FROM #query1)"] forKey:@"query2"];
    
    [friendParams setValue:[friendQueries JSONRepresentation] forKey:@"queries"];
    
    _pendingRequestsToParse++;
    [self sendRequestWithURL:albumsUrl andMethod:POST andHeaders:nil andParams:friendParams andUserInfo:nil];
  }
}

- (void)getAlbumsForFriendIds:(NSArray *)friendIds {
  NSURL *albumsUrl = [NSURL URLWithString:[NSString stringWithFormat:@"https://api.facebook.com/method/fql.multiquery"]];
  
  NSMutableDictionary *friendQueries = [NSMutableDictionary dictionary];
  NSMutableDictionary *friendParams = [NSMutableDictionary dictionary];
  [friendParams setValue:@"json" forKey:@"format"];
  
  [friendQueries setValue:[NSString stringWithFormat:@"SELECT aid,object_id,owner,cover_pid,name,description,location,size,type,modified_major,created,modified,can_upload FROM album WHERE owner IN (%@)", [friendIds componentsJoinedByString:@","]] forKey:@"query1"];
  [friendQueries setValue:[NSString stringWithFormat:@"SELECT aid,src_big FROM photo WHERE pid IN (SELECT cover_pid FROM #query1)"] forKey:@"query2"];
  
  [friendParams setValue:[friendQueries JSONRepresentation] forKey:@"queries"];
  
  _pendingRequestsToParse++;
  [self sendRequestWithURL:albumsUrl andMethod:POST andHeaders:nil andParams:friendParams andUserInfo:nil];
}

#pragma mark -
#pragma mark Serialization

#pragma mark Core Data Serialization
- (void)serializeAlbumsWithArray:(NSArray *)array inContext:(NSManagedObjectContext *)context {
  NSString *uniqueKey = @"aid";
  NSString *entityName = @"Album";
  
  // Special multiquery treatment
  NSArray *albumArray = nil;
  NSArray *coverArray = nil;
  for (NSDictionary *fqlResult in array) {
    if ([[fqlResult valueForKey:@"name"] isEqualToString:@"query1"]) {
      albumArray = [fqlResult valueForKey:@"fql_result_set"];
    } else if ([[fqlResult valueForKey:@"name"] isEqualToString:@"query2"]) {
      coverArray = [fqlResult valueForKey:@"fql_result_set"];
    } else {
      // error, invalid result
#warning facebook response invalid, alert error
      return;
    }
  }
  
  // Number of albums in this array
//  NSInteger resultCount = [albumArray count];

  // Create a dictionary of all new covers
  NSMutableDictionary *covers = [NSMutableDictionary dictionary];
  for (NSDictionary *cover in coverArray) {
    [covers setObject:[cover objectForKey:@"src_big"] forKey:[cover objectForKey:uniqueKey]];
  }
  
  // Find all existing Entities
  NSArray *newUniqueKeyArray = [albumArray valueForKey:uniqueKey];
  NSFetchRequest *existingFetchRequest = [[[NSFetchRequest alloc] init] autorelease];
  [existingFetchRequest setEntity:[NSEntityDescription entityForName:entityName inManagedObjectContext:context]];
  [existingFetchRequest setPredicate:[NSPredicate predicateWithFormat:@"(%K IN %@)", uniqueKey, newUniqueKeyArray]];
  [existingFetchRequest setPropertiesToFetch:[NSArray arrayWithObject:uniqueKey]];
  
  NSError *error = nil;
  NSArray *foundEntities = [context executeFetchRequest:existingFetchRequest error:&error];
  
  // Create a dictionary of existing entities
  NSMutableDictionary *existingEntities = [NSMutableDictionary dictionary];
  for (id foundEntity in foundEntities) {
    [existingEntities setObject:foundEntity forKey:[foundEntity valueForKey:uniqueKey]];
  }
  
  NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
  int i = 0;
  Album *existingEntity = nil;
  for (NSDictionary *newEntity in albumArray) {
    NSString *key = [newEntity objectForKey:uniqueKey];
    NSString *coverSrcBig = [covers objectForKey:key];
    existingEntity = [existingEntities objectForKey:key];
    if (existingEntity) {
      // update
      [existingEntity updateAlbumWithDictionary:newEntity andCover:coverSrcBig];
    } else {
      // insert
      [Album addAlbumWithDictionary:newEntity andCover:coverSrcBig inContext:context];
    }
    i++;
    _parseIndex++;
    
    if (_parseIndex % 100 == 0) {
      [self updateParseProgress];
    }
    
    // Perform batch core data saves
    if (_parseIndex % 1000 == 0) {
      [PSCoreDataStack saveInContext:context];
      [PSCoreDataStack resetInContext:context];
      
      [pool drain];
      pool = [[NSAutoreleasePool alloc] init];
    }
  }
  
  [self updateParseProgress];
  
  [pool drain];
}

- (void)updateParseProgress {
  NSNumber *progress = [NSNumber numberWithFloat:((CGFloat)_parseIndex / (CGFloat)_totalAlbumsToParse)];
  
  //      [NSDictionary dictionaryWithObject:progress forKey:@"progress"]
  [[NSNotificationCenter defaultCenter] postNotificationName:kUpdateLoginProgress object:nil userInfo:[NSDictionary dictionaryWithObjectsAndKeys:progress, @"progress", [NSNumber numberWithInteger:_parseIndex], @"index", [NSNumber numberWithInteger:_totalAlbumsToParse], @"total", nil]];
  DLog(@"update progress index: %d, total: %d, percent: %@", _parseIndex, _totalAlbumsToParse, progress);
}

- (void)parsePendingResponses {
  // Process the batched results using GCD  
  dispatch_async(_coreDataSerializationQueue, ^{
    NSManagedObjectContext *context = [PSCoreDataStack newManagedObjectContext];
    
    NSMutableArray *pendingResponses = [NSMutableArray arrayWithCapacity:1];
    
    for (ASIHTTPRequest *request in _requestsToParse) {
      id response = [[request responseData] JSONValue];
      
      // Validate response
      if (![self validateFacebookResponse:response]) {
        continue;
      }
      
      NSArray *albumArray = nil;
      for (NSDictionary *fqlResult in response) {
        if ([[fqlResult valueForKey:@"name"] isEqualToString:@"query1"]) {
          albumArray = [fqlResult valueForKey:@"fql_result_set"];
        } else {
          // check for error
        }
      }
      
      _totalAlbumsToParse += [albumArray count];
      
      [pendingResponses addObject:response];
    }
    
    if (_totalAlbumsToParse > 0) {
      dispatch_async(dispatch_get_main_queue(), ^{
        [[PSProgressCenter defaultCenter] setMessage:@"Saving Albums..."];
        [[PSProgressCenter defaultCenter] showProgress];
      });
    }
    
    for (id response in pendingResponses) {
      [self serializeAlbumsWithArray:response inContext:context];
    }
    [_requestsToParse removeAllObjects];
    
    // Save the context
    [PSCoreDataStack saveInContext:context];
    
    // Release context
    [context release];
    
    dispatch_async(dispatch_get_main_queue(), ^{
      if (_parseIndex > 0 && _totalAlbumsToParse > 0) {        
        // All albums downloaded
        [[NSNotificationCenter defaultCenter] postNotificationName:kAlbumDownloadComplete object:nil];
        
        // Inform Delegate if all responses are parsed
        if (_delegate && [_delegate respondsToSelector:@selector(dataCenterDidFinish:withResponse:)]) {
          [_delegate performSelector:@selector(dataCenterDidFinish:withResponse:) withObject:nil withObject:nil];
          [[NSUserDefaults standardUserDefaults] setValue:[NSDate date] forKey:@"albums.since"];
          [[NSUserDefaults standardUserDefaults] setBool:YES forKey:@"hasDownloadedAlbums"];
          [[NSUserDefaults standardUserDefaults] synchronize];
          [[PSProgressCenter defaultCenter] hideProgress];
        }
      }
    });
  });
}

- (void)parseMeWithRequest:(ASIHTTPRequest *)request {
  dispatch_async(_coreDataSerializationQueue, ^{
    NSManagedObjectContext *context = [PSCoreDataStack newManagedObjectContext];
    
    id response = [[request responseData] JSONValue];
    
    // Validate response
    if (![self validateFacebookResponse:response]) {
      return;
    }
    
    NSArray *albumArray = nil;
    for (NSDictionary *fqlResult in response) {
      if ([[fqlResult valueForKey:@"name"] isEqualToString:@"query1"]) {
        albumArray = [fqlResult valueForKey:@"fql_result_set"];
      } else {
        // check for error
      }
    }
    
    _totalAlbumsToParse += [albumArray count];
    
    if (_totalAlbumsToParse > 0) {
      dispatch_async(dispatch_get_main_queue(), ^{
        [[PSProgressCenter defaultCenter] setMessage:@"Saving Albums..."];
        [[PSProgressCenter defaultCenter] showProgress];
      });
    }
    
    [self serializeAlbumsWithArray:response inContext:context];
    
    // Save the context
    [PSCoreDataStack saveInContext:context];
    
    // Release context
    [context release];
    
    dispatch_async(dispatch_get_main_queue(), ^{
      if (_parseIndex > 0 && _totalAlbumsToParse > 0) {
        // Inform Delegate if all responses are parsed
        if (_delegate && [_delegate respondsToSelector:@selector(dataCenterDidFinish:withResponse:)]) {
          [_delegate performSelector:@selector(dataCenterDidFinish:withResponse:) withObject:nil withObject:nil];
        }
        [[PSProgressCenter defaultCenter] hideProgress];
        
        if (![[NSUserDefaults standardUserDefaults] boolForKey:@"hasDownloadedAlbums"]) {
          [[NSOperationQueue mainQueue] addOperationWithBlock:^{
            [[PSAlertCenter defaultCenter] postAlertWithTitle:@"Welcome!" andMessage:@"We are still downloading albums from your friends. You can browse your own photos in the meantime." andDelegate:nil];
          }];
        }
      }
    });
  });
}

- (BOOL)validateFacebookResponse:(id)response {
  // Check FB Error
  if ([response isKindOfClass:[NSDictionary class]] && [response objectForKey:@"error_msg"] && [response objectForKey:@"error_code"]) {
    // We have a FB error, probably a token invalidated
    [[NSUserDefaults standardUserDefaults] setBool:YES forKey:@"logoutRequested"];
    return NO;
  } else {
    return YES;
  }
}

#pragma mark - PSDataCenterDelegate
- (void)dataCenterRequestFinished:(ASIHTTPRequest *)request {
  // Me request
  if ([[request.userInfo objectForKey:@"albumRequestType"] isEqualToString:@"me"]) {
    [self parseMeWithRequest:request];
  } else {
    [_requestsToParse addObject:request];
    _pendingRequestsToParse--;
    
    // If we have reached the last request, let's flush the pendingResponses
    if (_pendingRequestsToParse == 0) {
      [self parsePendingResponses];
    }
  }
}

- (void)dataCenterRequestFailed:(ASIHTTPRequest *)request {
  NSLog(@"CRITICAL ALBUM REQUEST FAILED");
  [[[request copy] autorelease] startAsynchronous];
}

- (void)dealloc {
  RELEASE_SAFELY(_requestsToParse);
  [super dealloc];
}

@end
