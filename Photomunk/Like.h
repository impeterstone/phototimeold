//
//  Like.h
//  Photomunk
//
//  Created by Peter Shih on 5/16/11.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>


@interface Like : NSManagedObject {
@private
}
@property (nonatomic, retain) NSString * userPictureUrl;
@property (nonatomic, retain) NSString * id;
@property (nonatomic, retain) NSDate * timestamp;
@property (nonatomic, retain) NSString * userId;
@property (nonatomic, retain) NSString * userName;

@end
