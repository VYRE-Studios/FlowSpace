# FLŌ P2P Testing Guide

## B6 - Complete End-to-End Testing Suite

This guide provides comprehensive testing procedures for the FLŌ P2P system after implementing B3-B5.

---

## Prerequisites

1. **Two Windows machines** on the same LAN (PC A and PC B)
2. **FLŌ backend service** installed and running on both machines
3. **Flutter UI** available on both machines
4. **Windows Firewall** configured to allow UDP port 33445
5. **PostgreSQL database** running and accessible

---

## Test 1: Multi-Device Discovery

### Objective
Verify that peers discover each other automatically on the LAN.

### Steps

1. **Start service on PC A:**
   ```powershell
   Get-Service FlowSpaceBackend
   # Should show "Running"
   ```

2. **Start service on PC B:**
   ```powershell
   Get-Service FlowSpaceBackend
   # Should show "Running"
   ```

3. **Open Flutter UI on both machines**

4. **Verify in UI:**
   - Right sidebar should show discovered peers
   - Presence indicators should show green (online)
   - Activity feed should show "Peer discovered" events
   - Connection status indicator should show low latency (< 100ms)

### Expected Results
- Both UIs show each other as online peers within 2-5 seconds
- Presence indicators update in real-time
- Activity feed logs discovery events

### Logs to Check
```
C:\ProgramData\FLO\service\logs\flow_backend.out.log
```
Look for:
- `P2P Runtime listening on UDP port 33445`
- `Peer discovered: node_...`
- `P2P Gateway Connected`

---

## Test 2: Encrypted Messaging

### Objective
Verify message delivery, ordering, and decryption.

### Steps

1. **Send 1 message:**
   - From PC A, send a test message to PC B
   - Verify PC B receives it

2. **Send 10 messages in sequence:**
   - Send messages numbered 1-10
   - Verify PC B receives all 10 in order

3. **Send 100 messages rapidly:**
   - Use a script or rapid manual sending
   - Verify all messages arrive
   - Check for packet loss

4. **Verify decryption:**
   - Messages should be readable (not ciphertext)
   - No decryption errors in logs

### Expected Results
- 100% message delivery rate
- Messages arrive in order
- All messages are properly decrypted
- No packet loss

### Logs to Check
- `Message received from node_...`
- `Message delivered to node_...`
- No decryption errors

---

## Test 3: UI Closed Stress Test

### Objective
Verify background service continues operating when UI is closed.

### Steps

1. **Close Flutter app on PC A** (keep service running)

2. **From PC B, send 5 messages to PC A**

3. **Reopen Flutter app on PC A**

4. **Verify:**
   - Messages sync immediately
   - All 5 messages appear in order
   - No messages lost

### Expected Results
- Service continues running without UI
- Messages queue when peer is offline
- Messages sync when UI reopens
- No message loss

### Logs to Check
- `Message queued for node_...`
- `Processing queued messages`
- `Message delivered from queue`

---

## Test 4: Sleep and Wake

### Objective
Verify P2P runtime recovers after system sleep.

### Steps

1. **Put PC A to sleep**

2. **From PC B, send 3 messages to PC A**

3. **Wake PC A**

4. **Wait 10 seconds**

5. **Verify:**
   - PC A's service reconnects
   - Messages flush from queue
   - PC B shows PC A as online again

### Expected Results
- Service detects wake event
- UDP socket reinitializes
- Queued messages deliver automatically
- Peer presence updates correctly

### Logs to Check
- `P2P Runtime reinitializing after wake`
- `Processing queued messages`
- `Peer update: node_... online`

---

## Test 5: Reboot Recovery

### Objective
Verify service auto-starts and recovers state after reboot.

### Steps

1. **Send messages between PC A and PC B**

2. **Reboot PC B**

3. **Wait for service to auto-start** (should be automatic)

4. **Open UI on PC B**

5. **Verify:**
   - Service is running
   - UI connects to gateway
   - Queued messages sync
   - Peer list recovers

