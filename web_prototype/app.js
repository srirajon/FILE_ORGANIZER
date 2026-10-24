// Level 3 State Store
const DEFAULT_CONFIG = [
  {
    id: 'work_docs',
    name: 'Work Documents',
    description: 'Quarterly reports, NDA agreements & contracts',
    avatarEmoji: '💼',
    avatarBg: '#1E88E5',
    lastTimestamp: '11:42 AM',
    unreadCount: 0,
    files: [
      {
        id: 'f1',
        fileName: 'Q3_Financial_Analysis.pdf',
        fileSize: '2.4 MB',
        type: 'pdf',
        time: '11:42 AM',
        isPinned: false,
      },
      {
        id: 'f2',
        fileName: 'Vendor_Contract_DESCO.pdf',
        fileSize: '1.2 MB',
        type: 'pdf',
        time: '10:15 AM',
        isPinned: false,
      },
      {
        id: 'f3',
        fileName: 'Team_Sprint_Goals.docx',
        fileSize: '450 KB',
        type: 'doc',
        time: 'Yesterday',
        isPinned: false,
      },
    ],
  },
  {
    id: 'receipts',
    name: 'Receipts & Invoices',
    description: 'Tax deductions, utility bills & shopping receipts',
    avatarEmoji: '🧾',
    avatarBg: '#43A047',
    lastTimestamp: 'Yesterday',
    unreadCount: 0,
    files: [
      {
        id: 'f4',
        fileName: 'Grocery_Store_TaxInvoice.jpg',
        fileSize: '850 KB',
        type: 'img',
        time: 'Yesterday',
        isPinned: false,
      },
      {
        id: 'f5',
        fileName: 'Electricity_Bill_Oct2026.pdf',
        fileSize: '310 KB',
        type: 'pdf',
        time: 'Monday',
        isPinned: false,
      },
    ],
  },
  {
    id: 'ideas_notes',
    name: 'Ideas & Notes',
    description: 'AI responses, whiteboard clips & quick voice memos',
    avatarEmoji: '💡',
    avatarBg: '#FB8C00',
    lastTimestamp: 'Sunday',
    unreadCount: 0,
    files: [
      {
        id: 'f_md1',
        fileName: 'AI_Architecture_Brainstorm.md',
        fileSize: '2.4 KB',
        type: 'md',
        time: 'Sunday',
        isPinned: true,
        content: '# AI Brainstorm: Conversational File Organizer\n\n## Core Concept\n- Bypasses nested folder navigation by representing directories as conversational contacts.\n- Sharing a file looks like sending a WhatsApp message.\n\n## Key Advantages\n1. **Zero Friction Sorting:** One tap into WhatsApp contact.\n2. **AI Copied Text as .md:** Direct markdown file creation from LLM chats.\n3. **PC Access:** Direct USB folder access or cloud sync.\n\n```json\n{\n  "version": "1.0",\n  "status": "ready"\n}\n```',
      },
      {
        id: 'f8',
        fileName: 'App_Architecture_Diagram.png',
        fileSize: '1.4 MB',
        type: 'img',
        time: 'Sunday',
        isPinned: false,
      },
      {
        id: 'f9',
        fileName: 'Voice_Note_003.m4a',
        fileSize: '890 KB',
        type: 'audio',
        time: 'Oct 12',
        isPinned: false,
      },
    ],
  },
  {
    id: 'family_photos',
    name: 'Family Photos',
    description: 'Vacation memories, birthdays & family weekend',
    avatarEmoji: '📸',
    avatarBg: '#E53935',
    lastTimestamp: 'Tuesday',
    unreadCount: 0,
    files: [
      {
        id: 'f6',
        fileName: 'Beach_Sunset_2026.jpg',
        fileSize: '3.8 MB',
        type: 'img',
        time: 'Tuesday',
        isPinned: false,
      },
      {
        id: 'f7',
        fileName: 'Kids_Graduation.mp4',
        fileSize: '14.5 MB',
        type: 'video',
        time: 'Oct 15',
        isPinned: false,
      },
    ],
  },
  {
    id: 'medical',
    name: 'Medical & Health',
    description: 'Doctor prescriptions, blood tests & health insurance',
    avatarEmoji: '🏥',
    avatarBg: '#8E24AA',
    lastTimestamp: '10/12/26',
    unreadCount: 0,
    files: [
      {
        id: 'f10',
        fileName: 'Annual_Checkup_Lab_Results.pdf',
        fileSize: '980 KB',
        type: 'pdf',
        time: '10/12/26',
        isPinned: false,
      },
      {
        id: 'f11',
        fileName: 'Health_Insurance_Policy.pdf',
        fileSize: '1.8 MB',
        type: 'pdf',
        time: '09/28/26',
        isPinned: false,
      },
    ],
  },
];

// App State
const state = {
  activeScreen: 'home',
  activeFolderId: null,
  selectedOverlayFolderId: null,
  pendingSharedFile: null,
  isDarkTheme: true,
  isOpenedFromShare: false,
  isForwardMode: false,
  selectedEmoji: '📁',
  selectedColor: '#1E88E5',
  currentViewingMarkdown: null,
  folders: JSON.parse(localStorage.getItem('folders_config_v3') || JSON.stringify(DEFAULT_CONFIG)),
};

const EMOJI_PALETTE = ['📁', '💼', '🧾', '📸', '💡', '🏥', '🏢', '🚗', '🎓', '💰', '🛒', '✈️', '📄', '⚡', '🤖'];
const COLOR_PALETTE = [
  '#1E88E5', '#43A047', '#E53935', '#FB8C00', '#8E24AA', '#00ACC1', '#5E35B1', '#D81B60',
];

