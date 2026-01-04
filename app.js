/**
 * PERFORMANCE_MIRROR - CORE_LOGIC_V2.5
 * Author: Tristan Barry
 * Purpose: Data Parsing, Biometric KPIs, and Predictive Analytics
 * Features: Multi-device safety guards & Cyber-Neon UI
 */

// Configuration des objectifs (Pragmatic Tuning)
const STEP_GOAL_DAILY = 12000; 

// --- HELPER_FUNCTIONS ---

/**
 * Transforme "jeudi 17 juillet 2025" en objet Date JS
 */
function parseFrenchDate(dateStr) {
    const months = {
        "janvier": 0, "février": 1, "mars": 2, "avril": 3, "mai": 4, "juin": 5,
        "juillet": 6, "août": 7, "septembre": 8, "octobre": 9, "novembre": 10, "décembre": 11
    };
    const parts = dateStr.toLowerCase().replace('\u00fbt', 'ût').split(' '); 
    return new Date(parseInt(parts[3]), months[parts[2]], parseInt(parts[1]));
}

// --- CORE_DASHBOARD_ENGINE ---

async function initDashboard() {
    try {
        // Fetch des données traitées par le script Python
        const response = await fetch('./data/summary.json');
        const data = await response.json();
        
        if (!data || data.length === 0) {
            console.warn("[SYSTEM] Data array is empty. Check process_data.py.");
            return;
        }

        const firstEntry = data[0];
        const lastEntry = data[data.length - 1];

        // --- 1. ANALYSE TEMPORELLE (Uptime) ---
        const startDate = parseFrenchDate(firstEntry.Date);
        const endDate = parseFrenchDate(lastEntry.Date);
        const realDayCount = Math.ceil(Math.abs(endDate - startDate) / (1000 * 60 * 60 * 24)); 
        const uptimeEl = document.getElementById('days-count');
        if (uptimeEl) uptimeEl.innerText = realDayCount;

        // --- 2. BIOMÉTRIE & TENDANCES (Poids) ---
        const currentPDC = parseFloat(lastEntry.PDC);
        const startPDC = parseFloat(firstEntry.PDC);
        const weightEl = document.getElementById('current-weight');
        if (weightEl) weightEl.innerText = currentPDC.toFixed(1);

        const totalDelta = currentPDC - startPDC;
        const diffEl = document.getElementById('total-diff');
        if (diffEl) {
            diffEl.innerText = (totalDelta > 0 ? '+' : '') + totalDelta.toFixed(2);
            diffEl.style.color = totalDelta <= 0 ? 'var(--terminal-green)' : 'var(--danger)';
        }
        
        // Logique de Trend Detection (Analyse de dérive)
        const trendEl = document.getElementById('weight-trend');
        if (trendEl) {
            if (totalDelta < -0.5) {
                trendEl.innerText = "📉 WEIGHT_LOSS_DETECTION";
                trendEl.style.color = "var(--vol-opti)";
            } else if (totalDelta > 0.5) {
                trendEl.innerText = "📈 WEIGHT_GAIN_DETECTION";
                trendEl.style.color = "var(--danger)";
            } else {
                trendEl.innerText = "⚖️ STABLE_MAINTENANCE";
                trendEl.style.color = "var(--text-dim)";
            }
        }

        // --- 3. ANALYSE DE L'ACTIVITÉ (Steps) ---
        // Multiplication par 7 car summary.json agrège par semaine
        const totalStepsArchived = data.reduce((sum, d) => sum + (parseFloat(d.PAS) || 0), 0) * 7;
        const avgStepsPerDay = totalStepsArchived / realDayCount;
        
        const totalStepsEl = document.getElementById('total-steps');
        if (totalStepsEl) totalStepsEl.innerText = Math.round(totalStepsArchived).toLocaleString();
        
        const avgStepsEl = document.getElementById('avg-steps');
        if (avgStepsEl) avgStepsEl.innerText = Math.round(avgStepsPerDay).toLocaleString();
        
        const yearStepsEl = document.getElementById('year-steps');
        if (yearStepsEl) yearStepsEl.innerText = ((avgStepsPerDay * 365) / 1000000).toFixed(2);
        
        // Mise à jour de la barre de progression des pas
        const stepBar = document.getElementById('step-goal-bar');
        if (stepBar) {
            const stepPercent = Math.min((avgStepsPerDay / STEP_GOAL_DAILY) * 100, 100);
            stepBar.style.width = stepPercent + "%";
        }

        // --- 4. MÉTABOLISME & PHASES ---
        const phaseName = lastEntry.PHASE.toUpperCase();
        const phaseEl = document.getElementById('current-phase');
        if (phaseEl) {
            phaseEl.innerText = phaseName;
            phaseEl.className = `phase-tag phase-${lastEntry.PHASE.toLowerCase().replace(' ', '-')}`;
        }

        // Calcul du TDEE Prédictif (Basé sur Delta Poids vs Apport)
        const totalKcalDeficit = Math.abs(totalDelta) * 7700; 
        const dailyDeficitFromWeight = totalKcalDeficit / realDayCount;
        const kcalEntries = data.filter(d => d.KCALS && d.KCALS > 0);
        const avgConsumed = kcalEntries.reduce((sum, d) => sum + d.KCALS, 0) / kcalEntries.length;
        const estMaintenance = avgConsumed + (totalDelta < 0 ? dailyDeficitFromWeight : -dailyDeficitFromWeight);
        
        const maintEl = document.getElementById('est-maintenance');
        if (maintEl) maintEl.innerText = Math.round(estMaintenance);

        // --- 5. LOGS SYSTÈME (Terminal Simulation) ---
        const terminal = document.getElementById('terminal');
        if (terminal) {
            terminal.innerHTML = ''; // Reset prevent double logs
            const logs = [
                `[SYSTEM] Current Phase: ${phaseName}`,
                `[SYSTEM] Temporal drift: ${realDayCount} days tracked.`,
                `[MATH] Est. TDEE: ${Math.round(estMaintenance)} kcal.`,
                `[ACTIVITY] Daily Avg: ${Math.round(avgStepsPerDay)} steps.`
            ];
            logs.forEach((msg, i) => {
                setTimeout(() => {
                    const line = document.createElement('div');
                    line.className = 'log-line';
                    line.innerText = `> ${msg}`;
                    terminal.appendChild(line);
                    terminal.scrollTop = terminal.scrollHeight;
                }, i * 400);
            });
        }

        // --- 6. DATA_VISUALIZATION (Chart.js) ---
        renderCharts(data);

    } catch (error) {
        console.error("[CRITICAL_FAILURE] Trace:", error);
    }
}

