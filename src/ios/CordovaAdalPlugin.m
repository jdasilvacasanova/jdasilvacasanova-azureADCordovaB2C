/*******************************************************************************
 * Copyright (c) Microsoft Open Technologies, Inc.
 * All Rights Reserved
 * See License in the project root for license information.
 ******************************************************************************/

#import "CordovaAdalPlugin.h"
#import "CordovaAdalUtils.h"

#import <ADALiOS/ADAL.h>

@implementation CordovaAdalPlugin

- (void)createAsync:(CDVInvokedUrlCommand *)command
{
    [self.commandDelegate runInBackground:^{
        @try
        {
            NSString *authority = ObjectOrNil([command.arguments objectAtIndex:0]);
            BOOL validateAuthority = [[command.arguments objectAtIndex:1] boolValue];
            
            [CordovaAdalPlugin getOrCreateAuthContext:authority
                                    validateAuthority:validateAuthority];
            
            CDVPluginResult *pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK];
            
            [self.commandDelegate sendPluginResult:pluginResult callbackId:command.callbackId];
        }
        @catch (ADAuthenticationError *error)
        {
            CDVPluginResult *pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR
                                                          messageAsDictionary:[CordovaAdalUtils ADAuthenticationErrorToDictionary:error]];
            [self.commandDelegate sendPluginResult:pluginResult callbackId:command.callbackId];
        }
    }];
}

- (void)acquireTokenAsync:(CDVInvokedUrlCommand *)command
{
    [self.commandDelegate runInBackground:^{
        @try
        {
            NSString *authority = ObjectOrNil([command.arguments objectAtIndex:0]);
            BOOL validateAuthority = [[command.arguments objectAtIndex:1] boolValue];
            //NSString *resourceId = ObjectOrNil([command.arguments objectAtIndex:2]);
            NSString *clientId = ObjectOrNil([command.arguments objectAtIndex:3]);
            NSURL *redirectUri = [NSURL URLWithString:[command.arguments objectAtIndex:4]];
            NSString *userId = ObjectOrNil([command.arguments objectAtIndex:5]);
            NSString *extraQueryParameters = ObjectOrNil([command.arguments objectAtIndex:6]);
            NSString *policy = ObjectOrNil([command.arguments objectAtIndex:7]);
            
            ADAuthenticationContext *authContext = [CordovaAdalPlugin getOrCreateAuthContext:authority
                                                                           validateAuthority:validateAuthority];
            
            NSArray *scopes = @[clientId];
            NSArray *additionalScopes = @[];
            ADUserIdentifier *identifier = [ADUserIdentifier identifierWithId:userId];
            
            // TODO iOS sdk requires user name instead of guid so we should map provided id to a known user name
            userId = [CordovaAdalUtils mapUserIdToUserName:authContext
                                                    userId:userId];
            dispatch_async(dispatch_get_main_queue(), ^{
                [authContext
                 acquireTokenWithScopes:scopes
                 additionalScopes:additionalScopes
                 clientId:clientId
                 redirectUri:redirectUri
                 identifier:identifier
                 promptBehavior:AD_PROMPT_ALWAYS
                 extraQueryParameters:extraQueryParameters
                 policy:policy
                 completionBlock:^(ADAuthenticationResult *result) {
                     
                     NSMutableDictionary *msg = [CordovaAdalUtils ADAuthenticationResultToDictionary: result];
                     CDVCommandStatus status = (AD_SUCCEEDED != result.status) ? CDVCommandStatus_ERROR : CDVCommandStatus_OK;
                     CDVPluginResult *pluginResult = [CDVPluginResult resultWithStatus:status messageAsDictionary: msg];
                     [self.commandDelegate sendPluginResult:pluginResult callbackId:command.callbackId];
                 }];
            });
        }
        @catch (ADAuthenticationError *error)
        {
            CDVPluginResult *pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR
                                                          messageAsDictionary:[CordovaAdalUtils ADAuthenticationErrorToDictionary:error]];
            [self.commandDelegate sendPluginResult:pluginResult callbackId:command.callbackId];
        }
    }];
}