// DOM References
const foldersListEl = document.getElementById('foldersList');
const overlayContactsEl = document.getElementById('overlayContacts');
const shareOverlayEl = document.getElementById('shareOverlay');
const sendBtnContainerEl = document.getElementById('sendBtnContainer');
const sendBtnLabelEl = document.getElementById('sendBtnLabel');
const homeScreenEl = document.getElementById('homeScreen');
const chatScreenEl = document.getElementById('chatScreen');
const chatTitleEl = document.getElementById('chatTitle');
const chatSubtitleEl = document.getElementById('chatSubtitle');
const chatAvatarEl = document.getElementById('chatAvatar');
const chatMessagesEl = document.getElementById('chatMessages');
const pinnedBannerEl = document.getElementById('pinnedBanner');
const pinnedTextEl = document.getElementById('pinnedText');
const noteInputEl = document.getElementById('noteInput');
const toastMessageEl = document.getElementById('toastMessage');
const createFolderModalEl = document.getElementById('createFolderModal');
const configJsonModalEl = document.getElementById('configJsonModal');
const configJsonTextEl = document.getElementById('configJsonText');
const aiPasteModalEl = document.getElementById('aiPasteModal');
const aiDocTitleEl = document.getElementById('aiDocTitle');
const aiDocContentEl = document.getElementById('aiDocContent');
const markdownReaderModalEl = document.getElementById('markdownReaderModal');
const mdReaderTitleEl = document.getElementById('mdReaderTitle');
const mdReaderBodyEl = document.getElementById('mdReaderBody');
const pcAccessModalEl = document.getElementById('pcAccessModal');
const emojiPickerEl = document.getElementById('emojiPicker');
const colorPickerEl = document.getElementById('colorPicker');
const newFolderNameEl = document.getElementById('newFolderName');
const newFolderDescEl = document.getElementById('newFolderDesc');

function init() {
  saveToLocalStorage();
  renderHomeFolders();
  setupDropZone();
  buildPickers();
}

function saveToLocalStorage() {
  localStorage.setItem('folders_config_v3', JSON.stringify(state.folders));
}

function buildPickers() {
  emojiPickerEl.innerHTML = '';
  EMOJI_PALETTE.forEach((emoji) => {
    const btn = document.createElement('div');
    btn.className = `emoji-btn ${state.selectedEmoji === emoji ? 'selected' : ''}`;
    btn.textContent = emoji;
    btn.onclick = () => {
      state.selectedEmoji = emoji;
      buildPickers();
    };
    emojiPickerEl.appendChild(btn);
  });

  colorPickerEl.innerHTML = '';
  COLOR_PALETTE.forEach((c) => {
    const dot = document.createElement('div');
    dot.className = `color-circle ${state.selectedColor === c ? 'selected' : ''}`;
    dot.style.background = c;
    dot.onclick = () => {
      state.selectedColor = c;
      buildPickers();
    };
    colorPickerEl.appendChild(dot);
  });
}

function renderHomeFolders() {
  foldersListEl.innerHTML = '';
  state.folders.forEach((folder) => {
    const row = document.createElement('div');
    row.className = 'contact-row';
    row.onclick = () => openFolderChat(folder.id);

    const isUnread = folder.unreadCount > 0;
    const badgeHtml = isUnread
      ? `<span class="badge-counter">${folder.unreadCount}</span>`
      : `<span class="badge-counter muted">${folder.files.length}</span>`;

    row.innerHTML = `
      <div class="contact-avatar" style="background: ${folder.avatarBg}">${folder.avatarEmoji}</div>
      <div class="contact-info">
        <div class="contact-header">
          <div class="contact-name">${folder.name}</div>
          <div class="contact-time ${isUnread ? 'unread' : ''}">${folder.lastTimestamp}</div>
        </div>
        <div class="contact-details">
          <div class="contact-snippet">
            <svg width="15" height="15" viewBox="0 0 24 24" fill="none" stroke="${isUnread ? '#8696A0' : '#53BDEB'}" stroke-width="2.5">
              <polyline points="20 6 9 17 4 12"/>
            </svg>
            <span>${folder.description}</span>
          </div>
          ${badgeHtml}
        </div>
      </div>
    `;
    foldersListEl.appendChild(row);
  });
}

function renderOverlayContacts() {
  overlayContactsEl.innerHTML = '';
  state.folders.forEach((folder) => {
    const row = document.createElement('div');
    const isSelected = state.selectedOverlayFolderId === folder.id;
    row.className = `overlay-contact-row ${isSelected ? 'selected' : ''}`;
    row.onclick = () => selectOverlayFolder(folder.id);

    row.innerHTML = `
      <div class="contact-avatar" style="background: ${folder.avatarBg}; width: 44px; height: 44px; font-size: 20px;">${folder.avatarEmoji}</div>
      <div class="contact-info">
        <div class="contact-header">
          <div class="contact-name">${folder.name}</div>
          <div class="contact-time">${folder.files.length} items</div>
        </div>
        <div class="contact-snippet">
          <span>${folder.description}</span>
        </div>
      </div>
      ${isSelected ? '<span style="color: #00A884; font-size: 18px; font-weight: bold;">✓</span>' : ''}
    `;
    overlayContactsEl.appendChild(row);
  });
}

// Level 3: AI Text to .md feature
function openAiPasteModal() {
  aiDocTitleEl.value = 'AI_Insights_' + new Date().toISOString().slice(0, 10).replace(/-/g, '');
  aiDocContentEl.value = '';
  aiPasteModalEl.classList.add('active');
  setTimeout(() => aiDocContentEl.focus(), 150);
}

function closeAiPasteModal() {
  aiPasteModalEl.classList.remove('active');
}

function triggerAiPasteSimulation() {
  // Preset sample AI text from Claude/ChatGPT
  const sampleAiResponse = `# System Architecture: Conversational File Organizer\n\n## Overview\nThis architecture bypasses nested file trees by projecting directories as conversational WhatsApp contacts.\n\n### Key Principles\n1. **High velocity file routing**: Users share directly to contacts.\n2. **AI Markdown auto-formatter**: Plain text responses from AI assistants are stored as .md files.\n3. **Hardware independence**: Data syncs to Google Drive and is accessible via USB on PC.\n\n### Tech Stack\n- Flutter 3.47.7 & Android SDK 36\n- Markdown Parsing Engine\n- Portable JSON manifest registry`;

  aiDocTitleEl.value = 'AI_Architecture_Overview';
  aiDocContentEl.value = sampleAiResponse;
  aiPasteModalEl.classList.add('active');
}

