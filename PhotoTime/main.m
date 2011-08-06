//
//  main.m
//  PhotoTime
//
//  Created by Peter Shih on 3/23/11.
//  Copyright 2011 Seven Minute Labs. All rights reserved.
//

#import <UIKit/UIKit.h>

int main(int argc, char *argv[])
{
  NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
  int retVal = UIApplicationMain(argc, argv, nil, @"PhotoTimeAppDelegate");
  [pool release];
  return retVal;
}