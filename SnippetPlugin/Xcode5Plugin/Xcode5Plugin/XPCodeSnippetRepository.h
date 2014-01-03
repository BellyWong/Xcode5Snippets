//
//  XPCodeSnippetRepository.h
//  Xcode5Plugin
//
//  Created by Anupam on 06/12/13.
//  Copyright (c) 2013 Mutual Mobile. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "XPSnippet.h"

@interface XPCodeSnippetRepository : NSObject

+ (id)sharedRepository;
- (void)_loadUserCodeSnippets;
- (void)removeCodeSnippet:(XPSnippet *)snippet;

@property(readonly) NSSet *codeSnippets;

@end



/*
@interface IDECodeSnippetRepository : NSObject {
  NSMutableDictionary *_systemSnippetsByIdentifier;
  NSMutableDictionary *_snippetsByIdentifier;
  NSMutableSet *_codeSnippetsNeedingSaving;
  DVTDelayedValidator *_savingValidator;
  NSMutableSet *_codeSnippets;
}

+ (id)sharedRepository;
@property(readonly) NSSet *codeSnippets; // @synthesize codeSnippets=_codeSnippets;
- (void)removeCodeSnippet:(id)arg1;
- (void)addCodeSnippet:(id)arg1;
- (void)observeValueForKeyPath:(id)arg1 ofObject:(id)arg2 change:(id)arg3 context:(void *)arg4;
- (void)stopObservingSnippet:(id)arg1;
- (void)startObservingSnippet:(id)arg1;
- (void)_removeUserCodeSnippetFromDisk:(id)arg1;
- (void)_saveUserCodeSnippetsToDisk;
- (void)saveUserCodeSnippetToDisk:(id)arg1;
- (void)setUserSnippetNeedsSaving:(id)arg1;
- (id)_updatedUserSnippet:(id)arg1;
- (void)_loadUserCodeSnippets;
- (id)codeSnippetFromCustomDataSpecifier:(id)arg1 dataStore:(id)arg2;
- (void)_loadSystemCodeSnippets;
- (id)userDataStore;
- (id)init;
@end
*/