- (void)acquireTokenSilentAsync:(CDVInvokedUrlCommand *)command
{
    [self.commandDelegate runInBackground:^{
        @try
        {
            NSString *authority = ObjectOrNil([command.arguments objectAtIndex:0]);
            BOOL validateAuthority = [[command.arguments objectAtIndex:1] boolValue];
            NSString *resourceId = ObjectOrNil([command.arguments objectAtIndex:2]);
            NSString *clientId = ObjectOrNil([command.arguments objectAtIndex:3]);
            NSString *userId = ObjectOrNil([command.arguments objectAtIndex:4]);
            NSURL *redirectUri = [NSURL URLWithString:ObjectOrNil([command.arguments objectAtIndex:5])];
            NSString *policy = ObjectOrNil([command.arguments objectAtIndex:6]);
            
            ADAuthenticationContext *authContext = [CordovaAdalPlugin getOrCreateAuthContext:authority
                                                                           validateAuthority:validateAuthority];
            
            // TODO iOS sdk requires user name instead of guid so we should map provided id to a known user name
//            userId = [CordovaAdalUtils mapUserIdToUserName:authContext
//                                                    userId:userId];
            
            NSArray *scopes = @[clientId];
            ADUserIdentifier *identifier = [ADUserIdentifier identifierWithId:userId];
            
            [authContext acquireTokenSilentWithScopes:scopes
                                             clientId:clientId
                                          redirectUri:redirectUri
                                           identifier:identifier
                                               policy:policy
                                      completionBlock:^(ADAuthenticationResult *result) {
                                          NSMutableDictionary *msg = [CordovaAdalUtils ADAuthenticationResultToDictionary: result];
                                          CDVCommandStatus status = (AD_SUCCEEDED != result.status) ? CDVCommandStatus_ERROR : CDVCommandStatus_OK;
                                          CDVPluginResult *pluginResult = [CDVPluginResult resultWithStatus:status messageAsDictionary: msg];
                                          [self.commandDelegate sendPluginResult:pluginResult callbackId:command.callbackId];
                                      }];
        }
        @catch (ADAuthenticationError *error)
        {
            CDVPluginResult *pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR
                                                          messageAsDictionary:[CordovaAdalUtils ADAuthenticationErrorToDictionary:error]];
            [self.commandDelegate sendPluginResult:pluginResult callbackId:command.callbackId];
        }
    }];
}

- (void)tokenCacheClear:(CDVInvokedUrlCommand *)command
{
    [self.commandDelegate runInBackground:^{
        @try
        {
            ADAuthenticationError *error;
            
            NSString *authority = ObjectOrNil([command.arguments objectAtIndex:0]);
            BOOL validateAuthority = [[command.arguments objectAtIndex:1] boolValue];
            
            ADAuthenticationContext *authContext = [CordovaAdalPlugin getOrCreateAuthContext:authority
                                                                           validateAuthority:validateAuthority];
            
            
            [authContext.tokenCacheStore removeAll:&error];
            
            //            NSArray *cacheItems = [cacheStore allItems:&error];
            //
            //            for (int i = 0; i < cacheItems.count; i++)
            //            {
            //                [cacheStore removeItem: cacheItems[i] error: &error];
            //            }
            
            if (error != nil)
            {
                @throw(error);
            }
            
            CDVPluginResult *pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK];
            
            [self.commandDelegate sendPluginResult:pluginResult callbackId:command.callbackId];
        }
        @catch (ADAuthenticationError *error)
        {
            CDVPluginResult *pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR
                                                          messageAsDictionary:[CordovaAdalUtils ADAuthenticationErrorToDictionary:error]];
            [self.commandDelegate sendPluginResult:pluginResult callbackId:command.callbackId];
        }
    }];
}

