// State
let subjects = JSON.parse(localStorage.getItem('attendance_subjects')) || [];
let settings = JSON.parse(localStorage.getItem('attendance_settings')) || { target: 75 };
let historyLog = JSON.parse(localStorage.getItem('attendance_history')) || [];
let isReorderMode = false; // New state

// DOM Elements
const subjectsList = document.getElementById('subjectsList');
const historyView = document.getElementById('historyView');
const addSubjectBtn = document.getElementById('addSubjectBtn');
const settingsBtn = document.getElementById('settingsBtn');
const addModal = document.getElementById('addModal');
const settingsModal = document.getElementById('settingsModal');
const editModal = document.getElementById('editModal'); // New
const reorderBtn = document.getElementById('reorderBtn'); // New

// Init
function init() {
    render();
    sidebarInit();
    setupEventListeners();
}

function sidebarInit() {
    // Default to home
    switchTab('home');
}

// Global Tab Switcher
window.switchTab = (tab) => {
    const navHome = document.getElementById('navHome');
    const navHistory = document.getElementById('navHistory');
    const indicator = document.getElementById('navIndicator');

    if (tab === 'home') {
        subjectsList.classList.remove('hidden-view');
        historyView.classList.add('hidden-view');
        navHome.classList.add('active');
        navHistory.classList.remove('active');
        indicator.style.left = '10px';
        render();
    } else if (tab === 'history') {
        subjectsList.classList.add('hidden-view');
        historyView.classList.remove('hidden-view');
        navHome.classList.remove('active');
        navHistory.classList.add('active');
        indicator.style.left = '190px';
        renderHistory();
    }
};

function setupEventListeners() {
    // FAB/Nav Add -> Open Add Modal
    addSubjectBtn.addEventListener('click', () => {
        addModal.classList.remove('hidden');
        document.getElementById('subjectNameInput').value = '';
        setTimeout(() => document.getElementById('subjectNameInput').focus(), 100);
    });

    // Settings
    settingsBtn.addEventListener('click', () => {
        settingsModal.classList.remove('hidden');
        document.getElementById('targetInput').value = settings.target;
    });

    // Close Modals
    document.getElementById('cancelAdd').addEventListener('click', () => addModal.classList.add('hidden'));
    document.getElementById('confirmAdd').addEventListener('click', handleAddSubject);
    document.getElementById('cancelSettings').addEventListener('click', () => settingsModal.classList.add('hidden'));
    document.getElementById('saveSettings').addEventListener('click', handleSaveSettings);
    document.getElementById('cancelEdit').addEventListener('click', () => editModal.classList.add('hidden')); // New
    document.getElementById('saveEdit').addEventListener('click', handleSaveEdit); // New
    reorderBtn.addEventListener('click', () => {
        isReorderMode = !isReorderMode;
        reorderBtn.classList.toggle('active', isReorderMode);
        render();
    });

    // Outside click
    addModal.addEventListener('click', e => { if (e.target === addModal) addModal.classList.add('hidden'); });
    settingsModal.addEventListener('click', e => { if (e.target === settingsModal) settingsModal.classList.add('hidden'); });
    editModal.addEventListener('click', e => { if (e.target === editModal) editModal.classList.add('hidden'); }); // New
}

function saveData() {
    localStorage.setItem('attendance_subjects', JSON.stringify(subjects));
    localStorage.setItem('attendance_settings', JSON.stringify(settings));
    localStorage.setItem('attendance_history', JSON.stringify(historyLog));
    render();
}

function handleAddSubject() {
    const input = document.getElementById('subjectNameInput');
    const name = input.value.trim();
    if (!name) return;

    subjects.push({ id: Date.now(), name: name, present: 0, total: 0 });
    saveData();
    addModal.classList.add('hidden');
}

function handleSaveSettings() {
    const input = document.getElementById('targetInput');
    const val = parseInt(input.value);
    if (val && val > 0 && val <= 100) {
        settings.target = val;
        saveData();
        settingsModal.classList.add('hidden');
    }
}

// New: Open Edit Modal
function openEditModal(id) {
    const sub = subjects.find(s => s.id === id);
    if (!sub) return;

    document.getElementById('editSubjectId').value = sub.id;
    document.getElementById('editSubjectName').value = sub.name;
    document.getElementById('editPresent').value = sub.present;
    document.getElementById('editTotal').value = sub.total;

    editModal.classList.remove('hidden');
}

