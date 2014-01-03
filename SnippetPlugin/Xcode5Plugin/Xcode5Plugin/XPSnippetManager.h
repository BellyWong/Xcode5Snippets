//
//  XPSnippetManager.h
//  Xcode5Plugin
//
//  Created by Anupam on 03/12/13.
//  Copyright (c) 2013 ABC. All rights reserved.
//

typedef void(^XPNotification)(NSString *title, NSString *desc);

typedef void(^XPCompletion)(BOOL isCompleted);


#import <Foundation/Foundation.h>

extern NSString *kXPDestinationPath;
extern NSString *kXPStashSnippetsFolderPath;
extern NSString *kXPStashSnippetsFilePath;
extern NSString *kXPBackupPath;

@interface XPSnippetManager : NSObject  {
  NSMutableArray *localCodeSnippets_;
  NSArray *snippetsNameList_;
}

@property (nonatomic, strong) NSArray *snippetsNameList;
@property (nonatomic, weak) IBOutlet NSButton *myButton;

+ (instancetype)sharedSnippetManager;

- (BOOL)doesSnippetExist:(NSString *)snippetFieName;

- (void)fetchSnippets:(NSArray *)snippets
            andNotify:(XPNotification)notification
    completionHandler:(XPCompletion)completed;


@end
