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

#import <arpa/inet.h>
#import <stdatomic.h>
#import <sys/socket.h>
#import <unistd.h>

#import "AMHTTPServer.h"
#import "RouteRequest.h"
#import "RouteResponse.h"

static atomic_int gProbeHits;
static atomic_int gEchoedBodyLength;

// Exercises AMHTTPServer's routing and its HTTP/1.1 framing defenses. The framing tests drive raw
// BSD sockets - URL-loading APIs cannot produce malformed payloads like these.
@interface AMHTTPServerTests : XCTestCase
@property (nonatomic, strong) AMHTTPServer *server;
@property (nonatomic, assign) uint16_t port;
@end

@implementation AMHTTPServerTests

- (void)setUp
{
  [super setUp];
  atomic_store(&gProbeHits, 0);
  atomic_store(&gEchoedBodyLength, 0);

  self.server = [AMHTTPServer new];
  [self.server get:@"/ping" withBlock:^(RouteRequest *request, RouteResponse *response) {
    [response respondWithString:@"pong"];
  }];
  [self.server get:@"/items/:itemId" withBlock:^(RouteRequest *request, RouteResponse *response) {
    [response respondWithString:request.params[@"itemId"] ?: @""];
  }];
  [self.server delete:@"/ping" withBlock:^(RouteRequest *request, RouteResponse *response) {
    [response respondWithString:@"deleted"];
  }];
  [self.server handleMethod:@"POST" withPath:@"/probe" block:^(RouteRequest *request, RouteResponse *response) {
    atomic_fetch_add(&gProbeHits, 1);
    atomic_store(&gEchoedBodyLength, (int)request.body.length);
    [response respondWithString:@"probe-ok"];
  }];
  [self.server setDefaultHeader:@"X-Test-Default" value:@"1"];

  self.server.port = 0;
  NSError *error;
  XCTAssertTrue([self.server start:&error], @"%@", error);
  XCTAssertTrue(self.server.isRunning);
  self.port = [[self.server valueForKeyPath:@"socket.port"] unsignedShortValue];
  XCTAssertNotEqual(self.port, 0, @"the server must have been bound to an ephemeral port");
}

- (void)tearDown
{
  [self.server stop:NO];
  XCTAssertFalse(self.server.isRunning);
  self.server = nil;
  [super tearDown];
}

#pragma mark - Raw socket helper

// Sends `payload` as-is and reads until the server closes the connection or `timeout` elapses.
// Returns everything received (nil on connect failure); *didClose reports whether EOF was seen.
- (NSString *)responseForRawPayload:(NSData *)payload timeout:(NSTimeInterval)timeout didClose:(BOOL *)didClose
{
  *didClose = NO;
  int fd = socket(AF_INET, SOCK_STREAM, 0);
  if (fd < 0) {
    return nil;
  }
  int noSigpipe = 1;
  setsockopt(fd, SOL_SOCKET, SO_NOSIGPIPE, &noSigpipe, sizeof(noSigpipe));
  struct timeval tv = { .tv_sec = (long)timeout, .tv_usec = 0 };
  setsockopt(fd, SOL_SOCKET, SO_RCVTIMEO, &tv, sizeof(tv));
  struct sockaddr_in addr = { .sin_family = AF_INET, .sin_port = htons(self.port) };
  addr.sin_addr.s_addr = htonl(INADDR_LOOPBACK);
  if (0 != connect(fd, (struct sockaddr *)&addr, sizeof(addr))) {
    close(fd);
    return nil;
  }
  // send(2) may write only part of the payload, which would truncate the multi-KiB flood
  // payloads into something the server answers differently. Errors stay ignored on purpose:
  // some of these tests expect the server to close the connection mid-send.
  const uint8_t *bytes = payload.bytes;
  size_t remaining = payload.length;
  while (remaining > 0) {
    ssize_t sent = send(fd, bytes, remaining, 0);
    if (sent <= 0) {
      break;
    }
    bytes += sent;
    remaining -= (size_t)sent;
  }
  NSMutableData *received = [NSMutableData data];
  char chunk[4096];
  struct timeval drainTv = { .tv_sec = 0, .tv_usec = 200000 };
  setsockopt(fd, SOL_SOCKET, SO_RCVTIMEO, &drainTv, sizeof(drainTv));
  NSDate *deadline = [NSDate dateWithTimeIntervalSinceNow:timeout];
  // A keep-alive response never sends EOF, so waiting for one would sit out the whole `timeout`
  // on every non-closing response. Instead treat 600ms of silence after the last received byte as
  // "the response is done" - long enough to bridge the gaps between a pipelined request's
  // separately-arriving responses, short enough to not slow every keep-alive test down to `timeout`.
  NSDate *idleDeadline = [NSDate dateWithTimeIntervalSinceNow:0.6];
  while (deadline.timeIntervalSinceNow > 0 && idleDeadline.timeIntervalSinceNow > 0) {
    ssize_t n = recv(fd, chunk, sizeof(chunk), 0);
    if (n == 0) {
      *didClose = YES;
      break;
    }
    if (n < 0) {
      // A read timeout - keep polling until the idle window (or the overall deadline) elapses.
      continue;
    }
    [received appendBytes:chunk length:(NSUInteger)n];
    idleDeadline = [NSDate dateWithTimeIntervalSinceNow:0.6];
  }
  close(fd);
  return [[NSString alloc] initWithData:received encoding:NSUTF8StringEncoding] ?: @"";
}