// New: Save Edit
function handleSaveEdit() {
    const id = parseInt(document.getElementById('editSubjectId').value);
    const newName = document.getElementById('editSubjectName').value.trim();
    const newPresent = parseInt(document.getElementById('editPresent').value);
    const newTotal = parseInt(document.getElementById('editTotal').value);

    // Basic Validation
    if (!newName || isNaN(newPresent) || isNaN(newTotal) || newPresent < 0 || newTotal < 0) {
        alert('Please enter valid numbers.');
        return;
    }
    if (newPresent > newTotal) {
        alert('Present classes cannot be greater than Total classes.');
        return;
    }

    const subIndex = subjects.findIndex(s => s.id === id);
    if (subIndex > -1) {
        const sub = subjects[subIndex];
        const oldName = sub.name; // Capture for history

        // Update values
        sub.name = newName;
        sub.present = newPresent;
        sub.total = newTotal;

        // Add to History
        historyLog.unshift({
            timestamp: Date.now(),
            subject: newName,
            status: 'edited' // Special status
        });
        if (historyLog.length > 100) historyLog = historyLog.slice(0, 100);

        saveData();
        editModal.classList.add('hidden');
        showToast('Updated Successfully');
    }
}

function handleUpdateAttendance(id, type) {
    const sub = subjects.find(s => s.id === id);
    if (!sub) return;

    if (type === 'present' || type === 'absent') {
        if (type === 'present') sub.present++;
        sub.total++;

        // Add to History
        historyLog.unshift({
            timestamp: Date.now(),
            subject: sub.name,
            status: type
        });
        // Keep logs sane (last 100)
        if (historyLog.length > 100) historyLog = historyLog.slice(0, 100);

    } else if (type === 'delete') {
        if (confirm('Delete ' + sub.name + '?')) {
            subjects = subjects.filter(s => s.id !== id);
        }
    }

    saveData();
}

window.app_move = (id, direction) => {
    const index = subjects.findIndex(s => s.id === id);
    if (index === -1) return;

    if (direction === 'up' && index > 0) {
        [subjects[index], subjects[index - 1]] = [subjects[index - 1], subjects[index]];
    } else if (direction === 'down' && index < subjects.length - 1) {
        [subjects[index], subjects[index + 1]] = [subjects[index + 1], subjects[index]];
    }

    saveData();
};

function calculateNeeded(present, total, target) {
    if (total === 0) {
        return { status: 'bad', msg: `Attend next 1 class to reach ${target}%`, skippable: 0 };
    }
    const current = (present / total) * 100;
    const T = target / 100;

    if (current >= target) {
        // Can bunk calculation: present / (total + x) >= T  => x <= (present / T) - total
        let skippable = Math.floor((present / T) - total);
        if (skippable < 0) skippable = 0;
        return {
            status: 'good',
            msg: skippable > 0 ? `You can bunk the next ${skippable} classes safely.` : "Don't miss the next class!",
            skippable: skippable
        };
    } else {
        // Must attend calculation: (present + x) / (total + x) >= T => x >= (T * total - present) / (1 - T)
        let needed = Math.ceil((T * total - present) / (1 - T));
        if (needed <= 0) needed = 0;
        return { status: 'bad', msg: `Attend next ${needed} classes to reach ${target}%`, skippable: 0 };
    }
}