- (void)tokenCacheReadItems:(CDVInvokedUrlCommand *)command
{
    [self.commandDelegate runInBackground:^{
        @try
        {
            ADAuthenticationError *error;
            
            NSString *authority = ObjectOrNil([command.arguments objectAtIndex:0]);
            BOOL validateAuthority = [[command.arguments objectAtIndex:1] boolValue];
            
            ADAuthenticationContext *authContext = [CordovaAdalPlugin getOrCreateAuthContext:authority
                                                                           validateAuthority:validateAuthority];
            
            //get all items from cache
            NSArray *cacheItems = [authContext.tokenCacheStore allItems:&error];
            
            NSMutableArray *items = [NSMutableArray arrayWithCapacity:cacheItems.count];
            
            if (error != nil)
            {
                @throw(error);
            }
            
            for (id obj in cacheItems)
            {
                [items addObject:[CordovaAdalUtils ADTokenCacheStoreItemToDictionary:obj]];
            }
            
            CDVPluginResult *pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK
                                                               messageAsArray:items];
            
            [self.commandDelegate sendPluginResult:pluginResult callbackId:command.callbackId];
        }
        @catch (ADAuthenticationError *error)
        {
            CDVPluginResult *pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR
                                                          messageAsDictionary:[CordovaAdalUtils ADAuthenticationErrorToDictionary:error]];
            [self.commandDelegate sendPluginResult:pluginResult callbackId:command.callbackId];
        }
    }];
}
- (void)tokenCacheDeleteItem:(CDVInvokedUrlCommand *)command
{
    [self.commandDelegate runInBackground:^{
        @try
        {
            ADAuthenticationError *error;
            
            NSString *authority = ObjectOrNil([command.arguments objectAtIndex:0]);
            BOOL validateAuthority = [[command.arguments objectAtIndex:1] boolValue];
            NSString *itemAuthority = ObjectOrNil([command.arguments objectAtIndex:2]);
            NSString *resourceId = ObjectOrNil([command.arguments objectAtIndex:3]);
            NSString *clientId = ObjectOrNil([command.arguments objectAtIndex:4]);
            NSString *userId = ObjectOrNil([command.arguments objectAtIndex:5]);
            
            ADAuthenticationContext *authContext = [CordovaAdalPlugin getOrCreateAuthContext:authority
                                                                           validateAuthority:validateAuthority];
            
            // TODO iOS sdk requires user name instead of guid so we should map provided id to a known user name
            userId = [CordovaAdalUtils mapUserIdToUserName:authContext
                                                    userId:userId];
            
            ADTokenCacheStoreKey* key = [ADTokenCacheStoreKey keyWithAuthority:authority
                                                                      clientId:clientId
                                                                        userId:userId
                                                                      uniqueId:nil
                                                                        idType:OptionalDisplayableId
                                                                        policy:nil
                                                                        scopes:nil
                                                                         error:&error];
            if (error != nil)
            {
                @throw(error);
            }
            
            [authContext.tokenCacheStore removeItemWithKey:key error:&error];
            
            if (error != nil)
            {
                @throw(error);
            }
            
            // don't need iterate through since the above call searches automatically
            
            //get all items from cache
            //            NSArray *cacheItems = [cacheStore allItems:&error];
            //
            //            if (error != nil)
            //            {
            //                @throw(error);
            //            }
            //
            //            for (ADTokenCacheStoreItem*  item in cacheItems)
            //            {
            //                //remove item
            //
            //                if ([itemAuthority isEqualToString:[item authority]]
            //                    && [userId isEqualToString:[[item userInformation] userId]]
            //                    && [clientId isEqualToString:[item clientId]]
            //                    // resource could be nil which is fine
            //                    && ((!resourceId && ![item resource]) || [resourceId isEqualToString:[item resource]])) {
            //
            //                    [cacheStore removeItem:item error: &error];
            //
            //                    if (error != nil)
            //                    {
            //                        @throw(error);
            //                    }
            //                }
            //
            //            }
            
            CDVPluginResult *pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK];
            [self.commandDelegate sendPluginResult:pluginResult callbackId:command.callbackId];
        }
        @catch (ADAuthenticationError *error)
        {
            CDVPluginResult *pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR
                                                          messageAsDictionary:[CordovaAdalUtils ADAuthenticationErrorToDictionary:error]];
            [self.commandDelegate sendPluginResult:pluginResult callbackId:command.callbackId];
        }
    }];
}

static NSMutableDictionary *existingContexts = nil;

+ (ADAuthenticationContext *)getOrCreateAuthContext:(NSString *)authority
                                  validateAuthority:(BOOL)validate
{
    if (!existingContexts)
    {
        existingContexts = [NSMutableDictionary dictionaryWithCapacity:1];
    }
    
    ADAuthenticationContext *authContext = [existingContexts objectForKey:authority];
    
    if (!authContext)
    {
        ADAuthenticationError *error;
        
        authContext = [ADAuthenticationContext authenticationContextWithAuthority:authority
                                                                validateAuthority:validate
                                                                            error:&error];
        if (error != nil)
        {
            @throw(error);
        }
        
        [existingContexts setObject:authContext forKey:authority];
    }
    
    return authContext;
}

static id ObjectOrNil(id object)
{
    return [object isKindOfClass:[NSNull class]] ? nil : object;
}

@end
