async function initDashboard() {
    try {
        const response = await fetch('data/summary.json');
        const data = await response.json();

        if (!data || data.length === 0) return;

        // 1. CALCUL DES KPI (Indicateurs clés)
        const lastEntry = data[data.length - 1];
        const firstEntry = data[0];
        
        // Poids actuel
        document.getElementById('current-weight').innerText = lastEntry.PDC.toFixed(2);
        
        // Variation Totale
        const totalDiff = lastEntry.PDC - firstEntry.PDC;
        const diffElement = document.getElementById('total-diff');
        diffElement.innerText = (totalDiff > 0 ? '+' : '') + totalDiff.toFixed(2);
        diffElement.style.color = totalDiff <= 0 ? '#3fb950' : '#f85149'; // Vert si perte, rouge si prise

        // Moyenne Calories (7 derniers points)
        const last7 = data.slice(-7);
        const avgKcal = last7.reduce((acc, curr) => acc + (curr.KCALS || 0), 0) / last7.length;
        document.getElementById('avg-kcal').innerText = Math.round(avgKcal);

        // 2. CONFIGURATION DU GRAPHIQUE
        const ctx = document.getElementById('mainChart').getContext('2d');
        
        // Création d'un dégradé violet pour le fond de la courbe
        const gradient = ctx.createLinearGradient(0, 0, 0, 400);
        gradient.addColorStop(0, 'rgba(162, 119, 255, 0.4)');
        gradient.addColorStop(1, 'rgba(162, 119, 255, 0)');

        new Chart(ctx, {
            type: 'line',
            data: {
                labels: data.map(d => d.Date.split(' ').slice(1, 3).join(' ')), // Simplifie la date (ex: "17 juillet")
                datasets: [{
                    label: 'Poids de corps (kg)',
                    data: data.map(d => d.PDC),
                    borderColor: '#a277ff',
                    backgroundColor: gradient,
                    fill: true,
                    borderWidth: 3,
                    tension: 0.4,
                    pointRadius: 4,
                    pointBackgroundColor: '#a277ff',
                    pointBorderColor: '#010409',
                    pointHoverRadius: 7
                }]
            },
            options: {
                responsive: true,
                maintainAspectRatio: false,
                plugins: {
                    legend: { display: false },
                    tooltip: {
                        backgroundColor: '#161b22',
                        titleColor: '#a277ff',
                        bodyColor: '#c9d1d9',
                        borderColor: '#30363d',
                        borderWidth: 1,
                        displayColors: false,
                        callbacks: {
                            afterLabel: (context) => {
                                const entry = data[context.dataIndex];
                                return [`Phase: ${entry.PHASE}`, `Calories: ${entry.KCALS} kcal`];
                            }
                        }
                    }
                },
                scales: {
                    x: { ticks: { color: '#8b949e', maxRotation: 45 }, grid: { display: false } },
                    y: { ticks: { color: '#8b949e' }, grid: { color: 'rgba(48, 54, 61, 0.5)' } }
                }
            }
        });

    } catch (err) {
        console.error("Dashboard Error:", err);
    }
}

document.addEventListener('DOMContentLoaded', initDashboard);