//
//  XPPluginDemo.m
//  Xcode5Plugin
//
//  Created by Anupam on 26/11/13.
//  Copyright (c) 2013 Mutual Mobile. All rights reserved.
//


#import "XPPlugin.h"
#import <objc/runtime.h>
#import <Cocoa/Cocoa.h>
#import "XPSnippetManager.h"
#import "XPCodeSnippetRepository.h"

static XPPlugin *mySharedPlugin = nil;


@interface XPPlugin()
@property (nonatomic, strong) XPCodeSnippetRepository *snippetRepository;
@end

@class MMCodeSnippetRepository;

@implementation XPPlugin
@synthesize snippetRepository = _snippetRepository;
@synthesize responseData = responseData_;
@synthesize request = request_;
@synthesize localCodeSnippets = localCodeSnippets_;
@synthesize xcodeUserCodeSnippets = xcodeUserCodeSnippets_;

# pragma mark - Plugin Life Cycle

+(void)pluginDidLoad:(NSBundle *)plugin {
	NSLog(@"This is our first Xcode plugin!");
	static dispatch_once_t onceToken;
	dispatch_once(&onceToken, ^{
		mySharedPlugin = [[self alloc] init];
	});
}

+(XPPlugin *)sharedPlugin {
	return mySharedPlugin;
}

-(id)init {
	if (self = [super init]) {
    [self addMenuItems];
	}
	return self;
}

-(void)dealloc {
	[[NSNotificationCenter defaultCenter] removeObserver:self];
  [super dealloc];
}

-(void)addMenuItems {
  NSMenu *mmMenu = [[NSMenu alloc] initWithTitle:@"Snippets"];
	NSMenuItem *downloadSnippets = [[NSMenuItem alloc] initWithTitle:@"Download Snippets"
                                                 action:@selector(downloadSnippets:)
                                          keyEquivalent:@""];
	[downloadSnippets setTarget:self];
	[mmMenu addItem:downloadSnippets];
  
	NSMenuItem *mmMenuContainer = [[NSMenuItem alloc] initWithTitle:@"Snippets Menu Conatainer"
                                                       action:NULL
                                                keyEquivalent:@""];
	[mmMenuContainer setSubmenu:mmMenu];
	[[NSApp mainMenu] addItem:mmMenuContainer];
}

-(void)downloadSnippets:(id)sender {
  self.request = [[NSMutableURLRequest alloc] initWithURL:[NSURL URLWithString:kXPStashSnippetsFolderPath]];
  [self.request setValue:[self base64EncodedAuthonticationData]
      forHTTPHeaderField:@"Authorization"];
  NSURLConnection *connection = [[NSURLConnection alloc] initWithRequest:self.request
                                                                delegate:self];
  [connection start];
  
  self.localCodeSnippets = [self snippetsLocallyStored];
  self.snippetRepository = [self snippetRepository];
  self.xcodeUserCodeSnippets = [self userSnippetsFromCodeSnippets:[self.snippetRepository
                                                                   codeSnippets]];
}

#pragma mark NSURLConnection Delegate Methods

- (void)connection:(NSURLConnection *)connection
        didReceiveResponse:(NSURLResponse *)response {
  self.responseData = [[NSMutableData alloc] init];
}

- (void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)data {
  [self.responseData appendData:data];
}

- (NSCachedURLResponse *)connection:(NSURLConnection *)connection
                  willCacheResponse:(NSCachedURLResponse*)cachedResponse {
  return nil;
}

- (void)connectionDidFinishLoading:(NSURLConnection *)connection {
  NSError *error;
  
  NSMutableDictionary *responseDict =
  [NSJSONSerialization JSONObjectWithData:self.responseData
                                  options:NSJSONReadingMutableContainers
                                    error:&error];
  
  NSArray *snippets = [self  responseSnippets:[responseDict objectForKey:@"values"]
                       minusLocalCodeSnippets:self.localCodeSnippets];
  
  [[XPSnippetManager sharedSnippetManager]
   fetchSnippets:snippets
   andNotify:^(NSString *title, NSString *desc) {
     [self postNotification:title
            informativeText:desc
                   userInfo:nil];
   }
   completionHandler:^(BOOL isCompleted){
     if (isCompleted)
       [self loadXcodeWithDownloadedSnippets];
   }
   ];
  ;
}

- (void)connection:(NSURLConnection *)connection
  didFailWithError:(NSError *)error {
}

