//
//     Generated by class-dump 3.5 (64 bit).
//
//     class-dump is Copyright (C) 1997-1998, 2000-2001, 2004-2013 by Steve Nygard.
//

#import "CDStructures.h"

@class NSArray, NSDictionary, NSEnumerator, NSIndexPath, NSSet, NSString, XCAccessibilityElement, XCTLocalizableStringInfo;

@interface XCElementSnapshot : NSObject <NSSecureCoding, NSCopying>
{
    _Bool _isMainWindow;
    _Bool _enabled;
    _Bool _selected;
    _Bool _hasFocus;
    _Bool _hasKeyboardFocus;
    _Bool _isTruncatedValue;
    _Bool _hasPrivilegedAttributeValues;
    unsigned int _faultedInProperties;
    id _application;
    unsigned long long _generation;
    id _dataSource;
    NSString *_title;
    NSString *_label;
    id _value;
    NSString *_placeholderValue;
    unsigned long long _elementType;
    unsigned long long _traits;
    NSString *_identifier;
    long long _verticalSizeClass;
    long long _horizontalSizeClass;
    NSArray *_children;
    NSDictionary *_additionalAttributes;
    NSArray *_userTestingAttributes;
    NSSet *_disclosedChildRowAXElements;
    XCAccessibilityElement *_accessibilityElement;
    XCAccessibilityElement *_parentAccessibilityElement;
    XCElementSnapshot *_parent;
    XCTLocalizableStringInfo *_localizableStringInfo;
    struct CGRect _frame;
}