- (NSString *)responseForRawString:(NSString *)payload timeout:(NSTimeInterval)timeout didClose:(BOOL *)didClose
{
  return [self responseForRawPayload:(NSData * _Nonnull)[payload dataUsingEncoding:NSUTF8StringEncoding]
                              timeout:timeout
                             didClose:didClose];
}

#pragma mark - Routing

- (void)testGetRouteIsServed
{
  BOOL didClose;
  NSString *response = [self responseForRawString:@"GET /ping HTTP/1.1\r\n\r\n" timeout:5.0 didClose:&didClose];
  XCTAssertTrue([response containsString:@"200"], @"%@", response);
  XCTAssertTrue([response containsString:@"pong"], @"%@", response);
}

- (void)testPathParamIsCaptured
{
  BOOL didClose;
  NSString *response = [self responseForRawString:@"GET /items/42 HTTP/1.1\r\n\r\n" timeout:5.0 didClose:&didClose];
  XCTAssertTrue([response containsString:@"200"], @"%@", response);
  XCTAssertTrue([response containsString:@"42"], @"%@", response);
}

- (void)testUnmatchedPathReturnsNotFound
{
  BOOL didClose;
  NSString *response = [self responseForRawString:@"GET /does/not/exist HTTP/1.1\r\n\r\n" timeout:5.0 didClose:&didClose];
  XCTAssertTrue([response containsString:@"404"], @"%@", response);
}

- (void)testMethodNotRegisteredForPathReturnsNotFound
{
  // POST is not registered for /ping - only GET and DELETE are.
  BOOL didClose;
  NSString *response = [self responseForRawString:@"POST /ping HTTP/1.1\r\nContent-Length: 0\r\n\r\n" timeout:5.0 didClose:&didClose];
  XCTAssertTrue([response containsString:@"404"], @"%@", response);
}

- (void)testDeleteRouteIsServed
{
  BOOL didClose;
  NSString *response = [self responseForRawString:@"DELETE /ping HTTP/1.1\r\n\r\n" timeout:5.0 didClose:&didClose];
  XCTAssertTrue([response containsString:@"200"], @"%@", response);
  XCTAssertTrue([response containsString:@"deleted"], @"%@", response);
}

- (void)testDefaultHeaderIsAppliedToEveryResponse
{
  BOOL didClose;
  NSString *response = [self responseForRawString:@"GET /ping HTTP/1.1\r\n\r\n" timeout:5.0 didClose:&didClose];
  XCTAssertTrue([response containsString:@"X-Test-Default: 1"], @"%@", response);
}

- (void)testRequestBodyIsDeliveredToRoute
{
  NSString *payload = @"POST /probe HTTP/1.1\r\nContent-Length: 5\r\n\r\nhello";
  BOOL didClose;
  NSString *response = [self responseForRawString:payload timeout:5.0 didClose:&didClose];
  XCTAssertTrue([response containsString:@"200"], @"%@", response);
  XCTAssertTrue([response containsString:@"probe-ok"], @"%@", response);
  XCTAssertEqual(atomic_load(&gProbeHits), 1);
  XCTAssertEqual(atomic_load(&gEchoedBodyLength), 5);
}

