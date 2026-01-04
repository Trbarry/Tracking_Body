/**
 * VOLUME_CONTROL_CENTER - CLOUD_SYNC_EDITION
 * Logic: Supabase REST API + Session-based Admin Lock
 */

const SUPABASE_URL = 'https://pvcvpqhcyezcmlsgrnhl.supabase.co';
const SUPABASE_KEY = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InB2Y3ZwcWhjeWV6Y21sc2dybmhsIiwicm9sZSI6ImFub24iLCJpYXQiOjE3Njc1Mzc4MDMsImV4cCI6MjA4MzExMzgwM30.8MkCQ_2uoW5CbjdOhidpomaDna47sZbzYzbPn_xVBzQ';

let isAdmin = sessionStorage.getItem('isAdmin') === 'true';
let currentProgram = {};

// --- INITIALISATION ---
async function initVolumeManager() {
    await fetchFromCloud();
    renderMatrix();
    updateStats();
}

// --- CLOUD_OPERATIONS (CRUD) ---
async function fetchFromCloud() {
    try {
        const response = await fetch(`${SUPABASE_URL}/rest/v1/volume_progression?select=*&order=id.asc`, {
            headers: { "apikey": SUPABASE_KEY, "Authorization": `Bearer ${SUPABASE_KEY}` }
        });
        const data = await response.json();
        
        // Transformation du format tableau en objet pour le JS
        data.forEach(row => {
            currentProgram[row.day_name] = { sets: row.sets_count };
        });
        console.log("[CLOUD] Sync successful.");
    } catch (e) {
        console.error("[CLOUD] Sync failed, check API keys.");
    }
}

async function updateCloud(day, newValue) {
    if (!isAdmin) return;

    await fetch(`${SUPABASE_URL}/rest/v1/volume_progression?day_name=eq.${day}`, {
        method: 'PATCH',
        headers: { 
            "apikey": SUPABASE_KEY, 
            "Authorization": `Bearer ${SUPABASE_KEY}`,
            "Content-Type": "application/json"
        },
        body: JSON.stringify({ sets_count: parseInt(newValue), updated_at: new Date() })
    });
}

// --- UI_MANAGEMENT ---
function unlockAdmin() {
    const pass = prompt("Enter ACCESS_KEY :");
    if (pass === "MODE PROF") { 
        isAdmin = true;
        sessionStorage.setItem('isAdmin', 'true');
        location.reload(); // Refresh pour activer les sliders
    } else {
        alert("ACCESS_DENIED");
    }
}

function renderMatrix() {
    const container = document.getElementById('matrix-container');
    container.innerHTML = '';

    Object.keys(currentProgram).forEach(day => {
        const dayData = currentProgram[day];
        const dayRow = document.createElement('div');
        dayRow.className = `volume-row ${!isAdmin ? 'locked-row' : ''}`;
        
        dayRow.innerHTML = `
            <span class="day-label">${day}</span>
            <input type="range" min="0" max="30" value="${dayData.sets}" 
                   ${!isAdmin ? 'disabled' : ''} 
                   oninput="this.nextElementSibling.innerText = this.value + ' sets'"
                   onchange="updateVolume('${day}', this.value)">
            <span class="sets-count">${dayData.sets} sets</span>
        `;
        container.appendChild(dayRow);
    });
}

async function updateVolume(day, newValue) {
    currentProgram[day].sets = parseInt(newValue);
    updateStats();
    await updateCloud(day, newValue);
}

function updateStats() {
    const total = Object.values(currentProgram).reduce((sum, d) => sum + d.sets, 0);
    document.getElementById('total-weekly-sets').innerText = total;
    
    // Recovery Logic
    const statusEl = document.getElementById('recovery-status');
    if (total > 85) { statusEl.innerText = "OVERLOAD_RISK"; statusEl.style.color = "#f85149"; }
    else { statusEl.innerText = "OPTIMAL"; statusEl.style.color = "#3fb950"; }
}

document.addEventListener('DOMContentLoaded', initVolumeManager);