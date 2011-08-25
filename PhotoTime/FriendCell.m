//
//  FriendCell.m
//  PhotoTime
//
//  Created by Peter Shih on 8/18/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "FriendCell.h"
#import "PSCoreDataStack.h"

@implementation FriendCell

- (void)prepareForReuse {
  [super prepareForReuse];
  self.accessoryType = UITableViewCellAccessoryNone;
}

- (void)fillCellWithObject:(id)object {
  NSDictionary *friend = (NSDictionary *)object;
  
  _psImageView.urlPath = [NSString stringWithFormat:@"http://graph.facebook.com/%@/picture?type=square", [friend objectForKey:@"id"]];
  [_psImageView loadImageAndDownload:YES];
  
  self.textLabel.text = [friend objectForKey:@"name"];
  dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
    NSManagedObjectContext *context = [PSCoreDataStack newManagedObjectContext];
    NSUInteger count = 0;
    
    NSFetchRequest *countFetchRequest = [[NSFetchRequest alloc] init];
    [countFetchRequest setEntity:[NSEntityDescription entityForName:@"Album" inManagedObjectContext:context]];
    [countFetchRequest setPredicate:[NSPredicate predicateWithFormat:@"fromId == %@", [friend objectForKey:@"id"]]];
    count = [context countForFetchRequest:countFetchRequest error:nil];
    
    [countFetchRequest release];
    [context release];
    
    dispatch_async(dispatch_get_main_queue(), ^{
      self.detailTextLabel.text = [NSString stringWithFormat:@"%d", count];
    });
  });
}

@end