- (void)testRequestIsDispatchedWhenBodyArrivesInASeparateSegment
{
  // Regression test: the header block and body used to arrive in separate receive callbacks
  // (e.g. a slow client, or a body that just misses the header's TCP segment). The pipelining
  // loop in -processBufferForClient: must stop and wait for the rest of the body instead of
  // re-checking the same unchanged buffer forever, which would spin the connection's serial
  // queue and stall every other connection queued behind it.
  int fd = socket(AF_INET, SOCK_STREAM, 0);
  XCTAssertGreaterThanOrEqual(fd, 0);
  int noSigpipe = 1;
  setsockopt(fd, SOL_SOCKET, SO_NOSIGPIPE, &noSigpipe, sizeof(noSigpipe));
  struct timeval tv = { .tv_sec = 5, .tv_usec = 0 };
  setsockopt(fd, SOL_SOCKET, SO_RCVTIMEO, &tv, sizeof(tv));
  struct sockaddr_in addr = { .sin_family = AF_INET, .sin_port = htons(self.port) };
  addr.sin_addr.s_addr = htonl(INADDR_LOOPBACK);
  XCTAssertEqual(0, connect(fd, (struct sockaddr *)&addr, sizeof(addr)));

  NSData *headerData = [@"POST /probe HTTP/1.1\r\nContent-Length: 5\r\n\r\n" dataUsingEncoding:NSUTF8StringEncoding];
  NSData *bodyData = [@"hello" dataUsingEncoding:NSUTF8StringEncoding];
  XCTAssertEqual((ssize_t)headerData.length, send(fd, headerData.bytes, headerData.length, 0));
  // Long enough that the server's receive callback for the header block has already returned
  // (waiting for the body) well before the body arrives in its own, later callback.
  [NSThread sleepForTimeInterval:0.3];
  XCTAssertEqual((ssize_t)bodyData.length, send(fd, bodyData.bytes, bodyData.length, 0));

  char chunk[256];
  ssize_t n = recv(fd, chunk, sizeof(chunk), 0);
  NSString *response = n > 0 ? [[NSString alloc] initWithBytes:chunk length:(NSUInteger)n encoding:NSUTF8StringEncoding] : @"";
  close(fd);

  XCTAssertTrue([response containsString:@"200"], @"%@", response);
  XCTAssertTrue([response containsString:@"probe-ok"], @"%@", response);
  XCTAssertEqual(atomic_load(&gProbeHits), 1);
  XCTAssertEqual(atomic_load(&gEchoedBodyLength), 5);
}

#pragma mark - HTTP/1.1 framing hardening

- (void)testNonNumericContentLengthIsRejected
{
  // Under -integerValue's lenient parsing "bogus" became 0: the probe route would run with an
  // empty body and the smuggled GET below would be answered as a second pipelined request.
  NSString *payload = @"POST /probe HTTP/1.1\r\nContent-Length: bogus\r\n\r\nGET /ping HTTP/1.1\r\n\r\n";
  BOOL didClose;
  NSString *response = [self responseForRawString:payload timeout:5.0 didClose:&didClose];
  XCTAssertTrue([response containsString:@"400"], @"%@", response);
  XCTAssertFalse([response containsString:@"pong"], @"the smuggled request must not be answered: %@", response);
  XCTAssertTrue(didClose, @"the connection must be closed after unparseable framing");
  XCTAssertEqual(atomic_load(&gProbeHits), 0, @"the route must not be dispatched with unknown body extent");
}

- (void)testPartiallyNumericContentLengthIsRejected
{
  NSString *payload = @"POST /probe HTTP/1.1\r\nContent-Length: 5abc\r\n\r\nhello";
  BOOL didClose;
  NSString *response = [self responseForRawString:payload timeout:5.0 didClose:&didClose];
  XCTAssertTrue([response containsString:@"400"], @"%@", response);
  XCTAssertTrue(didClose);
  XCTAssertEqual(atomic_load(&gProbeHits), 0);
}

- (void)testWhitespaceBeforeHeaderColonIsRejected
{
  // RFC 7230 (3.2.4): whitespace between a field name and its colon MUST be rejected with a 400.
  // Tolerating it stores "content-length " as a distinct key, dispatches the request with a
  // zero-length body, and re-parses the declared body as a smuggled pipelined request.
  NSString *payload = @"POST /probe HTTP/1.1\r\nContent-Length : 5\r\n\r\nhello";
  BOOL didClose;
  NSString *response = [self responseForRawString:payload timeout:5.0 didClose:&didClose];
  XCTAssertTrue([response containsString:@"400"], @"%@", response);
  XCTAssertTrue(didClose);
  XCTAssertEqual(atomic_load(&gProbeHits), 0);
}

- (void)testHeaderLineWithoutColonIsRejected
{
  // Silently skipping the malformed line made this dispatch with an empty body while "hello"
  // stayed in the buffer to be parsed as the next request.
  NSString *payload = @"POST /probe HTTP/1.1\r\nContent-Length 5\r\n\r\nhello";
  BOOL didClose;
  NSString *response = [self responseForRawString:payload timeout:5.0 didClose:&didClose];
  XCTAssertTrue([response containsString:@"400"], @"%@", response);
  XCTAssertTrue(didClose);
  XCTAssertEqual(atomic_load(&gProbeHits), 0);
}

