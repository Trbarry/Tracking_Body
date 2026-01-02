async function renderDashboard() {
    try {
        const response = await fetch('data/summary.json');
        const data = await response.json();

        // 1. Extraction des labels (Dates) et des données (PDC)
        const labels = data.map(entry => entry.Date);
        const weights = data.map(entry => entry.PDC);
        
        // 2. Logique de couleur dynamique selon la PHASE
        // Si PHASE contient "DÉFICIT" -> Rouge/Rose, sinon -> Violet
        const pointColors = data.map(entry => 
            entry.PHASE && entry.PHASE.includes('DÉFICIT') ? '#ff4d4d' : '#8a2be2'
        );

        const ctx = document.getElementById('mainChart').getContext('2d');
        
        new Chart(ctx, {
            type: 'line',
            data: {
                labels: labels,
                datasets: [{
                    label: 'Poids de Corps (kg)',
                    data: weights,
                    borderColor: '#8a2be2',
                    backgroundColor: 'rgba(138, 43, 226, 0.1)',
                    borderWidth: 3,
                    pointBackgroundColor: pointColors,
                    pointRadius: 5,
                    tension: 0.3, // Courbe lisse
                    fill: true
                }]
            },
            options: {
                responsive: true,
                maintainAspectRatio: false,
                plugins: {
                    legend: { labels: { color: '#c9d1d9' } },
                    tooltip: {
                        callbacks: {
                            afterLabel: function(context) {
                                let entry = data[context.dataIndex];
                                return `Phase: ${entry.PHASE}\nTraining: ${entry.TRAINING}`;
                            }
                        }
                    }
                },
                scales: {
                    y: {
                        grid: { color: '#30363d' },
                        ticks: { color: '#8b949e' },
                        beginAtZero: false
                    },
                    x: {
                        grid: { display: false },
                        ticks: { color: '#8b949e' }
                    }
                }
            }
        });

    } catch (error) {
        console.error("Erreur d'initialisation du dashboard :", error);
    }
}

renderDashboard();