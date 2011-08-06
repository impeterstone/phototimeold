//
//  Comment.h
//  PhotoTime
//
//  Created by Peter Shih on 5/30/11.
//  Copyright (c) 2011 Seven Minute Labs, Inc.. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class Photo;

@interface Comment : NSManagedObject {
@private
}
@property (nonatomic, retain) NSString * id;
@property (nonatomic, retain) NSString * message;
@property (nonatomic, retain) NSDate * timestamp;
@property (nonatomic, retain) NSString * fromId;
@property (nonatomic, retain) NSString * fromName;
@property (nonatomic, retain) Photo * photo;

@end
