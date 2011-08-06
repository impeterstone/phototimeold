//
//  Album+Serialize.h
//  PhotoTime
//
//  Created by Peter Shih on 4/26/11.
//  Copyright 2011 Seven Minute Labs, Inc.. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "Album.h"

@interface Album (Serialize)

// This is used for sectioning in tableview
- (NSString *)daysAgo;
- (NSString *)lastViewedDaysAgo;

//- (NSString *)fromName;

+ (NSString *)fromNameForFromId:(NSString *)fromId;

+ (Album *)addAlbumWithDictionary:(NSDictionary *)dictionary andCover:(NSString *)cover inContext:(NSManagedObjectContext *)context;

- (Album *)updateAlbumWithDictionary:(NSDictionary *)dictionary andCover:(NSString *)cover;

@end