function renderCharts(data) {
    const chartOptions = {
        responsive: true,
        maintainAspectRatio: false,
        plugins: { legend: { display: false } },
        scales: {
            y: { grid: { color: 'rgba(255, 255, 255, 0.05)' }, ticks: { color: '#8b949e', font: { family: 'JetBrains Mono' } } },
            x: { grid: { display: false }, ticks: { color: '#8b949e', font: { family: 'JetBrains Mono' } } }
        }
    };

    const dates = data.map(d => {
        const p = d.Date.split(' ');
        return p[1] + ' ' + p[2].substring(0, 3) + '.'; 
    });

    // Chart Poids
    const weightCanvas = document.getElementById('weightChart');
    if (weightCanvas) {
        const ctxWeight = weightCanvas.getContext('2d');
        const gradWeight = ctxWeight.createLinearGradient(0, 0, 0, 400);
        gradWeight.addColorStop(0, 'rgba(162, 119, 255, 0.3)');
        gradWeight.addColorStop(1, 'rgba(162, 119, 255, 0)');

        new Chart(ctxWeight, {
            type: 'line',
            data: {
                labels: dates,
                datasets: [{
                    data: data.map(d => d.PDC),
                    borderColor: '#a277ff',
                    backgroundColor: gradWeight,
                    borderWidth: 3,
                    fill: true,
                    tension: 0.4,
                    pointRadius: 0
                }]
            },
            options: chartOptions
        });
    }

    // Chart Activité
    const stepsCanvas = document.getElementById('stepsChart');
    if (stepsCanvas) {
        new Chart(stepsCanvas, {
            type: 'bar',
            data: {
                labels: dates,
                datasets: [{
                    data: data.map(d => d.PAS),
                    backgroundColor: 'rgba(162, 119, 255, 0.4)',
                    borderRadius: 4
                }]
            },
            options: chartOptions
        });
    }
}

document.addEventListener('DOMContentLoaded', initDashboard);