# pragma mark - Private Methods

- (void)postNotification:(NSString *)title
         informativeText:(NSString *)informativeText
                userInfo:(NSDictionary *)userInfo {  
  NSUserNotification *notification = [[NSUserNotification alloc] init];
  notification.title = title;
  notification.informativeText = informativeText;
  notification.deliveryDate = [NSDate date];
  notification.soundName = NSUserNotificationDefaultSoundName;
  notification.userInfo = userInfo;
  [[NSUserNotificationCenter defaultUserNotificationCenter]
   deliverNotification:notification];
}

- (NSString *)base64EncodedAuthonticationData {
  return @"Basic YW51cGFtLmNob3VkaGFyeTpzZWVydmk1Nw==";
}

- (NSMutableArray *)snippetsLocallyStored {
  NSError *error;
  return (NSMutableArray *)
  [[NSFileManager defaultManager]
   contentsOfDirectoryAtPath:[kXPDestinationPath stringByExpandingTildeInPath]
   error:&error];
}

- (NSArray *)responseSnippets:(NSArray *)responseSnippets
       minusLocalCodeSnippets:(NSArray *)localSnippets {
  NSMutableArray *tempArray = [NSMutableArray arrayWithArray:responseSnippets];
  for (NSString *snippet in responseSnippets) {
    if ([localSnippets containsObject:snippet]) {
      [tempArray removeObject:snippet];
    }
  }
  return [NSArray arrayWithArray:tempArray];
}

- (void)removeBackUpDictionary {
  NSFileManager *fileManager = [NSFileManager defaultManager];
  if ([fileManager fileExistsAtPath:kXPBackupPath]) {
    NSError *error = nil;
    [fileManager removeItemAtPath:kXPBackupPath
                            error:&error];
    if (error != nil) {
      NSString *message = [NSString stringWithFormat:
                           @"Failed to remove snippet backup directory: %@ - %@",
                           kXPBackupPath,
                           error];
      [self sendRefreshError:message];
      return;
    }
  }
}

- (void)createDirectoryAtDestinationPath {
  NSFileManager *fileManager = [NSFileManager defaultManager];
  NSError *error = nil;
  [fileManager createDirectoryAtPath:kXPBackupPath
         withIntermediateDirectories:YES
                          attributes:@{}
                               error:&error];
  if (error != nil) {
    NSString *message = [NSString stringWithFormat:
                         @"Failed to create snippet backup directory: %@ - %@",
                         kXPBackupPath,
                         error];
    [self sendRefreshError:message];
    return;
  }
}

- (NSMutableSet *)userSnippetsFromCodeSnippets:(NSSet *)codeSnippets {
  NSMutableSet *userSnippets = [NSMutableSet set];
  for (XPSnippet *snippet in codeSnippets) {
    if ([self isSnippetCompatible:snippet] == NO){
      return nil;
    }
    if ([snippet isUserSnippet]) {
      [userSnippets addObject:snippet];
    }
  }
  return userSnippets;
}

- (NSMutableArray *)saveUserSnippetsInBackUp:(NSMutableSet *)userSnippets {
  NSMutableArray *userSnippetFilenames = [NSMutableArray array];
  for (id snippet in userSnippets) {
    NSString *identifier = [snippet identifier];
    NSString *snippetFileName = [NSString stringWithFormat:@"mutualMobile.Snippets.Xcode__%@",
                                 [identifier stringByAppendingPathExtension:@"codesnippet"]];
    [userSnippetFilenames addObject:snippetFileName];
    NSString *snippetPath = [[kXPDestinationPath stringByExpandingTildeInPath]
                             stringByAppendingPathComponent:snippetFileName];
    
    if ([[NSFileManager defaultManager] fileExistsAtPath:snippetPath]) {
      NSString *backupSnippetPath =
      [kXPBackupPath stringByAppendingPathComponent:snippetFileName];
      NSLog(@"backuping up snippet: %@ - %@", snippetFileName, backupSnippetPath);
      NSError *error = nil;
      [[NSFileManager defaultManager] copyItemAtPath:snippetPath
                                              toPath:backupSnippetPath
                                               error:&error];
      if (error != nil) {
        NSString *message = [NSString stringWithFormat:
                             @"Failed to backup user snippet file: %@ -> %@ - %@",
                             snippetPath,
                             backupSnippetPath,
                             error];
        [self sendRefreshError:message];
        return nil;
      }
    }
  }
  return userSnippetFilenames;
}