### Expected Results
- Service starts automatically on boot
- Database state persists
- Queued messages recover
- Peer connections re-establish

### Logs to Check
- Service startup logs
- `P2P Runtime initialized`
- `Loaded X persisted peers`
- `Processing queued messages`

---

## Test 6: Firewall Toggle

### Objective
Verify P2P works with firewall changes.

### Steps

1. **Turn Windows Firewall ON** (if off)

2. **Verify discovery still works:**
   - Peers should still discover each other
   - Messages should still deliver

3. **Turn Windows Firewall OFF**

4. **Verify:**
   - Discovery rebroadcasts
   - Messages continue working
   - No connection loss

### Expected Results
- P2P works with firewall enabled (if rules are correct)
- Discovery adapts to network changes
- No permanent connection loss

### Firewall Rules Required
```powershell
New-NetFirewallRule -DisplayName "FLO P2P UDP" -Direction Inbound -Protocol UDP -LocalPort 33445 -Action Allow
New-NetFirewallRule -DisplayName "FLO P2P UDP OUT" -Direction Outbound -Protocol UDP -LocalPort 33445 -Action Allow
```

---

## Test 7: Partial Connectivity

### Objective
Verify P2P works across different network segments.

### Steps

1. **PC A on Ethernet, PC B on WiFi** (same LAN)

2. **Verify:**
   - Discovery works
   - Messages deliver
   - Routing functions correctly

3. **Test with one peer on different subnet** (if possible)

### Expected Results
- P2P works across network segments on same LAN
- Broadcast discovery reaches all segments
- Messages route correctly

---

## Test 8: Verification Through Logs

### Objective
Comprehensive log analysis to verify all systems.

### Log Location
```
C:\ProgramData\FLO\service\logs\flow_backend.out.log
```

### What to Look For

#### Startup
- `P2P Runtime listening on UDP port 33445`
- `P2P Runtime initialized`
- `P2P Gateway Connected`

#### Discovery
- `Peer discovered: node_...`
- `Peer update: node_... online`
- `Peer lost: node_...`

#### Messaging
- `Message received from node_...`
- `Message queued for node_...`
- `Message delivered to node_...`
- `Delivery status: delivered`

#### Queueing
- `Processing queued messages`
- `Retry count: X`
- `Message delivered from queue`

#### Errors
- No UDP socket errors
- No decryption failures
- No database connection errors

---

## Performance Benchmarks

### Expected Metrics

- **Discovery Time:** < 5 seconds
- **Message Latency:** < 100ms on LAN
- **Delivery Rate:** 100% for online peers
- **Queue Processing:** < 3 seconds per message
- **Memory Usage:** < 100MB for service
- **CPU Usage:** < 5% idle, < 20% active

---

## Troubleshooting

### Peers Not Discovering

1. Check firewall rules
2. Verify both services are running
3. Check UDP port 33445 is not blocked
4. Verify both machines on same LAN
5. Check logs for UDP errors

### Messages Not Delivering

1. Verify peer is online (check presence)
2. Check queue status in database
3. Review retry logs
4. Verify encryption keys are valid
5. Check network connectivity

### Service Not Starting

1. Check Windows Event Viewer
2. Verify service is set to "Automatic"
3. Check database connection
4. Review service logs
5. Verify port 33445 is available

---

## Success Criteria

All tests pass when:

✅ Peers discover each other automatically  
✅ Messages deliver reliably (100% rate)  
✅ Service runs without UI  
✅ Messages queue when offline  
✅ Service recovers after reboot  
✅ Firewall changes don't break connectivity  
✅ Logs show clean operation  
✅ Performance meets benchmarks  

---

## Next Steps After Testing

Once all tests pass:

1. **Production Deployment:** System is ready for daily use
2. **Feature Expansion:** Add file sharing, voice, etc.
3. **Security Audit:** Review encryption implementation
4. **Performance Tuning:** Optimize for larger peer counts
5. **Documentation:** Update user guides

---

**End of Testing Guide**

