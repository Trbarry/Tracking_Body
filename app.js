async function initDashboard() {
    const statusEl = document.getElementById('status');
    try {
        const response = await fetch('./data/summary.json');
        if (!response.ok) throw new Error(`Erreur HTTP: ${response.status}`);
        
        const data = await response.json();
        if (!data || data.length === 0) return;

        // 1. KPI : Poids Actuel et Calories
        const lastEntry = data[data.length - 1];
        const firstEntry = data[0];
        
        document.getElementById('current-weight').innerText = lastEntry.PDC.toFixed(1);
        document.getElementById('avg-kcal').innerText = Math.round(lastEntry.KCALS || 0);

        // 2. KPI : Variation Totale
        const totalDiff = lastEntry.PDC - firstEntry.PDC;
        const diffEl = document.getElementById('total-diff');
        diffEl.innerText = (totalDiff > 0 ? '+' : '') + totalDiff.toFixed(2);
        diffEl.style.color = totalDiff <= 0 ? '#3fb950' : '#f85149';

        // 3. Graphique
        const ctx = document.getElementById('mainChart').getContext('2d');
        const gradient = ctx.createLinearGradient(0, 0, 0, 400);
        gradient.addColorStop(0, 'rgba(162, 119, 255, 0.4)');
        gradient.addColorStop(1, 'rgba(162, 119, 255, 0)');

        new Chart(ctx, {
            type: 'line',
            data: {
                labels: data.map(d => d.Date.split(' ').slice(1, 3).join(' ')),
                datasets: [{
                    label: 'Poids (kg)',
                    data: data.map(d => d.PDC),
                    borderColor: '#a277ff',
                    backgroundColor: gradient,
                    fill: true,
                    tension: 0.4,
                    borderWidth: 3
                }]
            },
            options: {
                responsive: true,
                maintainAspectRatio: false,
                scales: {
                    y: { beginAtZero: false, grid: { color: '#30363d' }, ticks: { color: '#8b949e' } },
                    x: { grid: { display: false }, ticks: { color: '#8b949e' } }
                },
                plugins: { legend: { display: false } }
            }
        });

        if(statusEl) statusEl.innerText = "Données synchronisées avec succès.";

    } catch (err) {
        console.error("Dashboard Error:", err);
        if(statusEl) statusEl.innerText = "Erreur de chargement des données.";
    }
}

document.addEventListener('DOMContentLoaded', initDashboard);