async function initDashboard() {
    try {
        const response = await fetch('./data/summary.json');
        const data = await response.json();
        if (!data || data.length === 0) return;

        const lastEntry = data[data.length - 1];
        const firstEntry = data[0];

        // 1. Mise à jour des KPIs
        document.getElementById('current-weight').innerText = lastEntry.PDC.toFixed(1);
        const diff = lastEntry.PDC - firstEntry.PDC;
        const diffEl = document.getElementById('total-diff');
        diffEl.innerText = (diff > 0 ? '+' : '') + diff.toFixed(2);
        diffEl.style.color = diff <= 0 ? '#3fb950' : '#f85149';

        // 2. Calcul Moyenne Calories (7 derniers jours réels)
        const validKcals = data.filter(d => d.KCALS && d.KCALS > 0).slice(-7);
        const avg = validKcals.reduce((sum, d) => sum + d.KCALS, 0) / (validKcals.length || 1);
        document.getElementById('avg-kcal').innerText = Math.round(avg);

        // 3. Moteur de Logs Terminal
        const terminal = document.getElementById('terminal');
        const logs = [
            `[AUTH] Identity confirmed: Tristan Barry`,
            `[DATA] Analysis of ${data.length} biometric nodes completed.`,
            `[STATUS] Current phase: ${lastEntry.PHASE}`,
            `[ALGO] Weight trend: ${diff.toFixed(2)}kg since start.`,
            `[INFO] System stable. Listening for next data push...`
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

        // 4. Initialisation Chart.js
        const ctx = document.getElementById('mainChart').getContext('2d');
        new Chart(ctx, {
            type: 'line',
            data: {
                labels: data.map(d => d.Date.split(' ').slice(1, 3).join(' ')),
                datasets: [{
                    data: data.map(d => d.PDC),
                    borderColor: '#a277ff',
                    backgroundColor: 'rgba(162, 119, 255, 0.05)',
                    fill: true,
                    tension: 0.4,
                    borderWidth: 2,
                    pointRadius: 2
                }]
            },
            options: {
                responsive: true,
                maintainAspectRatio: false, // Sécurisé par le wrapper CSS
                plugins: { legend: { display: false } },
                scales: {
                    y: { beginAtZero: false, grid: { color: '#161b22' }, ticks: { color: '#8b949e' } },
                    x: { grid: { display: false }, ticks: { color: '#8b949e' } }
                }
            }
        });

    } catch (e) { console.error("Critical System Failure:", e); }
}
document.addEventListener('DOMContentLoaded', initDashboard);