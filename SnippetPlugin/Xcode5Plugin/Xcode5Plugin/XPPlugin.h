//
//  XPPluginDemo.h
//  Xcode5Plugin
//
//  Created by Anupam on 26/11/13.
//  Copyright (c) 2013 Mutual Mobile. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface XPPlugin : NSObject {
  NSMutableData *responseData_;
  NSMutableURLRequest *request_;
  NSMutableArray *localCodeSnippets_;
}
@property (nonatomic, strong) NSMutableData *responseData;
@property (nonatomic, strong) NSMutableURLRequest *request;
@property (nonatomic, strong) NSMutableArray *localCodeSnippets;
@property (nonatomic, strong) NSMutableSet *xcodeUserCodeSnippets;

@end