- (void)testDuplicateContentLengthIsRejected
{
  // RFC 7230 (3.3.3): repeated framing fields are unrecoverable. Last-wins assignment would let
  // the second value drive parsing while an intermediary used the first - a smuggling primitive.
  NSString *payload = @"POST /probe HTTP/1.1\r\nContent-Length: 5\r\nContent-Length: 0\r\n\r\nhello";
  BOOL didClose;
  NSString *response = [self responseForRawString:payload timeout:5.0 didClose:&didClose];
  XCTAssertTrue([response containsString:@"400"], @"%@", response);
  XCTAssertTrue(didClose);
  XCTAssertEqual(atomic_load(&gProbeHits), 0);
}

- (void)testDuplicateTransferEncodingIsRejected
{
  NSString *payload = @"POST /probe HTTP/1.1\r\nTransfer-Encoding: chunked\r\nTransfer-Encoding: identity\r\n\r\n0\r\n\r\n";
  BOOL didClose;
  NSString *response = [self responseForRawString:payload timeout:5.0 didClose:&didClose];
  XCTAssertTrue([response containsString:@"400"], @"%@", response);
  XCTAssertTrue(didClose);
  XCTAssertEqual(atomic_load(&gProbeHits), 0);
}

- (void)testChunkedTransferEncodingIsRejected
{
  NSString *payload = @"POST /probe HTTP/1.1\r\nTransfer-Encoding: chunked\r\n\r\n0\r\n\r\n";
  BOOL didClose;
  NSString *response = [self responseForRawString:payload timeout:5.0 didClose:&didClose];
  XCTAssertTrue([response containsString:@"400"], @"%@", response);
  XCTAssertTrue(didClose);
  XCTAssertEqual(atomic_load(&gProbeHits), 0);
}

- (void)testNonChunkedTransferEncodingIsAlsoRejected
{
  // No transfer decoder exists at all, so any encoding is unsupported - not just "chunked".
  NSString *payload = @"POST /probe HTTP/1.1\r\nTransfer-Encoding: identity\r\n\r\nhello";
  BOOL didClose;
  NSString *response = [self responseForRawString:payload timeout:5.0 didClose:&didClose];
  XCTAssertTrue([response containsString:@"400"], @"%@", response);
  XCTAssertTrue(didClose);
  XCTAssertEqual(atomic_load(&gProbeHits), 0);
}

- (void)testOversizedDeclaredContentLengthIsRejected
{
  // The declared length alone is enough to reject - the body itself is never sent.
  NSString *payload = @"POST /probe HTTP/1.1\r\nContent-Length: 999999999999\r\n\r\n";
  BOOL didClose;
  NSString *response = [self responseForRawString:payload timeout:5.0 didClose:&didClose];
  XCTAssertTrue([response containsString:@"400"], @"%@", response);
  XCTAssertTrue(didClose);
  XCTAssertEqual(atomic_load(&gProbeHits), 0);
}

- (void)testOversizedHeaderBlockIsRejected
{
  // A header block that never terminates: 96 KiB of header lines with no \r\n\r\n. The server
  // must stop buffering and close the connection instead of growing the buffer indefinitely.
  NSMutableString *payload = [NSMutableString stringWithString:@"GET /ping HTTP/1.1\r\n"];
  NSString *filler = [@"X-Filler: " stringByAppendingString:[@"" stringByPaddingToLength:1013 withString:@"a" startingAtIndex:0]];
  while (payload.length < 96 * 1024) {
    [payload appendString:filler];
    [payload appendString:@"\r\n"];
  }
  BOOL didClose;
  NSString *response = [self responseForRawString:payload timeout:10.0 didClose:&didClose];
  XCTAssertTrue([response containsString:@"400"], @"%@", response);
  XCTAssertTrue(didClose, @"the connection must be closed rather than left buffering");
}

