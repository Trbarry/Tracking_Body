async function initDashboard() {
    try {
        const response = await fetch('./data/summary.json');
        const data = await response.json();
        if (!data) return;

        const lastEntry = data[data.length - 1];
        const firstEntry = data[0];

        // 1. KPI - Poids & Variation
        document.getElementById('current-weight').innerText = lastEntry.PDC.toFixed(1);
        const diff = lastEntry.PDC - firstEntry.PDC;
        document.getElementById('total-diff').innerText = (diff > 0 ? '+' : '') + diff.toFixed(2);

        // 2. VRAIE MOYENNE CALORIES (on filtre les 0 et les vides)
        const validKcals = data.filter(d => d.KCALS > 0).slice(-7);
        const avg = validKcals.reduce((sum, d) => sum + d.KCALS, 0) / (validKcals.length || 1);
        document.getElementById('avg-kcal').innerText = Math.round(avg);

        // 3. TERMINAL LOG ENGINE
        const terminal = document.getElementById('terminal');
        const logs = [
            `[AUTH] Access granted for UID: Tristan_Barry`,
            `[DATA] Analysis of ${data.length} biometric points completed.`,
            `[STATUS] Current phase: ${lastEntry.PHASE}`,
            `[TRACKER] Last training detected: ${lastEntry.TRAINING || 'REST'}`,
            `[INFO] Target detected: 70.0kg. Remaining: ${(lastEntry.PDC - 70).toFixed(2)}kg`
        ];
        
        // Ajout des logs avec un petit délai pour l'effet "hacker"
        logs.forEach((msg, i) => {
            setTimeout(() => {
                const line = document.createElement('div');
                line.className = 'log-line';
                line.innerText = msg;
                terminal.appendChild(line);
                terminal.scrollTop = terminal.scrollHeight;
            }, i * 600);
        });

        // 4. CHART FIX
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
                    pointRadius: 3
                }]
            },
            options: {
                responsive: true,
                maintainAspectRatio: false, // Important avec la hauteur fixe du CSS
                plugins: { legend: { display: false } },
                scales: {
                    y: { grid: { color: '#161b22' }, ticks: { color: '#8b949e' } },
                    x: { grid: { display: false }, ticks: { color: '#8b949e' } }
                }
            }
        });

    } catch (e) { console.error("SysError:", e); }
}
document.addEventListener('DOMContentLoaded', initDashboard);