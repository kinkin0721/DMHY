//
//  PreferenceController.m
//  DMHY
//
//  Created by 小笠原やきん on 9/16/15.
//  Copyright © 2015 yaqinking. All rights reserved.
//

#import "PreferenceController.h"
#import "ViewPreferenceController.h"
#import "SitePreferenceController.h"
#import "DMHYAPI.h"
#include <Carbon/Carbon.h>

NSString * const FliterKeywordKey = @"FliterKeyword";
NSString * const DontDownloadCollectionKey = @"DontDownloadCollection";
NSString * const DMHYDontDownloadCollectionKeyDidChangedNotification = @"DMHYDontDownloadCollectionKeyDidChangedNotification";

@interface PreferenceController ()
@property (weak) IBOutlet NSMatrix *downloadLinkTypeMatrix;
@property (weak) IBOutlet NSTextField *savePathLabel;
@property (weak) IBOutlet NSTextField *fileWatchPathLabel;

@property (weak) IBOutlet NSTextField *fetchIntervalTextField;

@property (weak) IBOutlet NSPopUpButton *fetchIntervalPopUpButton;

@property (weak) IBOutlet NSTextField *fliterKeywordTextField;

@property (weak) IBOutlet NSButton *dontDownloadCollectionButton;

@end

@implementation PreferenceController

- (instancetype)init {
    return [super initWithNibName:@"Preference" bundle:nil];
}

- (NSString *)identifier
{
    return @"GeneralPreferences";
}

- (NSImage *)toolbarItemImage
{
    return [NSImage imageNamed:NSImageNamePreferencesGeneral];
}

- (NSString *)toolbarItemLabel
{
    return @"常用";
}



- (void)viewDidLoad {
    [super viewDidLoad];
    [self configurePreference];
}

- (void)configurePreference {
    NSInteger idx = [PreferenceController preferenceDownloadLinkType];
    [self.downloadLinkTypeMatrix selectCellAtRow:idx column:0];
    NSURL *url = [PreferenceController preferenceSavePath];
    if (url) {
        self.savePathLabel.stringValue = [url path];
    } else {
        self.savePathLabel.stringValue = @"请设置文件保存路径";
    }
    //Todo bug
//    self.fileWatchPathLabel.stringValue = [[PreferenceController fileWatchPath] path];
    NSURL *fileWatchPath = [PreferenceController fileWatchPath];
    if (fileWatchPath) {
        self.fileWatchPathLabel.stringValue = fileWatchPath.path;
    } else {
        self.fileWatchPathLabel.stringValue = @"请设置文件查看路径 <_<";
    }
    NSInteger seconds = [PreferenceController preferenceFetchInterval];
    NSInteger minutes = seconds / 60;
    
    [self.fetchIntervalPopUpButton selectItemWithTitle:[NSString stringWithFormat:@"%li",(long)minutes]];
    
    NSInteger dontDownloadCollection = [PreferenceController preferenceDontDownloadCollection];
    self.dontDownloadCollectionButton.state = dontDownloadCollection;
    
    NSString *fliter = [[NSUserDefaults standardUserDefaults] stringForKey:FliterKeywordKey];
    self.fliterKeywordTextField.stringValue = fliter;
}

- (void)controlTextDidEndEditing:(NSNotification *)obj {
    NSString *fliter = ((NSTextField *)obj.object).stringValue;
    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
    [userDefaults setObject:fliter forKey:FliterKeywordKey];
    [userDefaults synchronize];
}

- (IBAction)downloadLinkTypeChanged:(id)sender {
    //这里仅有 0 1 这两中，直接偷懒（毕竟 YES = 1 NO = 0）
    NSInteger linkType = [self.downloadLinkTypeMatrix selectedRow];
    [PreferenceController setPreferenceDownloadLinkType:linkType];
    [DMHYNotification postNotificationName:DMHYDownloadLinkTypeNotification];
}

- (IBAction)changeSavePath:(id)sender {
    NSOpenPanel *openPanel = [NSOpenPanel openPanel];
    openPanel.canChooseFiles       = NO;
    openPanel.canChooseDirectories = YES;
    openPanel.prompt               = @"OK";
    if ([openPanel runModal] == NSModalResponseOK) {
        [PreferenceController setPreferenceSavePath:[openPanel URL]];
        self.savePathLabel.stringValue = [[openPanel URL] path];
    }
    [DMHYNotification postNotificationName:DMHYSavePathChangedNotification];
}

