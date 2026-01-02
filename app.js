// Fonction utilitaire pour parser les dates "jeudi 17 juillet 2025"
function parseFrenchDate(dateStr) {
    const months = {
        "janvier": 0, "février": 1, "mars": 2, "avril": 3, "mai": 4, "juin": 5,
        "juillet": 6, "août": 7, "septembre": 8, "octobre": 9, "novembre": 10, "décembre": 11
    };
    const p = dateStr.toLowerCase().split(' ');
    // p[1] = jour, p[2] = mois, p[3] = année
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

        // --- 2. CALCULS KPI STANDARDS ---
        document.getElementById('current-weight').innerText = lastEntry.PDC.toFixed(1);
        const totalDelta = lastEntry.PDC - firstEntry.PDC;
        const diffEl = document.getElementById('total-diff');
        diffEl.innerText = (totalDelta > 0 ? '+' : '') + totalDelta.toFixed(2);
        diffEl.style.color = totalDelta <= 0 ? '#3fb950' : '#f85149';

        // Pas totaux et projection
        const totalSteps = data.reduce((sum, d) => sum + (parseFloat(d.PAS) || 0), 0);
        document.getElementById('total-steps').innerText = Math.round(totalSteps).toLocaleString();
        const avgSteps = totalSteps / data.length; // Moyenne par semaine relevée
        document.getElementById('year-steps').innerText = ((avgSteps * 52) / 1000000).toFixed(2);

        // --- 3. FIX MAINTENANCE THÉORIQUE ---
        // 1kg de gras = 7700 kcal. 
        // Déficit total = perte de poids * 7700
        const totalKcalDeficit = Math.abs(totalDelta) * 7700;
        const dailyDeficit = totalKcalDeficit / realDayCount;

        // Moyenne des calories consommées (on ne prend que les jours avec data)
        const kcalEntries = data.filter(d => d.KCALS && d.KCALS > 0);
        const avgConsumed = kcalEntries.reduce((sum, d) => sum + d.KCALS, 0) / kcalEntries.length;

        // Maintenance = Calories mangées + Déficit compensé par le corps
        const estMaintenance = avgConsumed + dailyDeficit;
        document.getElementById('est-maintenance').innerText = Math.round(estMaintenance);

        // --- 4. TERMINAL & CHARTS (Inchangés mais utilisent les nouvelles vars) ---
        const terminal = document.getElementById('terminal');
        const logs = [
            `[SYSTEM] Temporal drift detected: ${realDayCount} days of tracking.`,
            `[MATH] Correcting metabolic baseline...`,
            `[INFO] Calculated daily deficit: ${Math.round(dailyDeficit)} kcal/day.`,
            `[PREDICT] Theoretical TDEE: ${Math.round(estMaintenance)} kcal.`
        ];
        
        logs.forEach((msg, i) => {
            setTimeout(() => {
                const line = document.createElement('div');
                line.className = 'log-line';
                line.innerText = `> ${msg}`;
                terminal.appendChild(line);
                terminal.scrollTop = terminal.scrollHeight;
            }, i * 600);
        });

        // Config Chart.js (Poids)
        new Chart(document.getElementById('weightChart'), {
            type: 'line',
            data: {
                labels: data.map(d => d.Date.split(' ').slice(1, 3).join(' ')),
                datasets: [{
                    data: data.map(d => d.PDC),
                    borderColor: '#a277ff',
                    fill: false,
                    tension: 0.4
                }]
            },
            options: { responsive: true, maintainAspectRatio: false, plugins: { legend: { display: false } } }
        });

        // Config Chart.js (Pas)
        new Chart(document.getElementById('stepsChart'), {
            type: 'bar',
            data: {
                labels: data.map(d => d.Date.split(' ').slice(1, 3).join(' ')),
                datasets: [{
                    data: data.map(d => d.PAS),
                    backgroundColor: 'rgba(162, 119, 255, 0.4)'
                }]
            },
            options: { responsive: true, maintainAspectRatio: false, plugins: { legend: { display: false } } }
        });

    } catch (e) { console.error("Sync_Error:", e); }
}
document.addEventListener('DOMContentLoaded', initDashboard);