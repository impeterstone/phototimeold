//
//  Tag.h
//  PhotoTime
//
//  Created by Peter Shih on 6/3/11.
//  Copyright (c) 2011 Seven Minute Labs, Inc.. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class Photo;

@interface Tag : NSManagedObject {
@private
}
@property (nonatomic, retain) NSString * fromId;
@property (nonatomic, retain) NSString * fromName;
@property (nonatomic, retain) NSDecimalNumber * x;
@property (nonatomic, retain) NSDecimalNumber * y;
@property (nonatomic, retain) NSDate * timestamp;
@property (nonatomic, retain) Photo * photo;

@end
