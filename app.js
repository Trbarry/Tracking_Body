// Fonction pour transformer "jeudi 17 juillet 2025" en date JS
function parseFrenchDate(dateStr) {
    const months = {
        "janvier": 0, "février": 1, "mars": 2, "avril": 3, "mai": 4, "juin": 5,
        "juillet": 6, "août": 7, "septembre": 8, "octobre": 9, "novembre": 10, "décembre": 11
    };
    const p = dateStr.toLowerCase().replace('\u00fbt', 'ût').split(' '); 
    return new Date(parseInt(p[3]), months[p[2]], parseInt(p[1]));
}

async function initDashboard() {
    try {
        const response = await fetch('./data/summary.json');
        const data = await response.json();
        if (!data || data.length === 0) return;

        const firstEntry = data[0];
        const lastEntry = data[data.length - 1];

        // --- 1. CALCUL DU TEMPS RÉEL ---
        const startDate = parseFrenchDate(firstEntry.Date);
        const endDate = parseFrenchDate(lastEntry.Date);
        const diffTime = Math.abs(endDate - startDate);
        const realDayCount = Math.ceil(diffTime / (1000 * 60 * 60 * 24)); 
        document.getElementById('days-count').innerText = realDayCount;

        // --- 2. GESTION DE LA PHASE ACTUELLE ---
        const phaseEl = document.getElementById('current-phase');
        const phaseName = lastEntry.PHASE.toUpperCase();
        phaseEl.innerText = phaseName;
        
        // On applique une classe CSS selon la phase
        let phaseClass = 'phase-maintenance'; // Défaut
        if (phaseName.includes('DÉFICIT')) phaseClass = 'phase-deficit';
        else if (phaseName.includes('REVERSE')) phaseClass = 'phase-reverse';
        else if (phaseName.includes('DIET BREAK')) phaseClass = 'phase-diet-break';
        else if (phaseName.includes('SURPLUS')) phaseClass = 'phase-surplus';
        else if (phaseName.includes('PRIMING')) phaseClass = 'phase-priming';
        
        phaseEl.className = `phase-tag ${phaseClass}`;

        // --- 3. CALCULS KPI ---
        document.getElementById('current-weight').innerText = lastEntry.PDC.toFixed(1);
        const totalDelta = lastEntry.PDC - firstEntry.PDC;
        const diffEl = document.getElementById('total-diff');
        diffEl.innerText = (totalDelta > 0 ? '+' : '') + totalDelta.toFixed(2);
        diffEl.style.color = totalDelta <= 0 ? '#3fb950' : '#f85149';

        // Pas & Projection (FIX multiplication par 7)
        const totalSteps = data.reduce((sum, d) => sum + (parseFloat(d.PAS) || 0), 0) * 7;
        document.getElementById('total-steps').innerText = Math.round(totalSteps).toLocaleString();
        const avgStepsPerDay = totalSteps / realDayCount;
        document.getElementById('year-steps').innerText = ((avgStepsPerDay * 365) / 1000000).toFixed(2);

        // --- 4. MAINTENANCE THÉORIQUE ---
        const totalKcalDeficit = Math.abs(totalDelta) * 7700;
        const dailyDeficitFromWeight = totalKcalDeficit / realDayCount;
        const kcalEntries = data.filter(d => d.KCALS && d.KCALS > 0);
        const avgConsumed = kcalEntries.reduce((sum, d) => sum + d.KCALS, 0) / kcalEntries.length;
        const estMaintenance = avgConsumed + dailyDeficitFromWeight;
        document.getElementById('est-maintenance').innerText = Math.round(estMaintenance);

        // --- 5. TERMINAL LOGS ---
        const terminal = document.getElementById('terminal');
        const logs = [
            `[SYSTEM] Current Phase detected: ${phaseName}`,
            `[SYSTEM] Temporal drift: ${realDayCount} days of tracking.`,
            `[MATH] Predictive TDEE: ${Math.round(estMaintenance)} kcal.`
        ];
        logs.forEach((msg, i) => {
            setTimeout(() => {
                const line = document.createElement('div');
                line.className = 'log-line';
                line.innerText = `> ${msg}`;
                terminal.appendChild(line);
                terminal.scrollTop = terminal.scrollHeight;
            }, i * 500);
        });

        // --- 6. GRAPHIQUES ---
        const chartOptions = { responsive: true, maintainAspectRatio: false, plugins: { legend: { display: false } }, scales: { y: { grid: { color: '#161b22' }, ticks: { color: '#8b949e' } }, x: { grid: { display: false }, ticks: { color: '#8b949e' } } } };
        new Chart(document.getElementById('weightChart'), { type: 'line', data: { labels: data.map(d => d.Date.split(' ').slice(1, 3).join(' ')), datasets: [{ data: data.map(d => d.PDC), borderColor: '#a277ff', tension: 0.4 }] }, options: chartOptions });
        new Chart(document.getElementById('stepsChart'), { type: 'bar', data: { labels: data.map(d => d.Date.split(' ').slice(1, 3).join(' ')), datasets: [{ data: data.map(d => d.PAS), backgroundColor: 'rgba(162, 119, 255, 0.4)' }] }, options: chartOptions });

    } catch (e) { console.error("Critical Failure:", e); }
}
document.addEventListener('DOMContentLoaded', initDashboard);