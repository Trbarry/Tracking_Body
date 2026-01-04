/**
 * VOLUME_CONTROL_CENTER - CLOUD_SYNC_EDITION (v1.3)
 * Logic: Weighted Volume (100% / 50% / 25%) + Bi-directional Sync
 */

const SUPABASE_URL = 'https://pvcvpqhcyezcmlsgrnhl.supabase.co';
const SUPABASE_KEY = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InB2Y3ZwcWhjeWV6Y21sc2dybmhsIiwicm9sZSI6ImFub24iLCJpYXQiOjE3Njc1Mzc4MDMsImV4cCI6MjA4MzExMzgwM30.8MkCQ_2uoW5CbjdOhidpomaDna47sZbzYzbPn_xVBzQ';

// Utilisation du client global Supabase
const supabaseClient = supabase.createClient(SUPABASE_URL, SUPABASE_KEY);

const MUSCLE_GROUPS = [
    "Pectoraux", "Trapèzes", "Grands dorsaux", "Deltoïdes antérieurs", 
    "Deltoïdes latéraux", "Deltoïdes postérieurs", "Triceps", "Biceps", 
    "Quadriceps", "Ischios", "Adducteurs", "Fessiers", "Lombaires", 
    "Abdominaux", "Mollets"
];

let isAdmin = sessionStorage.getItem('isAdmin') === 'true';
let cachedExercises = [];

async function initVolumeLab() {
    await fetchFromCloud();
    renderMuscleColumns(); // Remplace renderMatrix
    renderExercises();
    updateTotals();
}

// --- DATA_MANAGEMENT ---

async function fetchFromCloud() {
    const { data, error } = await supabaseClient
        .from('exercise_volume')
        .select('*')
        .order('id', { ascending: true });

    if (error) return console.error("[ERROR] Fetch failed:", error);
    cachedExercises = data;
    console.log("[CLOUD] Sync successful.");
}

async function updateCloud(id, payload) {
    if (!isAdmin) return;
    showSyncing(true);
    const { error } = await supabaseClient
        .from('exercise_volume')
        .update(payload)
        .eq('id', id);
    
    if (error) console.error("[ERROR] Sync failed:", error);
    showSyncing(false);
}

// --- UI_RENDERING ---

function renderMuscleColumns() {
    const grid = document.querySelector('.muscle-grid');
    if (!grid) return console.error("[ERROR] .muscle-grid non trouvée dans le HTML");

    grid.innerHTML = MUSCLE_GROUPS.map(muscle => `
        <div class="muscle-column" ondrop="drop(event)" ondragover="allowDrop(event)" data-muscle="${muscle}">
            <div class="muscle-header">
                <span>${muscle.toUpperCase()}</span>
                <span class="total-badge" id="total-${muscle}">0</span>
            </div>
            <div class="drop-zone"></div>
        </div>
    `).join('');
}

function renderExercises() {
    const bank = document.getElementById('exercise-bank');
    if (!bank) return;
    bank.innerHTML = ''; 

    cachedExercises.forEach(exo => {
        const card = document.createElement('div');
        card.className = `exo-card ${!isAdmin ? 'locked' : ''}`;
        card.id = `exo-${exo.id}`;
        card.draggable = isAdmin;
        card.ondragstart = (e) => e.dataTransfer.setData("text", e.target.id);

        const indicators = `
            <div class="target-indicators">
                <span class="dot p" title="Principal: ${exo.muscle_group}"></span>
                ${exo.muscle_medium ? `<span class="dot m" title="Moyen: ${exo.muscle_medium}"></span>` : ''}
                ${exo.muscle_secondary ? `<span class="dot s" title="Secondaire: ${exo.muscle_secondary}"></span>` : ''}
            </div>
        `;

        card.innerHTML = `
            <div class="exo-info">
                <div style="display:flex; flex-direction:column;">
                    <span class="exo-name">${exo.exercise_name}</span>
                    ${indicators}
                </div>
                <input type="number" class="sets-input" value="${exo.sets || 0}" 
                       ${!isAdmin ? 'disabled' : ''} 
                       onchange="updateSets(${exo.id}, this.value)">
            </div>
        `;

        const targetColumn = document.querySelector(`[data-muscle="${exo.muscle_group}"] .drop-zone`);
        if (targetColumn) targetColumn.appendChild(card);
        else bank.appendChild(card);
    });
}

// --- LOGIC_CORE ---

function updateTotals() {
    let globalWeeklySets = 0;

    MUSCLE_GROUPS.forEach(muscle => {
        let weightedVolume = 0;

        cachedExercises.forEach(exo => {
            const sets = parseInt(exo.sets) || 0;
            if (exo.muscle_group === muscle) {
                weightedVolume += sets;
                globalWeeklySets += sets;
            } else if (exo.muscle_medium === muscle) {
                weightedVolume += (sets * 0.5);
            } else if (exo.muscle_secondary === muscle) {
                weightedVolume += (sets * 0.25);
            }
        });

        const badge = document.getElementById(`total-${muscle}`);
        if (badge) {
            badge.innerText = weightedVolume % 1 === 0 ? weightedVolume : weightedVolume.toFixed(1);
            badge.style.opacity = weightedVolume > 0 ? "1" : "0.3";
        }
    });

    const totalEl = document.getElementById('total-weekly-sets');
    if (totalEl) totalEl.innerText = globalWeeklySets;
}

async function updateSets(id, newValue) {
    const val = parseInt(newValue) || 0;
    const exo = cachedExercises.find(e => e.id === id);
    if (exo) exo.sets = val;
    
    updateTotals();
    await updateCloud(id, { sets: val });
}

async function drop(ev) {
    ev.preventDefault();
    const dataId = ev.dataTransfer.getData("text");
    const muscle = ev.currentTarget.getAttribute('data-muscle');
    const id = parseInt(dataId.replace('exo-', ''));
    
    const exo = cachedExercises.find(e => e.id === id);
    if (exo) {
        exo.muscle_group = muscle;
        const targetDropZone = ev.currentTarget.querySelector('.drop-zone');
        targetDropZone.appendChild(document.getElementById(dataId));
        updateTotals();
        await updateCloud(id, { muscle_group: muscle });
    }
}

function unlockAdmin() {
    const pass = prompt("Enter ACCESS_KEY :");
    if (pass === "MODE PROF") { 
        isAdmin = true;
        sessionStorage.setItem('isAdmin', 'true');
        location.reload();
    } else { alert("ACCESS_DENIED"); }
}

function showSyncing(isSyncing) {
    const indicator = document.getElementById('sync-indicator');
    if (!indicator) return;
    indicator.innerText = isSyncing ? "● SYNCING..." : "● SYNC_READY";
    indicator.style.color = isSyncing ? "var(--warning)" : "var(--terminal-green)";
}

function allowDrop(ev) { ev.preventDefault(); }
document.addEventListener('DOMContentLoaded', initVolumeLab);