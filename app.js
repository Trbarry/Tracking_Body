async function initDashboard() {
    try {
        const response = await fetch('./data/summary.json');
        const data = await response.json();
        if (!data || data.length === 0) return;

        const lastEntry = data[data.length - 1];
        const firstEntry = data[0];

        // --- 1. KPIs ---
        document.getElementById('current-weight').innerText = lastEntry.PDC.toFixed(1);
        
        const diff = lastEntry.PDC - firstEntry.PDC;
        const diffEl = document.getElementById('total-diff');
        diffEl.innerText = (diff > 0 ? '+' : '') + diff.toFixed(2);
        diffEl.style.color = diff <= 0 ? '#3fb950' : '#f85149';

        // Moyenne Calories (7 derniers jours réels)
        const validKcals = data.filter(d => d.KCALS && d.KCALS > 0).slice(-7);
        const avgKcal = validKcals.reduce((sum, d) => sum + d.KCALS, 0) / (validKcals.length || 1);
        document.getElementById('avg-kcal').innerText = Math.round(avgKcal);

        // Moyenne Pas (7 derniers jours réels)
        const validSteps = data.filter(d => d.PAS && d.PAS > 0).slice(-7);
        const avgSteps = validSteps.reduce((sum, d) => sum + d.PAS, 0) / (validSteps.length || 1);
        document.getElementById('avg-steps').innerText = Math.round(avgSteps).toLocaleString();

        // --- 2. LOGS TERMINAL ---
        const terminal = document.getElementById('terminal');
        const logs = [
            `[AUTH] Identity confirmed: Tristan Barry`,
            `[DATA] Biometric and Activity nodes synced.`,
            `[STATUS] Phase: ${lastEntry.PHASE} | Activity: ${Math.round(avgSteps)} avg steps`,
            `[ALGO] Weight trend: ${diff.toFixed(2)}kg since start.`
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

        // --- 3. GRAPHIQUE POIDS ---
        const ctxWeight = document.getElementById('weightChart').getContext('2d');
        new Chart(ctxWeight, {
            type: 'line',
            data: {
                labels: data.map(d => d.Date.split(' ').slice(1, 3).join(' ')),
                datasets: [{
                    label: 'Poids (kg)',
                    data: data.map(d => d.PDC),
                    borderColor: '#a277ff',
                    backgroundColor: 'rgba(162, 119, 255, 0.05)',
                    fill: true,
                    tension: 0.4,
                    borderWidth: 2
                }]
            },
            options: { responsive: true, maintainAspectRatio: false, plugins: { legend: { display: false } }, 
                scales: { y: { beginAtZero: false, grid: { color: '#161b22' }, ticks: { color: '#8b949e' } }, x: { grid: { display: false }, ticks: { color: '#8b949e' } } }
            }
        });

        // --- 4. GRAPHIQUE PAS (Histogramme) ---
        const ctxSteps = document.getElementById('stepsChart').getContext('2d');
        new Chart(ctxSteps, {
            type: 'bar',
            data: {
                labels: data.map(d => d.Date.split(' ').slice(1, 3).join(' ')),
                datasets: [{
                    label: 'Pas quotidiens',
                    data: data.map(d => d.PAS),
                    backgroundColor: 'rgba(162, 119, 255, 0.5)',
                    borderRadius: 4
                }]
            },
            options: { responsive: true, maintainAspectRatio: false, plugins: { legend: { display: false } }, 
                scales: { y: { beginAtZero: true, grid: { color: '#161b22' }, ticks: { color: '#8b949e' } }, x: { grid: { display: false }, ticks: { color: '#8b949e' } } }
            }
        });

    } catch (e) { console.error("Critical System Failure:", e); }
}
document.addEventListener('DOMContentLoaded', initDashboard);