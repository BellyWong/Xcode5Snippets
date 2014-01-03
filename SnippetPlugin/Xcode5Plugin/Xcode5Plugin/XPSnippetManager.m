//
//  XPSnippetManager.m
//  Xcode5Plugin
//
//  Created by Anupam on 03/12/13.
//  Copyright (c) 2013 Mutual Mobile. All rights reserved.
//

// ABC

#import "XPSnippetManager.h"
#import "XPSnippet.h"

NSString *kXPDestinationPath = @"~/Library/Developer/Xcode/UserData/CodeSnippets";
NSString *kXPStashSnippetsFolderPath = @"https://stash.r.mutualmobile.com/rest/api/1.0/projects/IOSB/repos/mmsharedsnippets/files?at";
NSString *kXPStashSnippetsFilePath = @"https://stash.r.mutualmobile.com/projects/IOSB/repos/mmsharedsnippets/browse";
NSString *kXPBackupPath = @"/tmp/xcode-snippets-backup";

@interface XPSnippetManager()
@property (nonatomic, assign) NSMutableArray *localCodeSnippets;
@property (nonatomic, strong) NSOperationQueue *operationQueue;
@property (nonatomic, strong) NSMutableArray *operations;
@end

@implementation XPSnippetManager

@synthesize localCodeSnippets = localCodeSnippets_ ;
@synthesize snippetsNameList = snippetsNameList_;

+ (instancetype)sharedSnippetManager {
  static XPSnippetManager *_sharedSnippetManager = nil;
  static dispatch_once_t onceToken;
  dispatch_once(&onceToken, ^{
    _sharedSnippetManager = [[XPSnippetManager alloc] init];
  });
  return _sharedSnippetManager;
}

- (BOOL)doesSnippetExist:(NSString *)snippetFieName {
  return [self.snippetsNameList containsObject:snippetFieName];
}

- (void)fetchSnippets:(NSArray *)snippets
            andNotify:(XPNotification)notification
    completionHandler:(XPCompletion)completed {
  self.snippetsNameList = snippets;
  self.operationQueue = [[NSOperationQueue alloc] init];
  self.operations = [NSMutableArray arrayWithCapacity:[self.snippetsNameList count]];  
  for (NSString *snippet in self.snippetsNameList) {
    if ([self doesSnippetExist:snippet]) {
      [self fetchSnippetFromStash:snippet
                        andNotify:notification
                           isLast:(XPCompletion)completed];
    }
  }
}

- (void)fetchSnippetFromStash:(NSString *)snippet
                    andNotify:(XPNotification)notification
                       isLast:(XPCompletion)completed {
  NSString *filePath = [NSString stringWithFormat:@"%@/%@?raw",kXPStashSnippetsFilePath,snippet];
  NSString *destinationPath =
  [NSString stringWithFormat:@"%@/%@",[kXPDestinationPath stringByExpandingTildeInPath], snippet];
  NSURLRequest *request = [NSURLRequest requestWithURL:[NSURL URLWithString:filePath]];
  [NSURLConnection sendAsynchronousRequest:request
                                     queue:[NSOperationQueue mainQueue]
                         completionHandler:^(NSURLResponse *response, NSData *data, NSError *error) {
                           [data writeToFile:destinationPath
                                  atomically:YES];
                           notification([self snippetSummeryForFile:snippet],
                                        [self snippetSummeryForFile:snippet]);
                           [self.operations removeObject:request];
                           completed([self.operations count] == 0);
                         }];
  [self.operations addObject:request];
}

# pragma mark - Private Methods

- (NSString *)snippetSummeryForFile:(NSString *)snippet {
  NSDictionary *dict = [NSDictionary dictionaryWithContentsOfFile:
                        [NSString stringWithFormat:@"%@/%@",
                         [kXPDestinationPath stringByExpandingTildeInPath],snippet]];
  NSString *summery = [dict objectForKey:@"IDECodeSnippetSummary"];
  return summery? summery : [dict objectForKey:@"IDECodeSnippetContents"];
}

- (NSString *)snippetTitleForFile:(NSString *)snippet {
  NSDictionary *dict = [NSDictionary dictionaryWithContentsOfFile:
                        [NSString stringWithFormat:@"%@/%@",
                         [kXPDestinationPath stringByExpandingTildeInPath],snippet]];
  return [dict objectForKey:@"IDECodeSnippetTitle"];
}

@end

// tail -f /var/log/system.log
