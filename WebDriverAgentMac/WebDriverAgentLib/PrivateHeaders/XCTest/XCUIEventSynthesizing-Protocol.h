//
//     Generated by class-dump 3.5 (64 bit).
//
//     class-dump is Copyright (C) 1997-1998, 2000-2001, 2004-2013 by Steve Nygard.
//

@class XCSynthesizedEventRecord;

@protocol XCUIEventSynthesizing <NSObject>
@property double implicitEventConfirmationIntervalForCurrentContext;
- (_Bool)requestPressureEventsSupportedOrError:(id *)arg1;
- (id)synthesizeEvent:(XCSynthesizedEventRecord *)arg1 completion:(void (^)(_Bool, NSError *))arg2; // <XCUIEventSynthesisRequest>
@end

