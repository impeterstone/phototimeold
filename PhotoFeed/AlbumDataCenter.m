
//
//  AlbumDataCenter.m
//  PhotoFeed
//
//  Created by Peter Shih on 4/25/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "AlbumDataCenter.h"
#import "Album.h"
#import "Album+Serialize.h"

@implementation AlbumDataCenter

+ (AlbumDataCenter *)defaultCenter {
  static AlbumDataCenter *defaultCenter = nil;
  if (!defaultCenter) {
    defaultCenter = [[self alloc] init];
  }
  return defaultCenter;
}

- (id)init {
  self = [super init];
  if (self) {
    _pendingRequestsToParse = 0;
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
  
  _pendingRequestsToParse++;
  [self sendRequestWithURL:albumsUrl andMethod:POST andHeaders:nil andParams:params andUserInfo:nil];
  
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
- (void)serializeAlbumsWithRequest:(ASIHTTPRequest *)request {
  NSManagedObjectContext *context = [PSCoreDataStack newManagedObjectContext];
  
  // Parse the JSON
  id response = [[request responseData] JSONValue];
  
  // Process the Response for Albums
  if ([response isKindOfClass:[NSArray class]]) {
    [self serializeAlbumsWithArray:response inContext:context];
  }
  
  // Release context
  [context release];
  
  [self performSelectorOnMainThread:@selector(serializeAlbumsFinishedWithRequest:) withObject:request waitUntilDone:NO];
}

- (void)serializeAlbumsFinishedWithRequest:(ASIHTTPRequest *)request {
  _pendingRequestsToParse--;
  
  // Inform Delegate if all responses are parsed
  if (_pendingRequestsToParse == 0 && _delegate && [_delegate respondsToSelector:@selector(dataCenterDidFinish:withResponse:)]) {
    [_delegate performSelector:@selector(dataCenterDidFinish:withResponse:) withObject:request withObject:nil];
    [[NSUserDefaults standardUserDefaults] setValue:[NSDate date] forKey:@"albums.since"];
  }
}

#pragma mark Core Data Serialization
- (void)serializeAlbumsWithArray:(NSArray *)array inContext:(NSManagedObjectContext *)context {
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
  
  if ([albumArray count] != [coverArray count]) {
    NSLog(@"albums: %d, covers: %d", [albumArray count], [coverArray count]);
  }
  
  NSUInteger resultCount = [albumArray count];
  
  NSArray *sortedEntities = [albumArray sortedArrayUsingDescriptors:[NSArray arrayWithObject:[NSSortDescriptor sortDescriptorWithKey:@"aid" ascending:YES]]];
  NSArray *sortedCovers = [coverArray sortedArrayUsingDescriptors:[NSArray arrayWithObject:[NSSortDescriptor sortDescriptorWithKey:@"aid" ascending:YES]]];
  
  NSMutableArray *sortedEntityIds = [NSMutableArray array];
  for (NSDictionary *entityDict in sortedEntities) {
    [sortedEntityIds addObject:[entityDict valueForKey:@"aid"]];
  }
  
  NSFetchRequest *fetchRequest = [[[NSFetchRequest alloc] init] autorelease];
  [fetchRequest setEntity:[NSEntityDescription entityForName:@"Album" inManagedObjectContext:context]];
  [fetchRequest setPredicate:[NSPredicate predicateWithFormat: @"(aid IN %@)", sortedEntityIds]];
  [fetchRequest setSortDescriptors:[NSArray arrayWithObject:[NSSortDescriptor sortDescriptorWithKey:@"aid" ascending:YES]]];
  
  
  NSError *error = nil;
  NSArray *foundEntities = [context executeFetchRequest:fetchRequest error:&error];
  
  NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
  NSUInteger count = 0, LOOP_LIMIT = 1000;
  
  int i = 0;
  int k = 0;
  int c = 0;
  static NSString *cover = nil;
  static NSString *aid = nil;
  for (NSDictionary *entityDict in sortedEntities) {
    aid = [entityDict valueForKey:@"aid"];
    
    // Cover Picture
    if (c == [sortedCovers count]) {
      // We ran out of covers
      cover = nil;
    }
    else if ([[entityDict valueForKey:@"aid"] isEqualToString:[[sortedCovers objectAtIndex:c] valueForKey:@"aid"]]) {
      cover = [[sortedCovers objectAtIndex:c] valueForKey:@"src_big"];
      c++; // cover incrementer
    } else {
      cover = nil;
    }
    
    if ([foundEntities count] > 0 && i < [foundEntities count] && [aid isEqualToString:[[foundEntities objectAtIndex:i] aid]]) {
      //      DLog(@"found duplicated album with id: %@", [[foundEntities objectAtIndex:i] id]);
      [[foundEntities objectAtIndex:i] updateAlbumWithDictionary:entityDict andCover:cover];
      i++;
    } else {
      // Insert
      [Album addAlbumWithDictionary:entityDict andCover:cover inContext:context];
    }
    
    // Batch import performance
    count++;
    if (count == LOOP_LIMIT) {
      [PSCoreDataStack saveInContext:context];
      [PSCoreDataStack resetInContext:context];
      [pool drain];
      
      pool = [[NSAutoreleasePool alloc] init];
      count = 0;
    }
    
    k++;
    if (k % 100 == 0) {
      NSNumber *progress = [NSNumber numberWithFloat:((CGFloat)k / (CGFloat)resultCount)];
      [[NSNotificationCenter defaultCenter] postNotificationName:kUpdateLoginProgress object:nil userInfo:[NSDictionary dictionaryWithObject:progress forKey:@"progress"]];
    }
  }
  
  if (count != 0) {
    [PSCoreDataStack saveInContext:context];
    [PSCoreDataStack resetInContext:context];
  }
  
  [pool drain];
}

#pragma mark -
#pragma mark PSDataCenterDelegate
- (void)dataCenterRequestFinished:(ASIHTTPRequest *)request {
  // Process the batched results in a BG thread
#ifdef USE_JESSA_FIXTURES
  NSString *path = [[NSBundle mainBundle] pathForResource:@"jessa" ofType:@"json"];
  NSData *tmpData = [NSData dataWithContentsOfFile:path];
#else
  NSInvocationOperation *parseOp = [[NSInvocationOperation alloc] initWithTarget:self selector:@selector(serializeAlbumsWithRequest:) object:request];
  [[PSParserStack sharedParser] addOperation:parseOp];
  [parseOp release];
#endif
}

- (void)dataCenterRequestFailed:(ASIHTTPRequest *)request {
  // Inform Delegate
  if (_delegate && [_delegate respondsToSelector:@selector(dataCenterDidFail:withError:)]) {
    [_delegate performSelector:@selector(dataCenterDidFail:withError:) withObject:request withObject:[request error]];
  } 
}

- (void)dealloc {
  [super dealloc];
}

@end
