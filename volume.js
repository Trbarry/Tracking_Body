/**
 * VOLUME_CONTROL_CENTER - SESSION_PLANNER_EDITION
 * Logic: Weighted Volume (1.0 / 0.5 / 0.25) + Session Management
 */

const SUPABASE_URL = 'https://pvcvpqhcyezcmlsgrnhl.supabase.co';
const SUPABASE_KEY = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InB2Y3ZwcWhjeWV6Y21sc2dybmhsIiwicm9sZSI6ImFub24iLCJpYXQiOjE3Njc1Mzc4MDMsImV4cCI6MjA4MzExMzgwM30.8MkCQ_2uoW5CbjdOhidpomaDna47sZbzYzbPn_xVBzQ';

const supabaseClient = supabase.createClient(SUPABASE_URL, SUPABASE_KEY);

const MUSCLE_GROUPS = [
    "Pectoraux", "Trapèzes", "Grands dorsaux", "Deltoïdes antérieurs", 
    "Deltoïdes latéraux", "Deltoïdes postérieurs", "Triceps", "Biceps", 
    "Quadriceps", "Ischios", "Adducteurs", "Fessiers", "Lombaires", 
    "Abdominaux", "Mollets"
];

const SESSIONS = ['Upper A', 'Upper B', 'Legs'];
let isAdmin = sessionStorage.getItem('isAdmin') === 'true';
let cachedExercises = [];

async function initVolumeLab() {
    await fetchFromCloud();
    renderExercises();
    updateTotals();
}

// --- CLOUD OPS ---
async function fetchFromCloud() {
    const { data, error } = await supabaseClient.from('exercise_volume').select('*').order('id', { ascending: true });
    if (!error) {
        cachedExercises = data;
        console.log("[CLOUD] Sync successful.");
    }
}

async function updateCloud(id, payload) {
    if (!isAdmin) return;
    showSyncing(true);
    await supabaseClient.from('exercise_volume').update(payload).eq('id', id);
    showSyncing(false);
}

// --- UI RENDERING ---
function createExoCard(exo) {
    const card = document.createElement('div');
    card.className = `exo-card ${!isAdmin ? 'locked' : 'draggable'}`;
    card.id = `exo-${exo.id}`;
    card.draggable = isAdmin;
    card.ondragstart = (e) => e.dataTransfer.setData("text", e.target.id);

    card.innerHTML = `
        <div class="exo-info">
            <div style="display:flex; flex-direction:column;">
                <span class="exo-name">${exo.exercise_name}</span>
                <div class="target-indicators">
                    <span class="dot p" title="P: ${exo.muscle_group}"></span>
                    ${exo.muscle_medium ? `<span class="dot m" title="M: ${exo.muscle_medium}"></span>` : ''}
                    ${exo.muscle_secondary ? `<span class="dot s" title="S: ${exo.muscle_secondary}"></span>` : ''}
                </div>
            </div>
            <input type="number" class="sets-input" value="${exo.sets || 0}" 
                   ${!isAdmin ? 'disabled' : ''} 
                   onchange="updateSets(${exo.id}, this.value)">
        </div>
    `;
    return card;
}

function renderExercises() {
    document.querySelectorAll('.drop-zone').forEach(dz => dz.innerHTML = '');
    document.getElementById('exercise-bank').innerHTML = '';

    cachedExercises.forEach(exo => {
        const card = createExoCard(exo);
        if (exo.workout_session && SESSIONS.includes(exo.workout_session)) {
            const target = document.querySelector(`[data-session="${exo.workout_session}"] .drop-zone`);
            if (target) target.appendChild(card);
        } else {
            document.getElementById('exercise-bank').appendChild(card);
        }
    });
}

// --- CALCULS ---
function updateTotals() {
    let globalTotalSets = 0;
    const matrixContainer = document.getElementById('global-muscle-matrix');
    matrixContainer.innerHTML = '';

    MUSCLE_GROUPS.forEach(muscle => {
        let weightedVol = 0;

        cachedExercises.forEach(exo => {
            const s = parseInt(exo.sets) || 0;
            if (exo.muscle_group === muscle) { 
                weightedVol += s; 
                globalTotalSets += s;
            }
            else if (exo.muscle_medium === muscle) weightedVol += (s * 0.5);
            else if (exo.muscle_secondary === muscle) weightedVol += (s * 0.25);
        });

        if (weightedVol > 0) {
            const item = document.createElement('div');
            item.className = 'muscle-total-item';
            item.innerHTML = `
                <span class="m-name">${muscle}</span>
                <span class="m-val">${weightedVol % 1 === 0 ? weightedVol : weightedVol.toFixed(1)}</span>
            `;
            matrixContainer.appendChild(item);
        }
    });

    document.getElementById('total-weekly-sets').innerText = globalTotalSets;
    const statusEl = document.getElementById('recovery-status');
    statusEl.innerText = globalTotalSets > 85 ? "OVERLOAD_RISK" : "OPTIMAL";
    statusEl.style.color = globalTotalSets > 85 ? "#f85149" : "#3fb950";
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
    if (!isAdmin) return;
    const dataId = ev.dataTransfer.getData("text");
    const sessionName = ev.currentTarget.getAttribute('data-session');
    const id = parseInt(dataId.replace('exo-', ''));
    
    const exo = cachedExercises.find(e => e.id === id);
    if (exo) {
        exo.workout_session = (sessionName === "null") ? null : sessionName;
        const targetZone = (sessionName === "null") ? ev.currentTarget : ev.currentTarget.querySelector('.drop-zone');
        targetZone.appendChild(document.getElementById(dataId));
        updateTotals();
        await updateCloud(id, { workout_session: exo.workout_session });
    }
}

function unlockAdmin() {
    const pass = prompt("Enter ACCESS_KEY :");
    if (pass === "MODE PROF") { 
        sessionStorage.setItem('isAdmin', 'true');
        location.reload();
    } else { alert("ACCESS_DENIED"); }
}

function showSyncing(isSyncing) {
    const indicator = document.getElementById('sync-indicator');
    if (indicator) indicator.style.color = isSyncing ? "#dbab09" : "#3fb950";
}

function allowDrop(ev) { ev.preventDefault(); }
document.addEventListener('DOMContentLoaded', initVolumeLab);