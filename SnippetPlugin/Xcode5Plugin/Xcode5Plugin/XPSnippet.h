//
//  XPSnippet.h
//  Xcode5Plugin
//
//  Created by Anupam on 04/12/13.
//  Copyright (c) 2013 Mutual Mobile. All rights reserved.
//

typedef NS_ENUM(NSUInteger,XPSnippetStatus){
  XPSnippetStatusUnavailabe,
  XPSnippetStatusDownloading,
  XPSnippetStatusDownloaded
};

#import <Foundation/Foundation.h>

@interface XPSnippet : NSObject {
  XPSnippetStatus downloadStatus_;
  NSString *snippetId_;
}

@property (nonatomic, assign) XPSnippetStatus downloadStatus;
@property (nonatomic, copy) NSString *snippetId;
@property(readonly) NSString *identifier;
@property(getter=isUserSnippet) BOOL userSnippet;

@end
