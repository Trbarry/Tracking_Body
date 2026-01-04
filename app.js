/**
 * PERFORMANCE_MIRROR - CORE_LOGIC_V2.5
 * Author: Tristan Barry
 * Purpose: Data Parsing, Biometric KPIs, and Predictive Analytics
 */

// Configuration des objectifs (Pragmatic Tuning)
const STEP_GOAL_DAILY = 12000; // Ton objectif de pas quotidien

// --- HELPER_FUNCTIONS ---

/**
 * Transforme "jeudi 17 juillet 2025" en objet Date JS
 * Gère les spécificités de l'encodage français (ex: août)
 */
function parseFrenchDate(dateStr) {
    const months = {
        "janvier": 0, "février": 1, "mars": 2, "avril": 3, "mai": 4, "juin": 5,
        "juillet": 6, "août": 7, "septembre": 8, "octobre": 9, "novembre": 10, "décembre": 11
    };
    // Nettoyage et normalisation de la chaîne
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
        document.getElementById('days-count').innerText = realDayCount;

        // --- 2. BIOMÉTRIE & TENDANCES (Poids) ---
        const currentPDC = parseFloat(lastEntry.PDC);
        const startPDC = parseFloat(firstEntry.PDC);
        document.getElementById('current-weight').innerText = currentPDC.toFixed(1);

        const totalDelta = currentPDC - startPDC;
        const diffEl = document.getElementById('total-diff');
        diffEl.innerText = (totalDelta > 0 ? '+' : '') + totalDelta.toFixed(2);
        
        // Logique de Trend Detection (Analyse de dérive)
        const trendEl = document.getElementById('weight-trend');
        if (totalDelta < 0) {
            trendEl.innerText = "📉 WEIGHT_LOSS_DETECTION";
            trendEl.style.color = "var(--vol-opti)";
        } else if (totalDelta > 0) {
            trendEl.innerText = "📈 WEIGHT_GAIN_DETECTION";
            trendEl.style.color = "var(--danger)";
        } else {
            trendEl.innerText = "⚖️ STABLE_MAINTENANCE";
        }

        // --- 3. ANALYSE DE L'ACTIVITÉ (Steps) ---
        // Multiplication par 7 car summary.json semble agréger par semaine
        const totalStepsArchived = data.reduce((sum, d) => sum + (parseFloat(d.PAS) || 0), 0) * 7;
        const avgStepsPerDay = totalStepsArchived / realDayCount;
        
        document.getElementById('total-steps').innerText = Math.round(totalStepsArchived).toLocaleString();
        document.getElementById('avg-steps').innerText = Math.round(avgStepsPerDay).toLocaleString();
        document.getElementById('year-steps').innerText = ((avgStepsPerDay * 365) / 1000000).toFixed(2);
        
        // Mise à jour de la barre de progression des pas
        const stepPercent = Math.min((avgStepsPerDay / STEP_GOAL_DAILY) * 100, 100);
        const stepBar = document.getElementById('step-goal-bar');
        if (stepBar) stepBar.style.width = stepPercent + "%";

        // --- 4. MÉTABOLISME & PHASES ---
        const phaseName = lastEntry.PHASE.toUpperCase();
        const phaseEl = document.getElementById('current-phase');
        phaseEl.innerText = phaseName;
        // Mapping dynamique des classes CSS selon la phase
        phaseEl.className = `phase-tag phase-${lastEntry.PHASE.toLowerCase().replace(' ', '-')}`;

        // Calcul du TDEE Prédictif (Basé sur Delta Poids vs Apport)
        const totalKcalDeficit = Math.abs(totalDelta) * 7700; // 1kg ~ 7700kcal
        const dailyDeficitFromWeight = totalKcalDeficit / realDayCount;
        const kcalEntries = data.filter(d => d.KCALS && d.KCALS > 0);
        const avgConsumed = kcalEntries.reduce((sum, d) => sum + d.KCALS, 0) / kcalEntries.length;
        const estMaintenance = avgConsumed + (totalDelta < 0 ? dailyDeficitFromWeight : -dailyDeficitFromWeight);
        document.getElementById('est-maintenance').innerText = Math.round(estMaintenance);

        // --- 5. LOGS SYSTÈME (Terminal Simulation) ---
        const terminal = document.getElementById('terminal');
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

        // --- 6. DATA_VISUALIZATION (Chart.js Premium) ---
        renderCharts(data);

    } catch (error) {
        console.error("[CRITICAL_FAILURE] Trace:", error);
    }
}

/**
 * Configure et affiche les graphiques avec une esthétique Cyber-Neon
 */
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
        return p[1] + ' ' + p[2].substring(0, 3) + '.'; // Format court "17 juil."
    });

    // Chart Poids (Area Chart with Neon Gradient)
    const ctxWeight = document.getElementById('weightChart').getContext('2d');
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
                pointRadius: 0,
                pointHoverRadius: 5
            }]
        },
        options: chartOptions
    });

    // Chart Activité (Bar Chart)
    new Chart(document.getElementById('stepsChart'), {
        type: 'bar',
        data: {
            labels: dates,
            datasets: [{
                data: data.map(d => d.PAS),
                backgroundColor: 'rgba(162, 119, 255, 0.4)',
                borderRadius: 4,
                hoverBackgroundColor: '#a277ff'
            }]
        },
        options: chartOptions
    });
}

// Lancement à la fin du chargement du DOM
document.addEventListener('DOMContentLoaded', initDashboard);