function submitAiMarkdownDoc() {
  let title = aiDocTitleEl.value.trim() || 'AI_Note_' + Date.now();
  if (!title.toLowerCase().endsWith('.md')) {
    title += '.md';
  }
  const content = aiDocContentEl.value.trim() || '# ' + title + '\n\n*(Empty document)*';
  const sizeBytes = content.length;
  const sizeStr = (sizeBytes / 1024).toFixed(1) + ' KB';

  const newFile = {
    id: 'f_md_' + Date.now(),
    fileName: title,
    fileSize: sizeStr,
    type: 'md',
    time: formatCurrentTime(),
    content: content,
    isPinned: false,
  };

  closeAiPasteModal();

  // If in chat, save directly to this folder
  if (state.activeFolderId) {
    const folder = state.folders.find((f) => f.id === state.activeFolderId);
    if (folder) {
      folder.files.unshift(newFile);
      folder.lastTimestamp = 'Just now';
      saveToLocalStorage();
      renderChatMessages(folder);
      renderHomeFolders();
      showToast(`✓ Saved "${title}" to ${folder.name}`);
      return;
    }
  }

  // Otherwise trigger Share Overlay to pick folder
  state.pendingSharedFile = newFile;
  document.getElementById('interceptedName').textContent = title;
  document.getElementById('interceptedSize').textContent = `${sizeStr} • MARKDOWN`;
  document.getElementById('interceptedIconBox').textContent = '📄';
  document.getElementById('interceptedBadge').textContent = 'AI MARKDOWN DOC';

  state.selectedOverlayFolderId = null;
  sendBtnContainerEl.classList.remove('show');
  renderOverlayContacts();
  shareOverlayEl.classList.add('active');
}

// Markdown Reader
function openMarkdownReader(file) {
  state.currentViewingMarkdown = file;
  mdReaderTitleEl.textContent = file.fileName;

  // Simple clean markdown to HTML conversion
  const raw = file.content || `# ${file.fileName}\n\n*(Document content is empty or stored externally)*`;
  mdReaderBodyEl.innerHTML = parseSimpleMarkdown(raw);
  markdownReaderModalEl.classList.add('active');
}

function closeMarkdownReader() {
  markdownReaderModalEl.classList.remove('active');
  state.currentViewingMarkdown = null;
}

function copyMarkdownContent() {
  if (state.currentViewingMarkdown && state.currentViewingMarkdown.content) {
    navigator.clipboard.writeText(state.currentViewingMarkdown.content);
    showToast('✓ Markdown copied to clipboard');
  }
}

