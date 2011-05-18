//
//  Album.h
//  PhotoFeed
//
//  Created by Peter Shih on 5/18/11.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>


@interface Album : NSManagedObject {
@private
}
@property (nonatomic, retain) NSString * id;
@property (nonatomic, retain) NSDate * timestamp;
@property (nonatomic, retain) NSNumber * count;
@property (nonatomic, retain) NSString * name;
@property (nonatomic, retain) NSString * coverPhoto;
@property (nonatomic, retain) NSString * fromId;
@property (nonatomic, retain) NSString * fromName;
@property (nonatomic, retain) NSString * caption;
@property (nonatomic, retain) NSString * type;
@property (nonatomic, retain) NSString * location;

@end
