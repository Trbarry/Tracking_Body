async function initDashboard() {
    try {
        console.log("[*] Tentative de récupération des données...");
        const response = await fetch('./data/summary.json'); // Note le ./
        
        if (!response.ok) throw new Error(`Erreur HTTP: ${response.status}`);
        
        const data = await response.json();
        console.log("[+] Données reçues :", data);

        if (!data || data.length === 0) {
            console.error("[-] Le fichier JSON est vide.");
            return;
        }

        // --- NETTOYAGE DES KPI ---
        const lastEntry = data[data.length - 1];
        
        // On vérifie si les clés existent bien (exactement comme dans ton JSON)
        const currentWeight = lastEntry["PDC"] || 0;
        const kcals = lastEntry["KCALS"] || 0;
        
        document.getElementById('current-weight').innerText = currentWeight.toFixed(1);
        document.getElementById('avg-kcal').innerText = Math.round(kcals);

        // --- CONFIGURATION CHART ---
        const ctx = document.getElementById('mainChart').getContext('2d');
        
        new Chart(ctx, {
            type: 'line',
            data: {
                // On simplifie la date : "jeudi 17 juillet 2025" -> "17 juillet"
                labels: data.map(d => d.Date.split(' ').slice(1, 3).join(' ')),
                datasets: [{
                    label: 'Poids (kg)',
                    data: data.map(d => d.PDC),
                    borderColor: '#a277ff',
                    backgroundColor: 'rgba(162, 119, 255, 0.1)',
                    borderWidth: 3,
                    tension: 0.4,
                    fill: true
                }]
            },
            options: {
                responsive: true,
                maintainAspectRatio: false,
                scales: {
                    y: { 
                        beginAtZero: false,
                        grid: { color: '#30363d' },
                        ticks: { color: '#8b949e' }
                    },
                    x: {
                        grid: { display: false },
                        ticks: { color: '#8b949e' }
                    }
                },
                plugins: {
                    legend: { display: false }
                }
            }
        });

    } catch (err) {
        console.error("[!] Erreur lors de l'initialisation :", err);
        document.getElementById('status').innerText = "Erreur de chargement des données.";
    }
}

document.addEventListener('DOMContentLoaded', initDashboard);