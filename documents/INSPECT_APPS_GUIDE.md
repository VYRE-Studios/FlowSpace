# How to Inspect Teams/Slack/Zoom Features Locally

## Method 1: Manual Testing (Recommended)

### Microsoft Teams

1. **Install Teams**
   - Download from: https://www.microsoft.com/en-us/microsoft-teams/download-app
   - Or use web version: https://teams.microsoft.com

2. **Create Test Account**
   - Use a free Microsoft account
   - Create a test team/channel

3. **Inspect Features**
   ```
   Steps to follow:
   1. Open Teams
   2. Create a test channel
   3. Send a test message
   4. Right-click the message → See all options
   5. Hover over message → See inline actions
   6. Click message input → See formatting toolbar
   7. Click attachment icon → See file types
   8. Type @ → See mention autocomplete
   9. Click "Reply" → See thread interface
   10. Check Settings → See all features
   ```

4. **Document Findings**
   - Take screenshots of each feature
   - Note keyboard shortcuts (Ctrl+/ shows all)
   - Check context menus
   - Test file uploads
   - Test reactions
   - Test threads

### Slack

1. **Install Slack**
   - Download from: https://slack.com/downloads/windows
   - Or use web version: https://slack.com

2. **Create Test Workspace**
   - Go to: https://slack.com/create
   - Create free workspace
   - Invite yourself to test

3. **Inspect Features**
   ```
   Steps to follow:
   1. Open Slack
   2. Create a test channel
   3. Type / → See all slash commands
   4. Send message → Check formatting options
   5. Right-click message → See all actions
   6. Click attachment → See file options
   7. Type @ → See mention options
   8. Click thread icon → See threading
   9. Hover message → See reaction picker
   10. Check Preferences → See all settings
   ```

4. **Document Findings**
   - List all slash commands
   - Screenshot formatting toolbar
   - Note file upload limits
   - Test reactions/threads
   - Check keyboard shortcuts

### Zoom

1. **Install Zoom**
   - Download from: https://zoom.us/download
   - Sign up for free account

2. **Start Test Meeting**
   - Start a meeting (can be just you)
   - Open Chat panel

3. **Inspect Features**
   ```
   Steps to follow:
   1. Open Zoom
   2. Start a meeting
   3. Open Chat panel
   4. Send message → Check options
   ```

---

## Method 2: Browser DevTools Inspection

### For Web Versions

1. **Open Teams/Slack in Browser**
2. **Open DevTools** (F12)
3. **Inspect Elements**
   - Right-click UI elements → Inspect
   - See HTML structure
   - Check CSS classes
   - See JavaScript event handlers

4. **Network Tab**
   - See API calls
   - Check WebSocket connections
   - See file upload endpoints
   - Check message format

5. **Application Tab**
   - Check LocalStorage
   - Check IndexedDB
   - See stored data structure

### Example: Inspecting Teams Message Format

```javascript
// In Browser Console (F12)
// Find message element
const message = document.querySelector('[data-tid="message"]');
console.log(message);

// Check message data
const messageData = message.getAttribute('data-message');
console.log(JSON.parse(messageData));

// Check WebSocket messages
// (In Network tab, filter by WS)
```

---

## Method 3: API Documentation

### Teams API
- **Graph API**: https://docs.microsoft.com/en-us/graph/api/resources/teams-api-overview
- **Bot Framework**: https://docs.microsoft.com/en-us/microsoftteams/platform/

### Slack API
- **Web API**: https://api.slack.com/web
- **Events API**: https://api.slack.com/events-api
- **RTM API**: https://api.slack.com/rtm

### Zoom API
- **Chat API**: https://marketplace.zoom.us/docs/api-reference/zoom-api/chat/

---

## Method 4: Create Feature Test Document

Create a document like this for each app:

```markdown
# Teams Feature Inspection - [Date]

## Basic Messaging
- [x] Text messages
- [x] Rich text (bold, italic, underline)
- [x] Code blocks
- [ ] Markdown

## File Sharing
- [x] File attachments
- [x] Image previews
- [x] Drag & drop
- [ ] File versioning

## Message Actions
- [x] Reactions
- [x] Threads
- [x] Edit
- [x] Delete
- [x] Pin

## Screenshots
[Attach screenshots here]

## Keyboard Shortcuts
- Ctrl+B: Bold
- Ctrl+I: Italic
- ...

## API Observations
[Note any API calls you see in Network tab]
```

---

## Method 5: Automated Feature Detection (Advanced)

### Using Browser Automation

Create a script to automatically detect features:

```python
# Example using Selenium (Python)
from selenium import webdriver
from selenium.webdriver.common.by import By

driver = webdriver.Chrome()
driver.get("https://teams.microsoft.com")

# Check for features
features = {
    'file_upload': driver.find_elements(By.CSS_SELECTOR, '[aria-label*="attach"]'),
    'emoji_picker': driver.find_elements(By.CSS_SELECTOR, '[aria-label*="emoji"]'),
    'formatting': driver.find_elements(By.CSS_SELECTOR, '[aria-label*="format"]'),
    # ... etc
}

print(features)
```

---

## Quick Reference: What to Check

### Message Input Area
- [ ] Formatting toolbar (bold, italic, etc.)
- [ ] Attachment button
- [ ] Emoji picker
- [ ] @ mention autocomplete
- [ ] Code block button
- [ ] Link button
- [ ] GIF button
- [ ] Voice message button

### Message Context Menu (Right-click)
- [ ] React
- [ ] Reply/Thread
- [ ] Edit
- [ ] Delete
- [ ] Pin
- [ ] Copy
- [ ] Forward
- [ ] Save/Bookmark

### Message Hover Actions
- [ ] Quick reactions
- [ ] Reply button
- [ ] More options

### Channel Features
- [ ] Channel description
- [ ] Channel topic
- [ ] Member list
- [ ] Channel settings
- [ ] Search in channel
- [ ] Pinned messages
- [ ] Channel notifications

### Settings to Check
- [ ] Notification preferences
- [ ] Message formatting
- [ ] File upload limits
- [ ] Keyboard shortcuts
- [ ] Theme/appearance
- [ ] Privacy settings
- [ ] Encryption settings

---

## Tools for Inspection

1. **Screenshot Tool**: Windows Snipping Tool or ShareX
2. **Screen Recorder**: OBS Studio (for recording interactions)
3. **API Inspector**: Browser DevTools Network tab
4. **DOM Inspector**: Browser DevTools Elements tab
5. **Console**: Browser DevTools Console (for JavaScript inspection)

---

## Tips

1. **Create Test Accounts**: Use separate accounts for each app
2. **Take Screenshots**: Document every feature visually
3. **Note Keyboard Shortcuts**: These reveal hidden features
4. **Check Mobile Apps**: Some features differ on mobile
5. **Test Edge Cases**: Large files, long messages, etc.
6. **Check Documentation**: Official docs often list all features
7. **User Forums**: Reddit, Stack Overflow reveal user-requested features

---

## Next Steps

1. **Inspect Teams** → Document all features
2. **Inspect Slack** → Document all features  
3. **Inspect Zoom** → Document all features
4. **Compare with FLO** → Create gap analysis
5. **Prioritize Features** → Decide what to implement first
6. **Create Implementation Plan** → Break down into tasks

