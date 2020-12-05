/*
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * See the NOTICE file distributed with this work for additional
 * information regarding copyright ownership.
 * You may obtain a copy of the License at
 *
 *     http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

#import <XCTest/XCTest.h>

#import "AMIntegrationTestCase.h"
#import "XCUIApplication+FBW3CActions.h"


@interface AMW3CActionsTests : AMIntegrationTestCase
@end

@implementation AMW3CActionsTests

- (void)setUp
{
  [super setUp];
  static dispatch_once_t onceToken;
  dispatch_once(&onceToken, ^{
    [self launchApplication];
  });
}

- (void)testErroneousGestures
{
  NSArray<NSArray<NSDictionary<NSString *, id> *> *> *invalidGestures =
  @[
    // Empty chain
    @[],

    // Chain element without 'actions' key
    @[@{
        @"type": @"pointer",
        @"id": @"finger1",
        @"parameters": @{@"pointerType": @"mouse"},
    },
    ],

    // Chain element with empty 'actions'
    @[@{
        @"type": @"pointer",
        @"id": @"finger1",
        @"parameters": @{@"pointerType": @"mouse"},
        @"actions": @[],
    },
    ],

    // Chain element without type
    @[@{
        @"id": @"finger1",
        @"parameters": @{@"pointerType": @"mouse"},
        @"actions": @[
            @{@"type": @"pointerMove", @"duration": @1, @"x": @100, @"y": @100},
        ],
    },
    ],

    // Chain element without id
    @[@{
        @"type": @"pointer",
        @"parameters": @{@"pointerType": @"mouse"},
        @"actions": @[
            @{@"type": @"pointerMove", @"duration": @1, @"x": @100, @"y": @100},
        ],
    },
    ],

    // Chain element with empty id
    @[@{
        @"type": @"pointer",
        @"id": @"",
        @"parameters": @{@"pointerType": @"mouse"},
        @"actions": @[
            @{@"type": @"pointerMove", @"duration": @1, @"x": @100, @"y": @100},
        ],
    },
    ],

    // Chain element with unsupported type
    @[@{
        @"type": @"key",
        @"id": @"finger1",
        @"parameters": @{@"pointerType": @"mouse"},
        @"actions": @[
            @{@"type": @"pointerMove", @"duration": @1, @"x": @100, @"y": @100},
        ],
    },
    ],

    // Chain element with unsupported pointerType (non-default)
    @[@{
        @"type": @"pointer",
        @"id": @"finger1",
        @"parameters": @{@"pointerType": @"pen"},
        @"actions": @[
            @{@"type": @"pointerMove", @"duration": @1, @"x": @100, @"y": @100},
        ],
    },
    ],

    // Chain element with unsupported pointerType (non-default)
    @[@{
        @"type": @"pointer",
        @"id": @"finger1",
        @"parameters": @{@"pointerType": @"key"},
        @"actions": @[
            @{@"type": @"pause", @"duration": @1},
        ],
    },
    ],

    // Chain element without action item type
    @[@{
        @"type": @"pointer",
        @"id": @"finger1",
        @"parameters": @{@"pointerType": @"mouse"},
        @"actions": @[
            @{@"duration": @1, @"x": @1, @"y": @1},
            @{@"type": @"pointerDown"},
            @{@"type": @"pause", @"duration": @100},
            @{@"type": @"pointerUp"},
        ],
    },
    ],

    // Chain element with singe up action
    @[@{
        @"type": @"pointer",
        @"id": @"finger1",
        @"parameters": @{@"pointerType": @"mouse"},
        @"actions": @[
            @{@"type": @"pointerUp"},
        ],
    },
    ],

    // Chain element containing action item without y coordinate
    @[@{
        @"type": @"pointer",
        @"id": @"finger1",
        @"parameters": @{@"pointerType": @"mouse"},
        @"actions": @[
            @{@"type": @"pointerMove", @"duration": @1, @"x": @1},
            @{@"type": @"pointerDown"},
            @{@"type": @"pause", @"duration": @100},
            @{@"type": @"pointerUp"},
        ],
    },
    ],

    // Chain element containing action item with an unknown type
    @[@{
        @"type": @"pointer",
        @"id": @"finger1",
        @"parameters": @{@"pointerType": @"mouse"},
        @"actions": @[
            @{@"type": @"pointerMoved", @"duration": @1, @"x": @1, @"y": @1},
            @{@"type": @"pointerDown"},
            @{@"type": @"pause", @"duration": @100},
            @{@"type": @"pointerUp"},
        ],
    },
    ],

    // Chain element where action items start with an incorrect item
    @[@{
        @"type": @"pointer",
        @"id": @"finger1",
        @"parameters": @{@"pointerType": @"mouse"},
        @"actions": @[
            @{@"type": @"pause", @"duration": @100},
            @{@"type": @"pointerMove", @"duration": @1, @"x": @1, @"y": @1},
            @{@"type": @"pointerDown"},
            @{@"type": @"pause", @"duration": @100},
            @{@"type": @"pointerUp"},
        ],
    },
    ],

    // Chain element where pointerMove action item does not contain coordinates
    @[@{
        @"type": @"pointer",
        @"id": @"finger1",
        @"parameters": @{@"pointerType": @"mouse"},
        @"actions": @[
            @{@"type": @"pointerMove", @"duration": @1},
            @{@"type": @"pointerDown"},
            @{@"type": @"pause", @"duration": @100},
            @{@"type": @"pointerUp"},
        ],
    },
    ],

    // Chain element where pointerMove action item cannot use coordinates of the previous item
    @[@{
        @"type": @"pointer",
        @"id": @"finger1",
        @"parameters": @{@"pointerType": @"mouse"},
        @"actions": @[
            @{@"type": @"pointerMove", @"duration": @1, @"origin": @"pointer"},
            @{@"type": @"pointerDown"},
            @{@"type": @"pause", @"duration": @100},
            @{@"type": @"pointerUp"},
        ],
    },
    ],

    // Chain element where action items contains negative duration
    @[@{
        @"type": @"pointer",
        @"id": @"finger1",
        @"parameters": @{@"pointerType": @"mouse"},
        @"actions": @[
            @{@"type": @"pointerMove", @"duration": @1, @"x": @1, @"y": @1},
            @{@"type": @"pointerDown"},
            @{@"type": @"pause", @"duration": @-100},
            @{@"type": @"pointerUp"},
        ],
    },
    ],

    // Chain element where move duration is less than 1 ms
    @[@{
        @"type": @"pointer",
        @"id": @"finger1",
        @"parameters": @{@"pointerType": @"mouse"},
        @"actions": @[
            @{@"type": @"pointerMove", @"duration": @0, @"x": @1, @"y": @1},
            @{@"type": @"pointerDown"},
            @{@"type": @"pause", @"duration": @100},
            @{@"type": @"pointerUp"},
        ],
    },
    ],

    // Chain element where action items start with an incorrect one, because the correct one is canceled
    @[@{
        @"type": @"pointer",
        @"id": @"finger1",
        @"parameters": @{@"pointerType": @"mouse"},
        @"actions": @[
            @{@"type": @"pointerMove", @"duration": @1, @"x": @1, @"y": @1},
            @{@"type": @"pointerCancel"},
            @{@"type": @"pointerDown"},
            @{@"type": @"pause", @"duration": @-100},
            @{@"type": @"pointerUp"},
        ],
    },
    ],

  ];

  for (NSArray<NSDictionary<NSString *, id> *> *invalidGesture in invalidGestures) {
    NSError *error;
    XCTAssertFalse([self.testedApplication fb_performW3CActions:invalidGesture
                                                   elementCache:nil
                                                          error:&error]);
    XCTAssertNotNil(error);
  }
}

- (void)testClick
{
  XCUIElement *checkbox = self.testedApplication.checkBoxes.firstMatch;
  NSNumber *value = checkbox.value;

  NSArray<NSDictionary<NSString *, id> *> *gesture =
  @[@{
      @"type": @"pointer",
      @"id": @"finger1",
      @"parameters": @{@"pointerType": @"mouse"},
      @"actions": @[
          @{@"type": @"pointerMove", @"duration": @10, @"origin": checkbox, @"x": @0, @"y": @0},
          @{@"type": @"pointerDown"},
          @{@"type": @"pause", @"duration": @100},
          @{@"type": @"pointerUp"},
      ],
  },
  ];
  NSError *error;
  XCTAssertTrue([self.testedApplication fb_performW3CActions:gesture
                                                elementCache:nil
                                                       error:&error]);
  XCTAssertNil(error);
  XCTAssertTrue([checkbox.value boolValue] != [value boolValue]);
}

- (void)testRightClick
{
  XCUIElement *checkbox = self.testedApplication.checkBoxes.firstMatch;
  NSNumber *value = checkbox.value;

  NSArray<NSDictionary<NSString *, id> *> *gesture =
  @[@{
      @"type": @"pointer",
      @"id": @"finger1",
      @"parameters": @{@"pointerType": @"mouse"},
      @"actions": @[
          @{@"type": @"pointerMove", @"duration": @10, @"origin": checkbox, @"x": @0, @"y": @0},
          @{@"type": @"pointerDown", @"button": @2},
          @{@"type": @"pause", @"duration": @100},
          @{@"type": @"pointerUp", @"button": @2},
      ],
  },
  ];
  NSError *error;
  XCTAssertTrue([self.testedApplication fb_performW3CActions:gesture
                                                elementCache:nil
                                                       error:&error]);
  XCTAssertNil(error);
  XCTAssertTrue([checkbox.value boolValue] == [value boolValue]);
}


@end
