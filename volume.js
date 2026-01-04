/**
 * VOLUME_CONTROL_CENTER - CLOUD_SYNC_EDITION (v1.4)
 * Logic: Weighted Volume (100%/50%/25%) + Full Drag & Drop
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

let isAdmin = sessionStorage.getItem('isAdmin') === 'true';
let cachedExercises = [];

async function initVolumeLab() {
    await fetchFromCloud();
    renderMuscleColumns();
    renderExercises();
    updateTotals();
    setupBankDrop(); // Nouvelle fonction pour le drop dans la banque
}

async function fetchFromCloud() {
    const { data, error } = await supabaseClient.from('exercise_volume').select('*').order('id', { ascending: true });
    if (!error) {
        cachedExercises = data;
        console.log("[CLOUD] Sync successful.");
    }
}

function renderMuscleColumns() {
    const grid = document.querySelector('.muscle-grid');
    if (!grid) return;
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
        card.className = `exo-card ${!isAdmin ? 'locked' : 'draggable'}`;
        card.id = `exo-${exo.id}`;
        card.draggable = isAdmin; // Verrou si pas admin
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

        const targetColumn = document.querySelector(`[data-muscle="${exo.muscle_group}"] .drop-zone`);
        if (targetColumn && exo.muscle_group) targetColumn.appendChild(card);
        else bank.appendChild(card);
    });
}

function setupBankDrop() {
    const bank = document.getElementById('exercise-bank');
    bank.ondragover = (e) => e.preventDefault();
    bank.ondrop = async (e) => {
        e.preventDefault();
        const dataId = e.dataTransfer.getData("text");
        const id = parseInt(dataId.replace('exo-', ''));
        const exo = cachedExercises.find(ex => ex.id === id);
        if (exo && isAdmin) {
            exo.muscle_group = null;
            bank.appendChild(document.getElementById(dataId));
            updateTotals();
            await updateCloud(id, { muscle_group: null });
        }
    };
}

async function drop(ev) {
    ev.preventDefault();
    if (!isAdmin) return;
    const dataId = ev.dataTransfer.getData("text");
    const muscle = ev.currentTarget.getAttribute('data-muscle');
    const id = parseInt(dataId.replace('exo-', ''));
    
    const exo = cachedExercises.find(e => e.id === id);
    if (exo) {
        exo.muscle_group = muscle;
        ev.currentTarget.querySelector('.drop-zone').appendChild(document.getElementById(dataId));
        updateTotals();
        await updateCloud(id, { muscle_group: muscle });
    }
}

function updateTotals() {
    let globalTotal = 0;
    MUSCLE_GROUPS.forEach(muscle => {
        let weighted = 0;
        cachedExercises.forEach(exo => {
            const sets = parseInt(exo.sets) || 0;
            if (exo.muscle_group === muscle) { weighted += sets; globalTotal += sets; }
            else if (exo.muscle_medium === muscle) weighted += (sets * 0.5);
            else if (exo.muscle_secondary === muscle) weighted += (sets * 0.25);
        });
        const badge = document.getElementById(`total-${muscle}`);
        if (badge) badge.innerText = weighted % 1 === 0 ? weighted : weighted.toFixed(1);
    });
    document.getElementById('total-weekly-sets').innerText = globalTotal;
}

async function updateSets(id, newValue) {
    const val = parseInt(newValue) || 0;
    const exo = cachedExercises.find(e => e.id === id);
    if (exo) exo.sets = val;
    updateTotals();
    await updateCloud(id, { sets: val });
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