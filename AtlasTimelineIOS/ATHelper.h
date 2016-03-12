//
//  ATHelper.h
//  AtlasTimelineIOS
//
//  Created by Hong on 2/6/13.
//  Copyright (c) 2013 hong. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "ATEventDataStruct.h"
#import "UIView+Toast.h"

@interface ATHelper : NSObject
+ (BOOL)isStringNumber:(NSString*) numberStr;
+ (NSString *)applicationDocumentsDirectory;
+ (NSArray *)listFileAtPath:(NSString *)path;
+ (NSString*)getYearPartSmart:(NSDate*)date;
+ (NSString*) getYearPartHelper:(NSDate*) date;
+ (NSString*) getMonthDateInLetter:(NSDate*)date;
+ (NSString*) getMonthDateInTwoNumber:(NSDate*)date;
+ (NSString*) getMonthSlashDateInNumber:(NSDate *)date;
+ (Boolean)checkUserEmailAndSecurityCode:(UIViewController*)sender;
+ (void) closeCreateUserPopover;
+ (NSString*) getSelectedDbFileName;
+ (void) setSelectedDbFileName:(NSString*)fileName;
+ (UIColor *)darkerColorForColor:(UIColor *)c;
+ (NSDate *)dateByAddingComponentsRegardingEra:(NSDateComponents *)comps toDate:(NSDate *)date options:(NSUInteger)opts;
+ (NSDate *)getYearStartDate:(NSDate*)date;
+ (NSString*) get10YearForTimeLink:(NSDate*) date;
+ (NSString*) get100YearForTimeLink:(NSDate*) date;
+ (NSString*) getYearMonthForTimeLink:(NSDate*) date;
+ (NSDate *)getMonthStartDate:(NSDate*)date;

+ (UIColor *) colorWithHexString: (NSString *) stringToConvert;
+ (NSString*) getMarkerNameFromDescText: (NSString*)descTxt;
+ (NSArray*) getPhotoUrlsFromDescText: (NSString*)descTxt;
+ (NSString*) clearMakerFromDescText: (NSString*)desc :(NSString*)markerName;
+ (NSString*) clearMakerAllFromDescText: (NSString*)desc;
+ (NSArray*) getEventListWithUniqueIds: (NSArray*)uniqueIds;
+ (NSString*) httpGetFromServer:(NSString*)serverUrl;
+ (NSString*) httpGetFromServer:(NSString *)serverUrl :(BOOL)alertError;
+ (void)startReplaceDb:(NSString*)selectedAtlasName :(NSArray*)downloadedJsonArray :(UIActivityIndicatorView*)spinner;
+ (BOOL)isBCDate:(NSDate*)date;
+ (NSDictionary*) getScaleStartEndDate:(NSDate*)focusedDate;
+ (BOOL) isAtLeastIOS8;
+ (BOOL) isPOIEvent:(ATEventDataStruct*)event;
+ (BOOL) isPOIEventByDate:(NSDate*)eventDate;
+ (NSArray*) createdPoiListFromString:(NSString*)poiListString;

// file/photos related
+ (void) createPhotoDocumentoryPath;
+ (void) createWebCachePhotoDocumentoryPath;
+ (NSString*) getRootDocumentoryPath;
+ (NSString*)getPreloadedPhotoBundlePath; //previously named getBundlePath()
+ (NSString*)getWebCachePhotoDocummentoryPath;
+ (NSString*)convertWebUrlToFullPhotoPath:(NSString*)webPhotoUrl;
+ (NSString*)getPhotoDocummentoryPath;
+ (NSString*)getNewUnsavedEventPhotoPath;
+ (UIImage*)imageResizeWithImage:(UIImage*)image scaledToSize:(CGSize)newSize;
+ (UIImage*)fetchAndCachePhotoFromWeb:(NSString*)photoUrl thumbPhotoId:(NSString*)thumbPhotoId;
+ (UIImage*)readPhotoFromFile:(NSString*)photoFileName eventId:photoDir;
+ (UIImage*)readPhotoThumbFromFile:(NSString*)eventId;

//tutorial tost
+ (void)startTutorialToasts:(UIView*)parentView style:(CSToastStyle*)style nextToToast:(void (^)(UIView*, CSToastStyle*))callbackBlock;
+ (void)tutorialToastCreateEditEvent:(UIView*)parentView style:(CSToastStyle*)style nextToToast:(void (^)(UIView*, CSToastStyle*))callbackBlock;
+ (void)tutorialToastOtherFeatures:(UIView*)parentView style:(CSToastStyle*)style nextToToast:(void (^)(UIView*, CSToastStyle*))callbackBlock;

//set/get options
+ (BOOL) getOptionDateFieldKeyboardEnable;
+ (void) setOptionDateFieldKeyboardEnable:(BOOL)flag;
+ (BOOL) getOptionDisplayTimeLink;
+ (void) setOptionDisplayTimeLink:(BOOL)flag;
+ (BOOL) getOptionDateMagnifierModeScroll;
+ (void) setOptionDateMagnifierModeScroll:(BOOL)flag;
+ (BOOL) getOptionEditorFullScreen;
+ (void) setOptionEditorFullScreen:(BOOL)flag;
+ (BOOL) getOptionZoomToWeek;
+ (void) setOptionZoomToWeek:(BOOL)flag;

+(void) getStatsForEvent:(NSString*)sourceName tableCell:(UITableViewCell*)cell;


@end
