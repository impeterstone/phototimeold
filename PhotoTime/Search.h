//
//  Search.h
//  PhotoTime
//
//  Created by Peter Shih on 7/12/11.
//  Copyright (c) 2011 Seven Minute Labs, Inc.. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>


@interface Search : NSManagedObject {
@private
}
@property (nonatomic, retain) NSString * term;
@property (nonatomic, retain) NSDate * timestamp;
@property (nonatomic, retain) NSNumber * count;

@end