- (void)testOversizedCompletedHeaderBlockIsRejected
{
  // Same flood, but properly terminated with \r\n\r\n. Depending on how the bytes coalesce, the
  // terminator can arrive in the same receive callback as the bulk of the block, in which case
  // the incomplete-header cap never fires - the completed block must be rejected too instead of
  // being copied and parsed.
  NSMutableString *payload = [NSMutableString stringWithString:@"GET /ping HTTP/1.1\r\n"];
  NSString *filler = [@"X-Filler: " stringByAppendingString:[@"" stringByPaddingToLength:1013 withString:@"a" startingAtIndex:0]];
  while (payload.length < 96 * 1024) {
    [payload appendString:filler];
    [payload appendString:@"\r\n"];
  }
  [payload appendString:@"\r\n"];
  BOOL didClose;
  NSString *response = [self responseForRawString:payload timeout:10.0 didClose:&didClose];
  XCTAssertTrue([response containsString:@"400"], @"%@", response);
  XCTAssertFalse([response containsString:@"pong"], @"the oversized request must not be served: %@", response);
  XCTAssertTrue(didClose, @"the connection must be closed rather than left buffering");
}

- (void)testPipelinedRequestsAreServedInOrder
{
  // Two requests in one payload: both must be answered on the same connection.
  NSString *payload = @"GET /ping HTTP/1.1\r\n\r\nGET /items/7 HTTP/1.1\r\n\r\n";
  BOOL didClose;
  NSString *response = [self responseForRawString:payload timeout:5.0 didClose:&didClose];
  NSRange pongRange = [response rangeOfString:@"pong"];
  NSRange sevenRange = [response rangeOfString:@"7"];
  XCTAssertNotEqual(pongRange.location, (NSUInteger)NSNotFound, @"%@", response);
  XCTAssertNotEqual(sevenRange.location, (NSUInteger)NSNotFound, @"%@", response);
  XCTAssertLessThan(pongRange.location, sevenRange.location, @"responses must arrive in request order: %@", response);
}

#pragma mark - Lifecycle

- (void)testStopClosesOpenConnections
{
  int fd = socket(AF_INET, SOCK_STREAM, 0);
  XCTAssertGreaterThanOrEqual(fd, 0);
  struct sockaddr_in addr = { .sin_family = AF_INET, .sin_port = htons(self.port) };
  addr.sin_addr.s_addr = htonl(INADDR_LOOPBACK);
  XCTAssertEqual(0, connect(fd, (struct sockaddr *)&addr, sizeof(addr)));
  // Give Network.framework's async accept handshake a moment to register the connection before
  // it gets torn down, so -stop: has something to cancel rather than racing the accept.
  [NSThread sleepForTimeInterval:0.3];

  [self.server stop:NO];

  // -stop: cancels connections asynchronously on its own queue, so poll for the teardown to land
  // instead of a single blocking recv - a RST surfaces as a recv error, not a 0-byte read, so
  // either outcome counts as "the connection is no longer usable". A recv timeout (EAGAIN) only
  // means no bytes arrived yet - it says nothing about the connection being closed, so it must
  // keep polling rather than being treated as (or masking a missing) termination.
  struct timeval shortTv = { .tv_sec = 0, .tv_usec = 200000 };
  setsockopt(fd, SOL_SOCKET, SO_RCVTIMEO, &shortTv, sizeof(shortTv));
  NSDate *deadline = [NSDate dateWithTimeIntervalSinceNow:5.0];
  char buf[16];
  BOOL didObserveTermination = NO;
  while (!didObserveTermination && deadline.timeIntervalSinceNow > 0) {
    ssize_t n = recv(fd, buf, sizeof(buf), 0);
    if (n == 0) {
      didObserveTermination = YES;
    } else if (n < 0 && errno != EAGAIN && errno != EWOULDBLOCK) {
      didObserveTermination = YES;
    }
  }
  close(fd);
  XCTAssertTrue(didObserveTermination, @"the connection must observe an EOF or a reset once the server stops");
}

- (void)testNoNewConnectionsAcceptedAfterStop
{
  [self.server stop:NO];

  // -stop: cancels the listener asynchronously, so poll instead of asserting on the first attempt.
  NSDate *deadline = [NSDate dateWithTimeIntervalSinceNow:5.0];
  int connectResult;
  do {
    int fd = socket(AF_INET, SOCK_STREAM, 0);
    XCTAssertGreaterThanOrEqual(fd, 0);
    struct sockaddr_in addr = { .sin_family = AF_INET, .sin_port = htons(self.port) };
    addr.sin_addr.s_addr = htonl(INADDR_LOOPBACK);
    connectResult = connect(fd, (struct sockaddr *)&addr, sizeof(addr));
    close(fd);
    if (0 != connectResult) {
      break;
    }
    [NSThread sleepForTimeInterval:0.1];
  } while (deadline.timeIntervalSinceNow > 0);
  XCTAssertNotEqual(0, connectResult, @"a stopped server must not accept new connections on its old port");
}

@end