- (IBAction)changeFileWatchPath:(id)sender {
    NSOpenPanel *openPanel = [NSOpenPanel openPanel];
    openPanel.canChooseFiles       = NO;
    openPanel.canChooseDirectories = YES;
    openPanel.prompt               = @"OK";
    if ([openPanel runModal] == NSModalResponseOK) {
        NSURL *url = [openPanel URL];
        [PreferenceController setFileWatchPath:url];
        self.fileWatchPathLabel.stringValue = [[openPanel URL] path];
    }
    [DMHYNotification postNotificationName:DMHYFileWatchPathChangedNotification];
}

- (IBAction)changeFetchInterval:(id)sender {
    NSInteger minitues = [((NSPopUpButton *)sender).titleOfSelectedItem integerValue];
    NSInteger seconds = minitues * 60;
    [PreferenceController setPreferenceFetchInterval:seconds];
    [DMHYNotification postNotificationName:DMHYFetchIntervalChangedNotification];
}

- (IBAction)dontDownloadCollection:(id)sender {
    NSInteger state = ((NSButton *)sender).state;
    [PreferenceController setPreferenceDontDownloadCollection:state];
    [DMHYNotification postNotificationName:DMHYDontDownloadCollectionKeyDidChangedNotification];
}

+ (NSURL *)userDownloadPath {
    NSURL *downloadDirectoryURL = [[NSFileManager defaultManager] URLForDirectory:NSDownloadsDirectory
                                                                         inDomain:NSUserDomainMask
                                                                appropriateForURL:nil
                                                                           create:NO
                                                                            error:nil];
    return downloadDirectoryURL;
}

+ (void)setPreferenceDownloadLinkType:(BOOL)type {
    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
    [userDefaults setBool:type forKey:kDownloadLinkType];
    [userDefaults synchronize];
}

+ (BOOL)preferenceDownloadLinkType {
    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
    return [userDefaults boolForKey:kDownloadLinkType];
}

+ (void)setPreferenceDontDownloadCollection:(BOOL)value {
    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
    [userDefaults setBool:value forKey:DontDownloadCollectionKey];
    [userDefaults synchronize];
}

+ (BOOL)preferenceDontDownloadCollection {
    return [[NSUserDefaults standardUserDefaults] boolForKey:DontDownloadCollectionKey];
}

+ (void)setPreferenceSavePath:(NSURL *)path {
    NSUserDefaults *userDefautls = [NSUserDefaults standardUserDefaults];
    [userDefautls setURL:path forKey:kSavePath];
    [userDefautls synchronize];
}

+ (NSURL *)preferenceSavePath {
    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
    return [userDefaults URLForKey:kSavePath];
}

+ (void)setFileWatchPath:(NSURL *)url {
    NSData *data = [url bookmarkDataWithOptions:NSURLBookmarkCreationWithSecurityScope includingResourceValuesForKeys:nil relativeToURL:nil error:nil];
    NSUserDefaults *userDefautls = [NSUserDefaults standardUserDefaults];
    [userDefautls setObject:data forKey:kFileWatchPath];
    [userDefautls synchronize];
    [DMHYNotification postNotificationName:DMHYFileWatchPathChangedNotification];
}

+ (NSURL *)fileWatchPath {
    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
    NSData *filePathData = [userDefaults objectForKey:kFileWatchPath];
    BOOL bookmarkISStable = NO;
    NSURL *fileWatchPath = [NSURL URLByResolvingBookmarkData:filePathData options:NSURLBookmarkResolutionWithSecurityScope relativeToURL:nil bookmarkDataIsStale:&bookmarkISStable error:nil];
    return fileWatchPath;
}

+ (void)setPreferenceFetchInterval:(NSInteger)seconds {
    NSUserDefaults *userDefautls = [NSUserDefaults standardUserDefaults];
    [userDefautls setInteger:seconds forKey:kFetchInterval];
    [userDefautls synchronize];
}

+ (NSInteger)preferenceFetchInterval {
    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
    return [userDefaults integerForKey:kFetchInterval];
}

+ (void)setPreferenceTheme:(NSInteger)themeCode {
    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
    switch (themeCode) {
        case DMHYThemeLight:
            [userDefaults setInteger:0 forKey:DMHYThemeKey];
            break;
        case DMHYThemeDark:
            [userDefaults setInteger:1 forKey:DMHYThemeKey];
            break;
        default:
            [userDefaults setInteger:0 forKey:DMHYThemeKey];
            break;
    }
    [userDefaults synchronize];
}

+ (NSInteger)preferenceTheme {
    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
    return [userDefaults integerForKey:DMHYThemeKey];
}

@end
