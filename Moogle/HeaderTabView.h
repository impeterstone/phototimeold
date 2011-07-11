//
//  HeaderTabView.h
//  Moogle
//
//  Created by Peter Shih on 3/3/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "HeaderTabViewDelegate.h"

@interface HeaderTabView : UIView {
  NSMutableArray *_buttons;
  
  id <HeaderTabViewDelegate> _delegate;
}

@property (nonatomic, retain) NSMutableArray *buttons;
@property (nonatomic, assign) id <HeaderTabViewDelegate> delegate;

- (id)initWithFrame:(CGRect)frame andButtonTitles:(NSArray *)titles;
- (void)setSelectedForTabAtIndex:(NSInteger)index;
- (void)selectTabAtIndex:(NSInteger)index;

@end
