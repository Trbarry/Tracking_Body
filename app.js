async function initDashboard() {
    try {
        const response = await fetch('./data/summary.json');
        const data = await response.json();
        if (!data || data.length === 0) return;

        const lastEntry = data[data.length - 1];
        const firstEntry = data[0];
        const dayCount = data.length;

        // --- 1. CALCULS KPI ---
        document.getElementById('current-weight').innerText = lastEntry.PDC.toFixed(1);
        document.getElementById('days-count').innerText = dayCount;

        // Total Pas
        const totalSteps = data.reduce((sum, d) => sum + (parseFloat(d.PAS) || 0), 0);
        document.getElementById('total-steps').innerText = Math.round(totalSteps).toLocaleString();

        // Extrapolation Annuelle (Moyenne * 365)
        const avgSteps = totalSteps / dayCount;
        const yearProjection = (avgSteps * 365) / 1000000; // En Millions
        document.getElementById('year-steps').innerText = yearProjection.toFixed(2);

        // Variation Poids
        const totalDelta = lastEntry.PDC - firstEntry.PDC;
        document.getElementById('total-diff').innerText = (totalDelta > 0 ? '+' : '') + totalDelta.toFixed(2);

        // --- 2. EXTRAPOLATION MAINTENANCE (Maths) ---
        // 1kg de gras ~= 7700 kcal. On calcule le déficit moyen par jour.
        const totalKcalDeficit = Math.abs(totalDelta) * 7700;
        const dailyDeficit = totalKcalDeficit / dayCount;
        const avgConsummed = data.filter(d => d.KCALS > 0).reduce((sum, d) => sum + d.KCALS, 0) / dayCount;
        const estMaintenance = avgConsummed + dailyDeficit;
        document.getElementById('est-maintenance').innerText = Math.round(estMaintenance);

        // --- 3. TERMINAL LOGS (Predictive) ---
        const terminal = document.getElementById('terminal');
        const logs = [
            `[SYSTEM] Analysing biometric drift over ${dayCount} days...`,
            `[CALC] Average daily activity: ${Math.round(avgSteps)} steps.`,
            `[PREDICT] 2026 Objective: ${Math.round(avgSteps * 365).toLocaleString()} cumulative steps.`,
            `[CYBER] Body-fat-entropy decreasing: ${((Math.abs(totalDelta)/firstEntry.PDC)*100).toFixed(1)}% mass reduction.`,
            `[ADVICE] To maintain ${lastEntry.PDC}kg, aim for ${Math.round(estMaintenance)} kcal.`
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

        // --- 4. CHARTS ---
        const commonOptions = { responsive: true, maintainAspectRatio: false, plugins: { legend: { display: false } }, 
                                scales: { y: { grid: { color: '#161b22' }, ticks: { color: '#8b949e' } }, x: { ticks: { color: '#8b949e' }, grid: { display: false } } } };

        new Chart(document.getElementById('weightChart'), {
            type: 'line', data: { labels: data.map(d => d.Date.split(' ').slice(1, 3).join(' ')), 
            datasets: [{ data: data.map(d => d.PDC), borderColor: '#a277ff', tension: 0.4, fill: false }] }, options: commonOptions });

        new Chart(document.getElementById('stepsChart'), {
            type: 'bar', data: { labels: data.map(d => d.Date.split(' ').slice(1, 3).join(' ')), 
            datasets: [{ data: data.map(d => d.PAS), backgroundColor: 'rgba(162, 119, 255, 0.4)' }] }, options: commonOptions });

    } catch (e) { console.error("Extrapolation_Error:", e); }
}
document.addEventListener('DOMContentLoaded', initDashboard);