function render() {
    // Header Stats
    document.getElementById('targetDisplay').textContent = settings.target + '%';
    const totalP = subjects.reduce((acc, s) => acc + s.present, 0);
    const totalC = subjects.reduce((acc, s) => acc + s.total, 0);
    const avg = totalC === 0 ? 0 : Math.round((totalP / totalC) * 100);
    const avgEl = document.getElementById('overallAvg');
    avgEl.textContent = avg + '%';
    avgEl.style.color = avg >= settings.target ? 'var(--success)' : 'var(--danger)';

    // Subject List
    subjectsList.innerHTML = '';

    subjects.forEach(sub => {
        const pct = sub.total === 0 ? 0 : Math.round((sub.present / sub.total) * 100);
        const calc = calculateNeeded(sub.present, sub.total, settings.target);
        const isGood = pct >= settings.target;

        const card = document.createElement('div');
        card.className = `subject-card ${isReorderMode ? 'reorder-active' : ''}`;
        card.innerHTML = `
            <div class="subject-header">
                <div class="header-left">
                    ${isReorderMode ? `
                        <div class="reorder-controls">
                            <button class="move-btn" onclick="app_move(${sub.id}, 'up')" ${subjects.indexOf(sub) === 0 ? 'disabled' : ''}>
                                <svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.5">
                                    <polyline points="18 15 12 9 6 15"></polyline>
                                </svg>
                            </button>
                            <button class="move-btn" onclick="app_move(${sub.id}, 'down')" ${subjects.indexOf(sub) === subjects.length - 1 ? 'disabled' : ''}>
                                <svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.5">
                                    <polyline points="6 9 12 15 18 9"></polyline>
                                </svg>
                            </button>
                        </div>
                    ` : ''}
                    <span class="subject-name">${sub.name}</span>
                </div>
                <div class="header-actions">
                     <button class="edit-btn" onclick="app_edit(${sub.id})">
                        <svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
                            <path d="M12 20h9"></path>
                            <path d="M16.5 3.5a2.121 2.121 0 0 1 3 3L7 19l-4 1 1-4L16.5 3.5z"></path>
                        </svg>
                    </button>
                    <button class="delete-btn" onclick="app_delete(${sub.id})">
                        <svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
                            <path d="M18 6L6 18M6 6l12 12"/>
                        </svg>
                    </button>
                </div>
            </div>
            <div class="progress-section">
                <div class="progress-bar-bg">
                    <div class="progress-bar-fill" style="width: ${pct}%; background-color: ${isGood ? 'var(--success)' : 'var(--danger)'}"></div>
                </div>
                <div class="stats-row">
                    <span>${sub.present} / ${sub.total} classes</span>
                    <span>${pct}%</span>
                </div>
                <div class="attendance-message ${calc.status === 'good' ? 'status-good' : 'status-bad'}">${calc.msg}</div>
            </div>
            <div class="actions-row ${isReorderMode ? 'hidden' : ''}">
                <button class="action-btn btn-present" onclick="app_present(${sub.id})">Present</button>
                <button class="action-btn btn-absent" onclick="app_absent(${sub.id})">Absent</button>
            </div>
        `;
        subjectsList.appendChild(card);
    });
}

function renderHistory() {
    historyView.innerHTML = '';

    if (historyLog.length === 0) {
        historyView.innerHTML = '<div style="text-align:center; color:var(--text-secondary); padding:40px;">No history yet.</div>';
        return;
    }

    historyLog.forEach(item => {
        const date = new Date(item.timestamp);
        const dateStr = date.toLocaleDateString() + ' ' + date.toLocaleTimeString([], { hour: '2-digit', minute: '2-digit' });

        let statusClass = '';
        let statusText = item.status.toUpperCase();

        if (item.status === 'present') statusClass = 'h-present';
        else if (item.status === 'absent') statusClass = 'h-absent';
        else if (item.status === 'edited') statusClass = 'h-edited'; // New style needed

        const el = document.createElement('div');
        el.className = 'history-item';
        el.innerHTML = `
            <div class="h-left">
                <span class="h-subject">${item.subject}</span>
                <span class="h-time">${dateStr}</span>
            </div>
            <div class="h-status ${statusClass}">
                ${statusText}
            </div>
        `;
        historyView.appendChild(el);
    });
}

// Global Exports
window.app_present = (id) => handleUpdateAttendance(id, 'present');
window.app_absent = (id) => handleUpdateAttendance(id, 'absent');
window.app_delete = (id) => handleUpdateAttendance(id, 'delete');
window.app_edit = (id) => openEditModal(id); // New

// Offline Support
if ('serviceWorker' in navigator) {
    navigator.serviceWorker.register('sw.js')
        .then(() => showToast('Offline Ready 🟢'))
        .catch(err => console.log('SW Fail', err));
}

// Toast Function
function showToast(msg) {
    // Create toast element
    const toast = document.createElement('div');
    toast.className = 'toast';
    toast.innerHTML = `<span>${msg}</span>`;
    document.body.appendChild(toast);

    // Animate in
    setTimeout(() => toast.classList.add('toast-visible'), 100);

    // Animate out
    setTimeout(() => {
        toast.classList.remove('toast-visible');
        setTimeout(() => toast.remove(), 400);
    }, 3000);
}

init();
