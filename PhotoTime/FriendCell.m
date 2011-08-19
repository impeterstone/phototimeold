//
//  FriendCell.m
//  PhotoTime
//
//  Created by Peter Shih on 8/18/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "FriendCell.h"

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
}

@end