- (void)moveBackToSnippetsFolder:(NSMutableArray *)userSnippetFilenames {
  for (NSString *snippetFileName in userSnippetFilenames) {
    NSString *backupSnippetPath = [kXPBackupPath stringByAppendingPathComponent:snippetFileName];
    NSString *snippetPath = [[kXPDestinationPath stringByExpandingTildeInPath]
                             stringByAppendingPathComponent:snippetFileName];
    
    NSLog(@"copying backup snippet: %@ - %@", snippetFileName, snippetPath);
    NSError *error = nil;
    [[NSFileManager defaultManager] copyItemAtPath:backupSnippetPath
                                            toPath:snippetPath
                                             error:&error];
    if (error != nil &&
        ([error.domain isEqualToString:NSCocoaErrorDomain] == NO ||
         error.code != NSFileReadNoSuchFileError)) {
          
          NSString *message =
          [NSString stringWithFormat:@"Failed to copy snippet file back to user repo location: %@ -> %@ - %@",
           backupSnippetPath, snippetPath, error];
          [self sendRefreshError:message];
          return;
        }
  }
}

- (XPCodeSnippetRepository *)snippetRepository {
  if (xcodeUserCodeSnippets_ == nil ) {
    _snippetRepository = [NSClassFromString(@"IDECodeSnippetRepository") sharedRepository];
  }
  return _snippetRepository;
}

- (void)removeBackedUpSnippetsFromIDERepository {
  for (id snippet in self.xcodeUserCodeSnippets) {
    [self.snippetRepository removeCodeSnippet:snippet];
  }
}

- (void)loadXcodeWithDownloadedSnippets {
  if ([self isSnippetRepositoryCompatible:self.snippetRepository] == NO)
    return;
  @synchronized (self.snippetRepository) {
    [self removeBackUpDictionary];
    [self createDirectoryAtDestinationPath];
    NSMutableArray *backedUpSnippets = [self saveUserSnippetsInBackUp:self.xcodeUserCodeSnippets];
    [self removeBackedUpSnippetsFromIDERepository];
    [self moveBackToSnippetsFolder:backedUpSnippets];
    [self.snippetRepository _loadUserCodeSnippets];
  }
}

- (BOOL)isSnippetRepositoryCompatible:(XPCodeSnippetRepository *)snippetRepository {
  if ([snippetRepository isKindOfClass:NSClassFromString(@"IDECodeSnippetRepository")] == NO) {
    NSString *message =
    [NSString stringWithFormat:@"XCode snippet repository is not of type IDECodeSnippetRepository: %@",
     NSStringFromClass([snippetRepository class])];
    [self sendRefreshError:message];
    return NO;
  }
  
  if ([snippetRepository respondsToSelector:@selector(codeSnippets)] == NO) {
    [self sendRefreshError:@"XCode IDECodeSnippetRepository no longer responds to codeSnippets."];
    return NO;
  }
  
  if ([snippetRepository respondsToSelector:@selector(removeCodeSnippet:)] == NO) {
    [self sendRefreshError:@"XCode IDECodeSnippetRepository no longer responds to removeCodeSnippet:."];
    return NO;
  }
  
  return YES;
}

- (void)sendRefreshError:(NSString *)message {
  NSLog(@"Refresh Error :%@", message);
  [[NSDistributedNotificationCenter defaultCenter]
   postNotificationName:@"CHRefreshSnippetLibraryErrorNotification"
   object:nil
   userInfo:@{@"message" : message,}];
}

- (BOOL)isSnippetCompatible:(XPSnippet *)snippet {
  if ([snippet isKindOfClass:NSClassFromString(@"IDECodeSnippet")] == NO) {
    NSString *message =
    [NSString stringWithFormat:@"XCode snippet is not of type IDECodeSnippet: %@",
     NSStringFromClass([snippet class])];
    [self sendRefreshError:message];
    return NO;
  }
  
  if ([snippet respondsToSelector:@selector(isUserSnippet)] == NO) {
    [self sendRefreshError: @"XCode IDECodeSnippet no longer responds to isUserSnippet."];
    return NO;
  }
  
  if ([snippet respondsToSelector:@selector(identifier)] == NO) {
    [self sendRefreshError:@"XCode IDECodeSnippet no longer responds to identifier."];
    return NO;
  }
  
  return YES;
}


@end