function parseSimpleMarkdown(md) {
  let html = md
    .replace(/^### (.*$)/gim, '<h3>$1</h3>')
    .replace(/^## (.*$)/gim, '<h2>$1</h2>')
    .replace(/^# (.*$)/gim, '<h1>$1</h1>')
    .replace(/^\> (.*$)/gim, '<blockquote>$1</blockquote>')
    .replace(/\*\*(.*)\*\*/gim, '<strong>$1</strong>')
    .replace(/\*(.*)\*/gim, '<em>$1</em>')
    .replace(/```([a-z]*)([\s\S]*?)```/gim, '<pre><code>$2</code></pre>')
    .replace(/`([^`]+)`/gim, '<code>$1</code>')
    .replace(/^\s*\n\*/gm, '<ul>\n*')
    .replace(/^(\*.+)\s*\n([^\*])/gm, '$1\n</ul>\n\n$2')
    .replace(/^\* (.+)/gm, '<li>$1</li>')
    .replace(/^\d+\. (.+)/gm, '<li>$1</li>')
    .replace(/\n\n/gim, '<br><br>');
  return html;
}

// Pin / Unpin (Level 3 Item 2)
function togglePinMessage(fileId) {
  if (!state.activeFolderId) return;
  const folder = state.folders.find((f) => f.id === state.activeFolderId);
  if (!folder) return;

  const file = folder.files.find((f) => f.id === fileId);
  if (!file) return;

  file.isPinned = !file.isPinned;
  saveToLocalStorage();
  renderChatMessages(folder);
  updatePinnedBanner(folder);
  showToast(file.isPinned ? `📌 Pinned "${file.fileName}"` : 'Unpinned');
}

function updatePinnedBanner(folder) {
  const pinned = folder.files.filter((f) => f.isPinned);
  if (pinned.length > 0) {
    pinnedTextEl.textContent = `Pinned: ${pinned[0].fileName}`;
    pinnedBannerEl.style.display = 'flex';
  } else {
    pinnedBannerEl.style.display = 'none';
  }
}

function openCurrentPinnedFile() {
  if (!state.activeFolderId) return;
  const folder = state.folders.find((f) => f.id === state.activeFolderId);
  if (!folder) return;
  const pinned = folder.files.find((f) => f.isPinned);
  if (pinned) {
    if (pinned.type === 'md') {
      openMarkdownReader(pinned);
    } else {
      showToast(`📌 Opening ${pinned.fileName}`);
    }
  }
}

function unpinCurrentFile() {
  if (!state.activeFolderId) return;
  const folder = state.folders.find((f) => f.id === state.activeFolderId);
  if (!folder) return;
  const pinned = folder.files.find((f) => f.isPinned);
  if (pinned) {
    pinned.isPinned = false;
    saveToLocalStorage();
    renderChatMessages(folder);
    updatePinnedBanner(folder);
    showToast('Unpinned');
  }
}

// Forward Message (Level 3 Item 3)
function forwardFile(fileId) {
  if (!state.activeFolderId) return;
  const folder = state.folders.find((f) => f.id === state.activeFolderId);
  if (!folder) return;

  const file = folder.files.find((f) => f.id === fileId);
  if (!file) return;

  state.isForwardMode = true;
  state.pendingSharedFile = { ...file, id: 'f_fwd_' + Date.now(), time: formatCurrentTime() };

  document.getElementById('interceptedName').textContent = file.fileName;
  document.getElementById('interceptedSize').textContent = `${file.fileSize} • FORWARD`;
  document.getElementById('interceptedIconBox').textContent = getCategoryEmoji(file.type);
  document.getElementById('interceptedBadge').textContent = 'FORWARD FILE';
  document.getElementById('shareOverlaySubtitle').textContent = 'Forward to another Folder Contact';

  state.selectedOverlayFolderId = null;
  sendBtnContainerEl.classList.remove('show');
  renderOverlayContacts();
  shareOverlayEl.classList.add('active');
}

// Share Intercept Flow
function triggerManualShare() {
  simulatePresetShare('Monthly_DESCO_Expense.pdf', 380000, 'pdf');
}

function handlePrototypeStorageFile(event) {
  const file = event.target.files[0];
  if (!file) return;
  const sizeBytes = file.size;
  const ext = file.name.split('.').pop().toLowerCase();
  let type = 'doc';
  if (['jpg', 'jpeg', 'png', 'webp'].includes(ext)) type = 'img';
  else if (['mp4', 'mov', 'mkv'].includes(ext)) type = 'video';
  else if (['mp3', 'm4a', 'wav'].includes(ext)) type = 'audio';
  else if (ext === 'pdf') type = 'pdf';
  else if (ext === 'md') type = 'md';

  simulatePresetShare(file.name, sizeBytes, type);
  event.target.value = '';
}

function addTagFromInput() {
  const input = document.getElementById('shareTagInput');
  let val = (input.value || '').trim();
  if (!val) return;
  if (!val.startsWith('#')) val = '#' + val;
  if (!state.activeTags.includes(val)) {
    state.activeTags.push(val);
    renderShareTags();
  }
  input.value = '';
}

function handleTagKey(e) {
  if (e.key === 'Enter') {
    e.preventDefault();
    addTagFromInput();
  }
}

function addPresetTag(t) {
  if (!state.activeTags.includes(t)) {
    state.activeTags.push(t);
    renderShareTags();
  }
}

function removeTag(t) {
  state.activeTags = state.activeTags.filter((item) => item !== t);
  renderShareTags();
}

function renderShareTags() {
  const container = document.getElementById('shareTagsChips');
  if (!container) return;
  const presets = ['#work', '#receipt', '#tax', '#important', '#bill'].filter((p) => !state.activeTags.includes(p));
  container.innerHTML = `
    ${state.activeTags.map((t) => `
      <span class="tag-chip">${t} <span class="remove-tag" onclick="removeTag('${t}')">✕</span></span>
    `).join('')}
    ${presets.map((p) => `
      <span class="tag-chip preset" onclick="addPresetTag('${p}')">${p}</span>
    `).join('')}
  `;
}

function simulatePresetShare(fileName, sizeBytes, type) {
  const sizeStr = (sizeBytes / (1024 * 1024)).toFixed(1) + ' MB';
  state.isForwardMode = false;
  state.activeTags = [];
  state.pendingSharedFile = {
    id: 'f_' + Date.now(),
    fileName,
    fileSize: sizeStr,
    type,
    time: formatCurrentTime(),
    isPinned: false,
  };

  const captionInput = document.getElementById('shareCaptionInput');
  if (captionInput) captionInput.value = '';
  renderShareTags();

  document.getElementById('interceptedName').textContent = fileName;
  document.getElementById('interceptedSize').textContent = `${sizeStr} • ${type.toUpperCase()}`;
  document.getElementById('interceptedIconBox').textContent = getCategoryEmoji(type);
  document.getElementById('interceptedBadge').textContent = 'INTERCEPTED FILE';
  document.getElementById('shareOverlaySubtitle').textContent = 'Select or create a Folder Contact';

  state.selectedOverlayFolderId = null;
  sendBtnContainerEl.classList.remove('show');

  renderOverlayContacts();
  shareOverlayEl.classList.add('active');
}

function selectOverlayFolder(folderId) {
  if (state.selectedOverlayFolderId === folderId) {
    state.selectedOverlayFolderId = null;
    sendBtnContainerEl.classList.remove('show');
  } else {
    state.selectedOverlayFolderId = folderId;
    const targetFolder = state.folders.find((f) => f.id === folderId);
    sendBtnLabelEl.textContent = state.isForwardMode ? `Forward to ${targetFolder.name}` : `Save to ${targetFolder.name}`;
    sendBtnContainerEl.classList.add('show');
  }
  renderOverlayContacts();
}

function confirmSendFile() {
  if (!state.selectedOverlayFolderId || !state.pendingSharedFile) return;

  const targetFolder = state.folders.find((f) => f.id === state.selectedOverlayFolderId);
  if (!targetFolder) return;

  const caption = document.getElementById('shareCaptionInput')?.value?.trim() || null;

  targetFolder.files.unshift({
    id: state.pendingSharedFile.id,
    fileName: state.pendingSharedFile.fileName,
    fileSize: state.pendingSharedFile.fileSize,
    type: state.pendingSharedFile.type,
    time: formatCurrentTime(),
    content: state.pendingSharedFile.content,
    caption: caption,
    tags: [...state.activeTags],
    isPinned: false,
  });
  targetFolder.unreadCount += 1;
  targetFolder.lastTimestamp = 'Just now';

  saveToLocalStorage();
  shareOverlayEl.classList.remove('active');

  const actionMsg = state.isForwardMode ? 'Forwarded to' : 'File sorted into';
  showToast(`✓ ${actionMsg} "${targetFolder.name}"`);
  openFolderChat(targetFolder.id);
  renderHomeFolders();
}

function closeShareOverlay() {
  shareOverlayEl.classList.remove('active');
  state.pendingSharedFile = null;
  state.selectedOverlayFolderId = null;
  state.isForwardMode = false;
}

// Create Folder Modal
function openCreateFolderModal(fromShare = false) {
  state.isOpenedFromShare = fromShare;
  newFolderNameEl.value = '';
  newFolderDescEl.value = '';
  createFolderModalEl.classList.add('active');
  setTimeout(() => newFolderNameEl.focus(), 100);
}

function closeCreateFolderModal() {
  createFolderModalEl.classList.remove('active');
}

function submitNewFolder() {
  const name = newFolderNameEl.value.trim();
  if (!name) return;

  const desc = newFolderDescEl.value.trim() || 'Custom folder';
  const newFolder = {
    id: 'f_' + Date.now(),
    name,
    description: desc,
    avatarEmoji: state.selectedEmoji,
    avatarBg: state.selectedColor,
    lastTimestamp: 'Just now',
    unreadCount: 0,
    files: [],
  };

  state.folders.unshift(newFolder);
  saveToLocalStorage();
  closeCreateFolderModal();

  renderHomeFolders();

  if (state.isOpenedFromShare && shareOverlayEl.classList.contains('active')) {
    selectOverlayFolder(newFolder.id);
    renderOverlayContacts();
    showToast(`✓ Folder "${name}" created & selected`);
  } else {
    showToast(`✓ Folder "${name}" added to folders_config.json`);
  }
}

// PC File Access Guide (Level 3 Item 4)
function openPcAccessModal() {
  pcAccessModalEl.classList.add('active');
}

function closePcAccessModal() {
  pcAccessModalEl.classList.remove('active');
}

// Configuration JSON Editor
function openConfigModal() {
  configJsonTextEl.value = JSON.stringify(state.folders, null, 2);
  configJsonModalEl.classList.add('active');
}

function closeConfigModal() {
  configJsonModalEl.classList.remove('active');
}

function saveConfigFromJsonText() {
  try {
    const parsed = JSON.parse(configJsonTextEl.value);
    if (Array.isArray(parsed)) {
      state.folders = parsed;
      saveToLocalStorage();
      renderHomeFolders();
      closeConfigModal();
      showToast('✓ folders_config.json updated & applied');
    } else {
      alert('Config must be a valid JSON array of folder objects.');
    }
  } catch (err) {
    alert('Invalid JSON formatting: ' + err.message);
  }
}

function exportBackupPackage() {
  const backupData = {
    app: 'FileOrganizer',
    version: '1.0.0',
    exportDate: new Date().toISOString(),
    config: state.folders,
  };
  const blob = new Blob([JSON.stringify(backupData, null, 2)], { type: 'application/json' });
  const url = URL.createObjectURL(blob);
  const a = document.createElement('a');
  a.href = url;
  a.download = `FileOrganizer_Backup_${Date.now()}.fo_backup`;
  document.body.appendChild(a);
  a.click();
  document.body.removeChild(a);
  URL.revokeObjectURL(url);
  showToast('✓ Backup file exported successfully');
}

// Folder Conversation / Chat
function openFolderChat(folderId) {
  state.activeFolderId = folderId;
  const folder = state.folders.find((f) => f.id === folderId);
  if (!folder) return;

  folder.unreadCount = 0;
  saveToLocalStorage();

  chatTitleEl.textContent = folder.name;
  chatSubtitleEl.textContent = `${folder.files.length} items • Active folder`;
  chatAvatarEl.textContent = folder.avatarEmoji;
  chatAvatarEl.style.background = folder.avatarBg;

  updatePinnedBanner(folder);
  renderChatMessages(folder);

  homeScreenEl.classList.remove('active');
  chatScreenEl.classList.add('active');
}

function renderChatMessages(folder) {
  chatMessagesEl.innerHTML = '';
  folder.files.forEach((file) => {
    const bubble = document.createElement('div');
    bubble.className = 'file-bubble';

    const isMd = file.type === 'md' || (file.fileName && file.fileName.endsWith('.md'));
    const isPinned = file.isPinned;

    const pinnedBadgeHtml = isPinned
      ? `<div class="bubble-pinned-badge"><span>📌</span> <span>PINNED</span></div>`
      : '';

    const captionHtml = (file.caption || file.note)
      ? `<div class="bubble-caption">${file.caption || file.note}</div>`
      : '';

    const tagsHtml = (file.tags && file.tags.length > 0)
      ? `<div class="bubble-tags">${file.tags.map((t) => `<span class="bubble-tag-pill">${t}</span>`).join('')}</div>`
      : '';

    bubble.innerHTML = `
      ${pinnedBadgeHtml}
      <div class="file-attachment-box" onclick="${isMd ? `openMarkdownReaderById('${file.id}')` : `openFileOpenerModalById('${file.id}')`}">
        <div class="f-icon">${getCategoryEmoji(file.type)}</div>
        <div class="f-info">
          <div class="f-title">${file.fileName}</div>
          <div class="f-size">${file.fileSize} • ${isMd ? 'MARKDOWN (Tap to read)' : `${file.type.toUpperCase()} (Tap to open)`}</div>
        </div>
        <span style="color: #00A884; font-size: 13px;">${isMd ? '📖' : '↗'}</span>
      </div>
      ${captionHtml}
      ${tagsHtml}
      <div class="bubble-actions-row">
        <button class="bubble-btn" onclick="togglePinMessage('${file.id}')">${isPinned ? 'Unpin' : '📌 Pin'}</button>
        <button class="bubble-btn" onclick="forwardFile('${file.id}')">↗️ Forward</button>
      </div>
      <div class="bubble-footer">
        <span>${file.time}</span>
        <span class="check-icon">✓✓</span>
      </div>
    `;
    chatMessagesEl.appendChild(bubble);
  });
}

function openMarkdownReaderById(fileId) {
  if (!state.activeFolderId) return;
  const folder = state.folders.find((f) => f.id === state.activeFolderId);
  if (!folder) return;
  const file = folder.files.find((f) => f.id === fileId);
  if (file) openMarkdownReader(file);
}

function closeChat() {
  chatScreenEl.classList.remove('active');
  homeScreenEl.classList.add('active');
  state.activeFolderId = null;
  renderHomeFolders();
}

function addNoteFromInput() {
  const text = noteInputEl.value.trim();
  if (!text || !state.activeFolderId) return;

  const folder = state.folders.find((f) => f.id === state.activeFolderId);
  if (!folder) return;

  folder.files.unshift({
    id: 'note_' + Date.now(),
    fileName: `Note - ${formatCurrentTime()}`,
    fileSize: `${text.length * 2} B`,
    type: 'doc',
    time: formatCurrentTime(),
    note: text,
    isPinned: false,
  });

  saveToLocalStorage();
  noteInputEl.value = '';
  renderChatMessages(folder);
  chatSubtitleEl.textContent = `${folder.files.length} items • Active folder`;
  renderHomeFolders();
}

function handleNoteKey(e) {
  if (e.key === 'Enter') {
    addNoteFromInput();
  }
}

function openFolderOptions() {
  showToast('📁 Folder options: Pin, Forward, or Add AI Notes');
}

function setupDropZone() {
  const dropZone = document.getElementById('dropZone');
  const fileInput = document.getElementById('fileInput');

  dropZone.onclick = () => fileInput.click();

  fileInput.onchange = (e) => {
    if (e.target.files && e.target.files[0]) {
      const f = e.target.files[0];
      const ext = f.name.split('.').pop() || 'doc';
      simulatePresetShare(f.name, f.size, ext);
    }
  };

  dropZone.ondragover = (e) => {
    e.preventDefault();
    dropZone.style.background = 'rgba(0, 168, 132, 0.2)';
  };

  dropZone.ondragleave = () => {
    dropZone.style.background = 'rgba(0, 168, 132, 0.05)';
  };

  dropZone.ondrop = (e) => {
    e.preventDefault();
    dropZone.style.background = 'rgba(0, 168, 132, 0.05)';
    if (e.dataTransfer.files && e.dataTransfer.files[0]) {
      const f = e.dataTransfer.files[0];
      const ext = f.name.split('.').pop() || 'doc';
      simulatePresetShare(f.name, f.size, ext);
    }
  };
}

function switchMainTab(tab) {
  if (tab === 'pc_access') {
    openPcAccessModal();
  }
}

function getCategoryEmoji(type) {
  switch ((type || '').toLowerCase()) {
    case 'md':
      return '📄';
    case 'pdf':
      return '📕';
    case 'img':
    case 'jpg':
    case 'png':
      return '🖼️';
    case 'video':
    case 'mp4':
      return '🎥';
    case 'audio':
    case 'm4a':
    case 'mp3':
      return '🎵';
    case 'doc':
    case 'docx':
      return '📝';
    default:
      return '📁';
  }
}

function formatCurrentTime() {
  const d = new Date();
  let hours = d.getHours();
  const minutes = d.getMinutes().toString().padStart(2, '0');
  const ampm = hours >= 12 ? 'PM' : 'AM';
  hours = hours % 12 || 12;
  return `${hours}:${minutes} ${ampm}`;
}

function showToast(msg) {
  toastMessageEl.textContent = msg;
  toastMessageEl.classList.add('show');
  setTimeout(() => {
    toastMessageEl.classList.remove('show');
  }, 2400);
}

function toggleTheme() {
  state.isDarkTheme = !state.isDarkTheme;
  const body = document.body;
  const themeBtn = document.getElementById('themeBtn');

  if (state.isDarkTheme) {
    body.className = 'dark-theme';
    themeBtn.textContent = '🌙 WhatsApp Dark';
  } else {
    body.className = 'light-theme';
    themeBtn.textContent = '☀️ WhatsApp Light';
  }
}

// Level 4: Central Search across ALL chats
let centralSearchFilter = 'All';

function openCentralSearchModal() {
  const modal = document.getElementById('centralSearchModal');
  const input = document.getElementById('centralSearchInput');
  modal.classList.add('active');
  input.value = '';
  centralSearchFilter = 'All';
  document.querySelectorAll('.search-filter-pills .pill').forEach((p, idx) => {
    p.classList.toggle('active', idx === 0);
  });
  handleCentralSearch();
  setTimeout(() => input.focus(), 150);
}

function closeCentralSearchModal() {
  document.getElementById('centralSearchModal').classList.remove('active');
}

function setCentralSearchFilter(filter, el) {
  centralSearchFilter = filter;
  document.querySelectorAll('.search-filter-pills .pill').forEach((p) => p.classList.remove('active'));
  el.classList.add('active');
  handleCentralSearch();
}

function handleCentralSearch() {
  const query = (document.getElementById('centralSearchInput').value || '').trim().toLowerCase();
  const resultsContainer = document.getElementById('centralSearchResults');
  const statsEl = document.getElementById('searchResultsStats');

  const matches = [];

  state.folders.forEach((folder) => {
    folder.files.forEach((file) => {
      // Category filter
      const isMd = file.type === 'md' || (file.fileName && file.fileName.endsWith('.md'));
      const isMedia = file.type === 'img' || file.type === 'video' || file.type === 'png' || file.type === 'jpg';
      const isDoc = !isMd && !isMedia;

      if (centralSearchFilter === 'Docs' && !isDoc) return;
      if (centralSearchFilter === 'Media' && !isMedia) return;
      if (centralSearchFilter === 'Notes' && !isMd) return;
      if (centralSearchFilter === 'Pinned' && !file.isPinned) return;

      // Query filter
      if (!query) {
        if (centralSearchFilter !== 'All') {
          matches.push({ folder, file });
        }
      } else {
        const inName = file.fileName.toLowerCase().includes(query);
        const inFolder = folder.name.toLowerCase().includes(query);
        const inContent = file.content && file.content.toLowerCase().includes(query);
        const inCaption = file.caption && file.caption.toLowerCase().includes(query);
        const inNote = file.note && file.note.toLowerCase().includes(query);
        const inTags = file.tags && file.tags.some((t) => t.toLowerCase().includes(query) || t.toLowerCase().replace('#', '').includes(query));

        if (inName || inFolder || inContent || inCaption || inNote || inTags) {
          matches.push({ folder, file });
        }
      }
    });
  });

  statsEl.textContent = query || centralSearchFilter !== 'All'
    ? `Found ${matches.length} item${matches.length === 1 ? '' : 's'} across ${state.folders.length} folder chats`
    : `Showing all items across ${state.folders.length} folder chats`;

  if (matches.length === 0) {
    resultsContainer.innerHTML = `
      <div style="text-align: center; padding: 30px; color: #8696A0;">
        <div style="font-size: 36px; margin-bottom: 8px;">🔍</div>
        <p style="font-size: 14px; font-weight: bold;">No matching files found</p>
        <p style="font-size: 12px; margin-top: 4px;">Try searching by file name, caption, tags (e.g. #receipt), or keywords inside notes.</p>
      </div>
    `;
    return;
  }

  resultsContainer.innerHTML = '';
  matches.forEach(({ folder, file }) => {
    const isMd = file.type === 'md' || (file.fileName && file.fileName.endsWith('.md'));
    const card = document.createElement('div');
    card.className = 'search-result-card';
    card.onclick = () => {
      closeCentralSearchModal();
      openFolderChat(folder.id);
    };

    const tagsHtml = (file.tags && file.tags.length > 0)
      ? `<div style="margin-top: 3px;">${file.tags.map((t) => `<span class="bubble-tag-pill" style="font-size:9px; padding:1px 4px;">${t}</span>`).join(' ')}</div>`
      : '';

    card.innerHTML = `
      <div style="font-size: 26px;">${getCategoryEmoji(file.type)}</div>
      <div style="flex: 1; min-width: 0;">
        <div style="display: flex; align-items: center; justify-content: space-between;">
          <strong style="font-size: 13.5px; white-space: nowrap; overflow: hidden; text-overflow: ellipsis; display: block;">${file.fileName}</strong>
          ${file.isPinned ? '<span class="pinned-tag-mini">📌 PINNED</span>' : ''}
        </div>
        <div style="display: flex; align-items: center; gap: 8px; margin-top: 3px;">
          <span class="search-location-chip" style="color: ${folder.avatarBg};">${folder.avatarEmoji} ${folder.name}</span>
          <span style="font-size: 11px; color: #8696A0;">${file.fileSize} • ${file.time}</span>
        </div>
        ${file.caption ? `<div style="font-size: 11px; color: #00A884; margin-top: 2px;">💬 ${file.caption}</div>` : ''}
        ${tagsHtml}
      </div>
      <button class="bubble-btn" style="padding: 4px 8px;" onclick="event.stopPropagation(); ${isMd ? `openMarkdownReaderById('${file.id}')` : `openFileOpenerModalById('${file.id}')`}">Open</button>
    `;
    resultsContainer.appendChild(card);
  });
}

// Level 4: Chat Media, Docs & Notes 3-Dots Filter
let currentMediaTab = 'media';

function openChatMediaModal() {
  if (!state.activeFolderId) return;
  const folder = state.folders.find((f) => f.id === state.activeFolderId);
  if (!folder) return;

  document.getElementById('chatMediaTitle').textContent = `${folder.name} — Media & Docs`;
  document.getElementById('chatMediaSubtitle').textContent = `${folder.files.length} total files in this folder contact`;
  document.getElementById('chatMediaModal').classList.add('active');
  switchMediaTab('media');
}

function closeChatMediaModal() {
  document.getElementById('chatMediaModal').classList.remove('active');
}

function switchMediaTab(tab) {
  currentMediaTab = tab;
  if (!state.activeFolderId) return;
  const folder = state.folders.find((f) => f.id === state.activeFolderId);
  if (!folder) return;

  const mediaFiles = folder.files.filter((f) => f.type === 'img' || f.type === 'video' || f.type === 'png' || f.type === 'jpg');
  const docFiles = folder.files.filter((f) => f.type !== 'img' && f.type !== 'video' && f.type !== 'png' && f.type !== 'jpg' && f.type !== 'md');
  const noteFiles = folder.files.filter((f) => f.type === 'md' || (f.fileName && f.fileName.endsWith('.md')));

  document.getElementById('tabMediaBtn').textContent = `MEDIA (${mediaFiles.length})`;
  document.getElementById('tabDocsBtn').textContent = `DOCS (${docFiles.length})`;
  document.getElementById('tabNotesBtn').textContent = `AI NOTES (${noteFiles.length})`;

  document.querySelectorAll('.media-tab').forEach((b) => b.classList.remove('active'));
  if (tab === 'media') document.getElementById('tabMediaBtn').classList.add('active');
  if (tab === 'docs') document.getElementById('tabDocsBtn').classList.add('active');
  if (tab === 'notes') document.getElementById('tabNotesBtn').classList.add('active');

  const contentEl = document.getElementById('chatMediaContent');

  if (tab === 'media') {
    if (mediaFiles.length === 0) {
      contentEl.innerHTML = '<p style="text-align: center; color: #8696A0; padding: 24px;">No media files (photos/videos) shared in this chat yet.</p>';
      return;
    }
    contentEl.innerHTML = `<div class="media-grid">${mediaFiles.map((f) => `
      <div class="media-grid-item" onclick="openFileOpenerModalById('${f.id}')">
        <span>${getCategoryEmoji(f.type)}</span>
        <span style="font-size: 10px; color: #8696A0; margin-top: 4px;">${f.fileSize}</span>
        ${f.isPinned ? '<span style="position: absolute; top: 4px; right: 4px; font-size: 10px;">📌</span>' : ''}
      </div>
    `).join('')}</div>`;
  } else if (tab === 'docs') {
    if (docFiles.length === 0) {
      contentEl.innerHTML = '<p style="text-align: center; color: #8696A0; padding: 24px;">No documents (PDFs/Office) shared in this chat yet.</p>';
      return;
    }
    contentEl.innerHTML = docFiles.map((f) => `
      <div class="search-result-card" onclick="openFileOpenerModalById('${f.id}')">
        <div style="font-size: 24px;">${getCategoryEmoji(f.type)}</div>
        <div style="flex: 1;">
          <strong>${f.fileName}</strong>
          <div style="font-size: 11px; color: #8696A0; margin-top: 2px;">${f.fileSize} • ${f.time}</div>
        </div>
        <button class="bubble-btn">Open</button>
      </div>
    `).join('');
  } else if (tab === 'notes') {
    if (noteFiles.length === 0) {
      contentEl.innerHTML = '<p style="text-align: center; color: #8696A0; padding: 24px;">No AI Markdown notes saved in this chat yet.</p>';
      return;
    }
    contentEl.innerHTML = noteFiles.map((f) => `
      <div class="search-result-card" onclick="openMarkdownReaderById('${f.id}')">
        <div style="font-size: 24px;">📝</div>
        <div style="flex: 1;">
          <strong>${f.fileName}</strong>
          <div style="font-size: 11px; color: #8696A0; margin-top: 2px;">${f.fileSize} • Tap to Read</div>
        </div>
        <button class="bubble-btn" style="color: #00A884;">Read .md</button>
      </div>
    `).join('');
  }
}

// Level 5 (v1.3): Android System App Chooser Modal
let activeFileToOpen = null;

function openFileOpenerModalById(fileId) {
  let found = null;
  state.folders.forEach((f) => {
    const match = f.files.find((item) => item.id === fileId);
    if (match) found = match;
  });

  if (!found) return;
  activeFileToOpen = found;

  document.getElementById('fileOpenerName').textContent = found.fileName;
  document.getElementById('fileOpenerMeta').textContent = `${found.fileSize} • ${found.type.toUpperCase()}`;
  document.getElementById('fileOpenerIcon').textContent = getCategoryEmoji(found.type);

  let apps = [];
  if (found.type === 'pdf') {
    apps = [
      { name: 'Adobe Acrobat Reader', desc: 'Default PDF Viewer', icon: '📕' },
      { name: 'Google Drive PDF Viewer', desc: 'Google LLC', icon: '🔺' },
      { name: 'Microsoft 365 (Office)', desc: 'View & annotate documents', icon: '📊' },
      { name: 'Files by Google', desc: 'System file manager', icon: '📁' },
    ];
  } else if (found.type === 'img' || found.type === 'jpg' || found.type === 'png') {
    apps = [
      { name: 'Google Photos', desc: 'Default photo viewer', icon: '🖼️' },
      { name: 'Samsung Gallery', desc: 'System photo app', icon: '🌄' },
      { name: 'Snapseed', desc: 'Photo editor', icon: '🍃' },
      { name: 'Files by Google', desc: 'System file manager', icon: '📁' },
    ];
  } else if (found.type === 'video') {
    apps = [
      { name: 'VLC for Android', desc: 'All format media player', icon: '🎬' },
      { name: 'Google Photos Video', desc: 'System video player', icon: '📽️' },
      { name: 'MX Player', desc: 'High performance player', icon: '▶️' },
    ];
  } else {
    apps = [
      { name: 'Microsoft 365 / Word', desc: 'Word processor & reader', icon: '📘' },
      { name: 'Google Docs', desc: 'Google LLC', icon: '📄' },
      { name: 'WPS Office', desc: 'Document suite', icon: '📑' },
      { name: 'Files by Google', desc: 'System file manager', icon: '📁' },
    ];
  }

  state.selectedApp = apps[0].name;
  const listEl = document.getElementById('appChooserList');
  listEl.innerHTML = apps.map((app, idx) => `
    <div class="app-chooser-item ${idx === 0 ? 'selected' : ''}" onclick="selectAppChooser(this, '${app.name}')">
      <div class="app-icon-img">${app.icon}</div>
      <div class="app-info">
        <div class="app-info-title">${app.name}</div>
        <div class="app-info-desc">${app.desc}</div>
      </div>
    </div>
  `).join('');

  document.getElementById('fileOpenerModal').classList.add('active');
}

function selectAppChooser(el, appName) {
  document.querySelectorAll('.app-chooser-item').forEach((item) => item.classList.remove('selected'));
  el.classList.add('selected');
  state.selectedApp = appName;
}

function closeFileOpenerModal() {
  document.getElementById('fileOpenerModal').classList.remove('active');
  activeFileToOpen = null;
}

function simulateAppOpen(choice) {
  if (!activeFileToOpen) return;
  const app = state.selectedApp || 'Selected App';
  const fileName = activeFileToOpen.fileName;
  closeFileOpenerModal();
  showToast(`🚀 Opened "${fileName}" with ${app} (${choice})`);
}

// Level 5 (v1.3): Delete Folder Contact & Contents
function openFolderOptions() {
  if (!state.activeFolderId) return;
  const folder = state.folders.find((f) => f.id === state.activeFolderId);
  if (!folder) return;

  const opt = confirm(
    `Folder: "${folder.name}" (${folder.files.length} items)\n\n` +
    `• Click OK to view Media, Docs & Notes\n` +
    `• Click Cancel to Delete this Folder Contact & all its files`
  );

  if (opt) {
    openChatMediaModal();
  } else {
    const confirmDel = confirm(
      `⚠️ PERMANENT DELETION:\n\nAre you sure you want to delete folder contact "${folder.name}" along with all its ${folder.files.length} files and contents?`
    );
    if (confirmDel) {
      state.folders = state.folders.filter((f) => f.id !== folder.id);
      saveToLocalStorage();
      closeChat();
      renderHomeFolders();
      showToast(`🗑️ Deleted folder "${folder.name}" and all contents`);
    }
  }
}

// Level 5 (v1.3): Check for Updates via GitHub
function openUpdateModal() {
  const modal = document.getElementById('updateModal');
  const body = document.getElementById('updateModalBody');
  modal.classList.add('active');
  body.innerHTML = `
    <div style="display:flex; align-items:center; gap:12px; margin-bottom:14px;">
      <div style="width:44px; height:44px; border-radius:50%; background:rgba(0,168,132,0.2); display:flex; align-items:center; justify-content:center; font-size:22px;">🚀</div>
      <div>
        <h4 style="margin:0; font-size:16px;">File Organizer v1.3.0</h4>
        <div style="font-size:12px; color:#8696A0;">Connected to personal GitHub releases</div>
      </div>
    </div>
    <div style="background:#202C33; padding:12px; border-radius:8px; font-size:12.5px; line-height:1.4; margin-bottom:12px;">
      <strong>✓ Current Version:</strong> 1.3.0 (Installed)<br>
      <strong>✓ Personal GitHub Repo:</strong> <code>github.com/srirajon/FileOrganizer</code><br>
      <strong>✓ Status:</strong> You are using the latest version!
    </div>
    <div style="border-top: 1px solid rgba(255,255,255,0.08); padding-top:10px; font-size:12px;">
      <strong>How to publish new APK releases to your GitHub:</strong>
      <ol style="padding-left:18px; margin-top:6px; color:#8696A0; line-height:1.5;">
        <li>Create repository on github.com (e.g. <code>FileOrganizer</code>)</li>
        <li>Click <strong>Releases</strong> → <strong>Draft a new release</strong></li>
        <li>Type tag <code>v1.4.0</code> and title <code>File Organizer v1.4.0</code></li>
        <li>Attach the compiled APK binary file into release assets</li>
        <li>Click <strong>Publish Release</strong> — the app checks and updates automatically!</li>
      </ol>
    </div>
  `;
}

function closeUpdateModal() {
  document.getElementById('updateModal').classList.remove('active');
}

function triggerUpdateAction() {
  closeUpdateModal();
  showToast('✓ Check for updates: You are running the latest v1.3.0');
}

init();

