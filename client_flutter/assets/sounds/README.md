# FlowSpace Sound Effects

This directory contains sound effects for the Flo application.

## Current Sound Files

✅ `message.mp3` - New message notification (subtle ping)
✅ `mention.mp3` - Mention notification (distinct chime)  
✅ `online.mp3` - User online notification (soft activation)
✅ `offline.mp3` - User offline notification (muted thud)
✅ `typing.mp3` - Typing indicator (optional pulse)

## Missing Sound Files

❌ `update.mp3` - Update available notification (alert sound)

## Creating the Missing Sound

You can create `update.mp3` in one of these ways:

### Option 1: Use an Existing Sound Temporarily
Copy one of the existing sounds as a placeholder:
```powershell
Copy-Item message.mp3 update.mp3
```

### Option 2: Generate Custom Sound
Use a tool like:
- **Audacity** (free): Generate tone or import sound
- **FL Studio** / **Ableton Live**: Professional DAW
- **Online generators**: freesound.org, zapsplat.com

### Option 3: AI Sound Generation
- **ElevenLabs** (sound effects)
- **Stable Audio**
- **AudioCraft by Meta**

## Sound Design Guidelines

**Update Sound (`update.mp3`):**
- Duration: 0.5-1.0 seconds
- Style: Alert/notification (not alarming)
- Tone: Positive, professional
- Volume: Medium (user should notice but not be startled)
- Example: Two-tone chime or ascending arpeggio

**General Guidelines for All Sounds:**
- Keep files under 100KB
- Use 128-192 kbps MP3 encoding
- Sample rate: 44.1kHz
- Normalize volume levels
- Add slight fade in/out
- Test on different devices

## Sound Effects Philosophy

Flo uses **subtle, professional sounds** that:
- Don't disrupt workflow
- Provide clear audio feedback
- Match the sleek, cinematic brand
- Are distinguishable from each other
- Work in both quiet and noisy environments

## Testing Sounds

To test a sound in the app:
1. Place the `.mp3` file in this directory
2. Trigger the corresponding event:
   - Message: Send a chat message
   - Mention: Send message with @username
   - Online: User joins workspace
   - Offline: User leaves workspace
   - Typing: User is typing in chat
   - Update: New version available (force check in Settings)

## Licensing

Ensure all sound files are:
- Created by you, OR
- Licensed for commercial use (if using third-party sources)
- Attribution provided if required by license