+ (unsigned long long)elementTypeForAccessibilityElement:(id)arg1 usingAXAttributes_iOS:(id)arg2 useLegacyElementType:(_Bool)arg3;
+ (unsigned long long)elementTypeForAccessibilityElement:(id)arg1 usingAXAttributes_macOS:(id)arg2 macCatalystStatusProvider:(id)arg3 useLegacyElementType:(_Bool)arg4;
+ (id)axAttributesForSnapshotAttributes:(id)arg1 isMacOS:(_Bool)arg2;
+ (id)requiredAXAttributesForElementSnapshotHierarchyOnMacOS:(_Bool)arg1;
+ (id)sanitizedElementSnapshotHierarchyAttributesForAttributes:(id)arg1 isMacOS:(_Bool)arg2;
+ (id)axAttributesForFaultingPropertiesOnMacOS:(_Bool)arg1;
+ (id)axAttributesForElementSnapshotKeyPaths:(id)arg1 isMacOS:(_Bool)arg2;
+ (id)elementWithAccessibilityElement:(id)arg1;
+ (_Bool)supportsSecureCoding;
@property _Bool hasPrivilegedAttributeValues; // @synthesize hasPrivilegedAttributeValues=_hasPrivilegedAttributeValues;
@property(copy) XCTLocalizableStringInfo *localizableStringInfo; // @synthesize localizableStringInfo=_localizableStringInfo;
@property __weak XCElementSnapshot *parent; // @synthesize parent=_parent;
@property(retain) XCAccessibilityElement *parentAccessibilityElement; // @synthesize parentAccessibilityElement=_parentAccessibilityElement;
@property(readonly, copy, nonatomic) XCAccessibilityElement *accessibilityElement; // @synthesize accessibilityElement=_accessibilityElement;
@property unsigned int faultedInProperties; // @synthesize faultedInProperties=_faultedInProperties;
@property _Bool isTruncatedValue; // @synthesize isTruncatedValue=_isTruncatedValue;
@property(copy) NSDictionary *additionalAttributes; // @synthesize additionalAttributes=_additionalAttributes;
@property(readonly) _Bool isMacOS;
@property(readonly) _Bool isTopLevelTouchBarElement;
@property(readonly) _Bool isTouchBarElement;
- (_Bool)_isAncestorOfElement:(id)arg1;
- (_Bool)_isDescendantOfElement:(id)arg1;
@property(readonly) NSSet *uniqueDescendantSubframes;
@property(readonly) NSArray *suggestedHitpoints;
@property(readonly) _Bool isRemote;
@property(readonly) XCElementSnapshot *rootElement;
@property(readonly) double centerY;
@property(readonly) double centerX;
@property(readonly) struct CGPoint center;
@property(readonly) struct CGRect visibleFrame;
@property(readonly) NSArray *disclosedChildRows;
@property(readonly) XCElementSnapshot *outline;
@property(readonly) _Bool isInRootMenu;
@property(readonly) XCElementSnapshot *menuItem;
@property(readonly) XCElementSnapshot *menu;
@property(readonly) XCElementSnapshot *scrollView;
- (id)nearestSharedAncestorOfElement:(id)arg1 matchingType:(long long)arg2;
- (id)_nearestAncestorMatchingAnyOfTypes:(id)arg1;
- (id)nearestAncestorMatchingType:(long long)arg1;
- (id)localizableStringsDataIncludingChildren;
- (_Bool)_frameFuzzyMatchesElement:(id)arg1 tolerance:(double)arg2;
- (_Bool)_frameFuzzyMatchesElement:(id)arg1;
- (_Bool)_fuzzyMatchesElement:(id)arg1;
- (_Bool)_matchesElement:(id)arg1;
- (void)replaceDescendant:(id)arg1 withElement:(id)arg2;
- (id)descendantAtIndexPath:(id)arg1;
@property(readonly, copy) NSIndexPath *indexPath;
- (id)sparseTreeWithDescendants:(id)arg1 error:(id *)arg2;
- (_Bool)matchesTreeWithRoot:(id)arg1;
@property(readonly, copy) XCElementSnapshot *pathFromRoot;
- (void)mergeTreeWithSnapshot:(id)arg1;
- (id)_childMatchingElement:(id)arg1;
- (id)_allDescendants;
@property(readonly, copy) NSEnumerator *descendantEnumerator;
@property(readonly, copy) NSEnumerator *childEnumerator;
- (_Bool)hasDescendantMatchingFilter:(CDUnknownBlockType)arg1;
- (id)descendantsByFilteringWithBlock:(CDUnknownBlockType)arg1;
- (id)elementSnapshotMatchingAccessibilityElement:(id)arg1;
- (void)enumerateDescendantsUsingBlock:(CDUnknownBlockType)arg1;
@property(readonly) unsigned long long depth;
- (id)dictionaryRepresentationWithAttributes:(id)arg1;
@property(readonly, copy) NSString *sparseTreeDescription;
@property(readonly, copy) NSString *compactDescription;
@property(readonly, copy) NSString *pathDescription;
@property(readonly) NSString *recursiveDescriptionIncludingAccessibilityElement;
@property(readonly) NSString *recursiveDescription;
- (id)recursiveDescriptionWithIndent:(id)arg1 includeAccessibilityElement:(_Bool)arg2 includingPointers:(_Bool)arg3;
- (id)debugDescription;
- (id)descriptionIncludingPointers:(_Bool)arg1;
- (id)description;
@property(readonly) _Bool anyDescendantHasPrivilegedAttributeValues;
@property(copy) NSSet *disclosedChildRowAXElements; // @synthesize disclosedChildRowAXElements=_disclosedChildRowAXElements;
@property(copy) NSArray *children; // @synthesize children=_children;
@property(copy) NSArray *userTestingAttributes; // @synthesize userTestingAttributes=_userTestingAttributes;
@property long long verticalSizeClass; // @synthesize verticalSizeClass=_verticalSizeClass;
@property long long horizontalSizeClass; // @synthesize horizontalSizeClass=_horizontalSizeClass;
@property unsigned long long traits; // @synthesize traits=_traits;
@property _Bool isMainWindow; // @synthesize isMainWindow=_isMainWindow;
@property(getter=isSelected) _Bool selected; // @synthesize selected=_selected;
@property(getter=isEnabled) _Bool enabled; // @synthesize enabled=_enabled;
@property _Bool hasFocus; // @synthesize hasFocus=_hasFocus;
@property _Bool hasKeyboardFocus; // @synthesize hasKeyboardFocus=_hasKeyboardFocus;
@property(copy) NSString *identifier; // @synthesize identifier=_identifier;
@property(copy) NSString *label; // @synthesize label=_label;
@property(copy) NSString *title; // @synthesize title=_title;
@property(copy) NSString *placeholderValue; // @synthesize placeholderValue=_placeholderValue;
@property(copy) id value; // @synthesize value=_value;
@property(readonly, copy) NSString *truncatedValueString;
@property struct CGRect frame; // @synthesize frame=_frame;
@property unsigned long long elementType; // @synthesize elementType=_elementType;
- (id)_fetchPrivilegedValueForKey:(id)arg1;
- (_Bool)_shouldAttemptPrivilegedFaultForValue:(id)arg1;
- (_Bool)_fetchBoolForKey:(id)arg1;
- (id)_fetchSimpleValueForKey:(id)arg1;
//- (void)_assertForFaultsInContext:(CDUnknownBlockType)arg1;
- (int)_faultingBitForKey:(id)arg1;
- (void)markAsFaultedInPropertiesDerivedFromSnapshotAttributes:(id)arg1;
- (_Bool)_willAssertOnFault;
- (void)_recursivelySetFaultedBits:(int)arg1;
- (void)_unsetIsFaultedIn:(int)arg1;
- (void)_setIsFaultedIn:(int)arg1;
- (_Bool)_isFaultedIn:(int)arg1;
- (_Bool)_shouldAttemptFaultForBit:(int)arg1;
- (void)_compensateForInsufficientElementTypeData;
- (void)_recursivelyResetElementType;
- (void)recursivelyClearDataSource;
@property __weak id dataSource; // @synthesize dataSource=_dataSource;
- (_Bool)isEqual:(id)arg1;
- (unsigned long long)hash;
- (id)copyWithZone:(struct _NSZone *)arg1;
- (void)encodeWithCoder:(id)arg1;
- (id)initWithCoder:(id)arg1;
@property(readonly, copy) NSArray *identifiers;
@property(nonatomic) unsigned long long generation; // @synthesize generation=_generation;
@property(nonatomic) __weak id application; // @synthesize application=_application;
- (id)initWithAccessibilityElement:(id)arg1;
- (void)dealloc;

@end

