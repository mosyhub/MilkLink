// chartDataUtils.js

import { toTitleCase } from "../utils/helper";

function generateColors(count) {
    // Carefully curated distinct colors
    const distinctColors = [
        'rgba(229, 57, 53, 0.7)',   // Red
        'rgba(30, 136, 229, 0.7)',  // Blue  
        'rgba(67, 160, 71, 0.7)',   // Green
        'rgba(255, 152, 0, 0.7)',   // Orange
        'rgba(142, 36, 170, 0.7)',  // Purple
        'rgba(0, 172, 193, 0.7)',   // Cyan
        'rgba(255, 87, 34, 0.7)',   // Deep Orange
        'rgba(76, 175, 80, 0.7)',   // Light Green
        'rgba(156, 39, 176, 0.7)',  // Deep Purple
        'rgba(3, 169, 244, 0.7)',   // Light Blue
        'rgba(255, 193, 7, 0.7)',   // Amber
        'rgba(121, 85, 72, 0.7)',   // Brown
        'rgba(158, 158, 158, 0.7)', // Gray
        'rgba(233, 30, 99, 0.7)',   // Pink
        'rgba(0, 150, 136, 0.7)',   // Teal
        'rgba(103, 58, 183, 0.7)',  // Deep Purple Alt
        'rgba(205, 220, 57, 0.7)',  // Lime
        'rgba(255, 235, 59, 0.7)',  // Yellow
        'rgba(96, 125, 139, 0.7)',  // Blue Gray
        'rgba(255, 111, 97, 0.7)',  // Light Red
    ];

    if (count <= distinctColors.length) {
        return distinctColors.slice(0, count);
    }

    // If we need more colors, generate them with maximum separation
    const colors = [...distinctColors];
    const remaining = count - distinctColors.length;

    for (let i = 0; i < remaining; i++) {
        // Use prime numbers for maximum color separation
        const primes = [181, 211, 241, 271, 307, 337, 367, 397, 431, 461];
        const primeMultiplier = primes[i % primes.length];
        const hue = (i * primeMultiplier) % 360;
        const saturation = 70 + (i * 7) % 25; // 70-95%
        const lightness = 45 + (i * 11) % 25; // 45-70%

        colors.push(`hsla(${hue}, ${saturation}%, ${lightness}%, 0.7)`);
    }

    return colors;
}

export function milkCollectedChartData(stats) {
    const months = Object.keys(stats).filter((key) => key !== 'total');
    const communityData = months.map((month) => stats[month].community);
    const privateData = months.map((month) => stats[month].private);

    const data = {
        labels: months,
        datasets: [
            {
                label: 'Community',
                data: communityData,
                borderColor: 'rgba(51, 102, 153, 1)',
                backgroundColor: 'rgba(51, 102, 153, 0.5)',
                borderWidth: 2,
                borderRadius: 5,
                borderSkipped: false
            },
            {
                label: 'Private',
                data: privateData,
                borderColor: 'rgba(240, 99, 149, 1)',
                backgroundColor: 'rgba(240, 99, 149, 0.5)',
                borderWidth: 2,
                borderRadius: 5,
                borderSkipped: false
            },
        ],
    };

    const options = {
        responsive: true,
        plugins: {
            datalabels: {
                color: "#000"
            },
            legend: { position: 'top' },
            tooltip: {
                mode: 'index',
                intersect: false,
                callbacks: {
                    label(context) {
                        const label = context.dataset.label || '';
                        const value = context.parsed.y || 0;
                        return `${label}: ${value.toLocaleString()} ml`;
                    },
                },
            },
        },
    };

    return { data, options };
}

export function monthlyDonorsChartData(monthlyDonors) {
    const months = Object.keys(monthlyDonors).filter((key) => key !== 'total');
    const communityData = months.map((month) => monthlyDonors[month].community);
    const privateData = months.map((month) => monthlyDonors[month].private);

    const data = {
        labels: months,
        datasets: [
            {
                label: 'Community',
                data: communityData,
                borderColor: 'rgba(51, 102, 153, 1)',
                backgroundColor: 'rgba(51, 102, 153, 0.5)',
                borderWidth: 2,
                borderRadius: 5,
                borderSkipped: false
            },
            {
                label: 'Private',
                data: privateData,
                borderColor: 'rgba(240, 99, 149, 1)',
                backgroundColor: 'rgba(240, 99, 149, 0.5)',
                borderWidth: 2,
                borderRadius: 5,
                borderSkipped: false
            },
        ],
    };

    const options = {
        responsive: true,
        plugins: {
            datalabels: {
                color: '#000'
            },
            legend: { position: 'top' },
            tooltip: {
                mode: 'index',
                intersect: false,
                callbacks: {
                    label(context) {
                        const label = context.dataset.label || '';
                        const value = context.parsed.y || 0;
                        return `${label}: ${value.toLocaleString()}`;
                    },
                },
            },
        },
    };

    return { data, options };
}

// You can create similar functions for patients, dispensedMilk, etc.
// For example:

export function monthlyPatientsChartData(monthlyPatients) {
    const months = Object.keys(monthlyPatients).filter((key) => key !== 'total');
    const inpatientData = months.map((month) => monthlyPatients[month].inpatient);
    const outpatientData = months.map((month) => monthlyPatients[month].outpatient);

    const data = {
        labels: months,
        datasets: [
            {
                label: 'Inpatient',
                data: inpatientData,
                borderColor: 'rgba(51, 102, 153, 1)',
                backgroundColor: 'rgba(51, 102, 153, 0.5)',
                borderWidth: 2,
                borderRadius: 5,
                borderSkipped: false
            },
            {
                label: 'Outpatient',
                data: outpatientData,
                borderColor: 'rgba(240, 99, 149, 1)',
                backgroundColor: 'rgba(240, 99, 149, 0.5)',
                borderWidth: 2,
                borderRadius: 5,
                borderSkipped: false
            },
        ],
    };

    const options = {
        responsive: true,
        plugins: {
            datalabels: {
                color: "#000"
            },
            legend: { position: 'top' },
            tooltip: {
                mode: 'index',
                intersect: false,
                callbacks: {
                    label(context) {
                        const label = context.dataset.label || '';
                        const value = context.parsed.y || 0;
                        return `${label}: ${value.toLocaleString()}`;
                    },
                },
            },
        },
    };

    return { data, options };
}

export function monthlyDispensedMilkChartData(dispensedMilk) {

    const months = Object.keys(dispensedMilk).filter((key) => key !== 'total');
    const inpatientData = months.map((month) => dispensedMilk[month].inpatient);
    const outpatientData = months.map((month) => dispensedMilk[month].outpatient);
    const data = {
        labels: months,
        datasets: [
            {
                label: 'Inpatient',
                data: inpatientData,
                borderColor: 'rgba(51, 102, 153, 1)',
                backgroundColor: 'rgba(51, 102, 153, 0.5)',
                borderWidth: 2,
                borderRadius: 5,
                borderSkipped: false
            },
            {
                label: 'Outpatient',
                data: outpatientData,
                borderColor: 'rgba(240, 99, 149, 1)',
                backgroundColor: 'rgba(240, 99, 149, 0.5)',
                borderWidth: 2,
                borderRadius: 5,
                borderSkipped: false
            }
        ]
    };

    // Optional config
    const options = {
        responsive: true,
        plugins: {
            datalabels: {
                color: "#000"
            },
            legend: { position: 'top' },
            tooltip: {
                mode: 'index',
                intersect: false,
                callbacks: {
                    label: function (context) {
                        const label = context.dataset.label || '';
                        const value = context.parsed.y || 0;
                        return `${label}: ${value.toLocaleString()} ml`;
                    }
                }
            }
        }
    };

    return { data, options }
}


export function milkDonatedPerBarangay(volumePerLocation) {
    const entries = Object.entries(volumePerLocation).filter(([key]) => key !== 'total');

    const locations = entries.map(([location]) => location);
    const labels = locations.map(toTitleCase)
    const dataValues = entries.map(([, volume]) => volume);
    // Generate dynamic colors based on the number of data points
    const dynamicColors = generateColors(dataValues.length);
    const data = {
        labels,
        datasets: [
            {
                label: 'Volume',
                data: dataValues,
                backgroundColor: dynamicColors,
                borderWidth: 1,
            },
        ],
    };
    const options = {
        responsive: true,
        maintainAspectRatio: false,
        plugins: {
            legend: {
                display: true,
                position: 'right',
                labels: {
                    boxWidth: 20,
                    padding: 15, // Adjust this value to control spacing
                    usePointStyle: true,
                    font: {
                        size: 12
                    }
                }
            },
            datalabels: {
                color: '#000',
                font: {
                    weight: 'semibold',
                    size: 12, // Reduced from 14 for better fit
                },
                formatter: (value, context) => {
                    // Show percentage instead of label + value for cleaner look
                    const total = context.dataset.data.reduce((a, b) => a + b, 0);
                    const percentage = ((value / total) * 100).toFixed(1);
                    return `${percentage}%`;
                },
                display: function (context) {
                    // Only show labels for slices larger than 5%
                    const value = context.parsed;
                    const total = context.dataset.data.reduce((a, b) => a + b, 0);
                    const percentage = (value / total) * 100;
                    return percentage > 5;
                }
            },
            tooltip: {
                callbacks: {
                    label: function (tooltipItem) {
                        const value = tooltipItem.raw || 0;
                        const total = tooltipItem.dataset.data.reduce((a, b) => a + b, 0);
                        const percentage = ((value / total) * 100).toFixed(1);
                        const label = tooltipItem.label || '';
                        return `${label}: ${value.toLocaleString()} ml (${percentage}%)`;
                    },
                },
            },
        },
        layout: {
            padding: {
                top: 10,
                bottom: 10,
                left: 10,
                right: 10
            }
        }
    };

    return { data, options }

}


export function donorsPerBarangay(donorLocation) {
    const entries = Object.entries(donorLocation).filter(([key]) => key !== 'total');

    const labels = entries.map(([location]) => location);
    const dataValues = entries.map(([, volume]) => volume);
    // Generate dynamic colors based on the number of data points
    const dynamicColors = generateColors(dataValues.length);
    const data = {
        labels,
        datasets: [
            {
                label: 'Volume',
                data: dataValues,
                backgroundColor: dynamicColors,
                borderWidth: 1,
            },
        ],
    };
    const options = {
        responsive: true,
        maintainAspectRatio: false,
        plugins: {
            legend: {
                display: true,
                position: 'right', // Changed from 'left' to 'right' for better space utilization
                labels: {
                    boxWidth: 20, // Reduced from 40 for more chart space
                    padding: 15, // Increased padding for better spacing
                    usePointStyle: true,
                    font: {
                        size: 12 // Added font size for better readability
                    }
                }
            },
            datalabels: {
                color: '#000',
                font: {
                    weight: 'semibold',
                    size: 12, // Reduced from 14 for better fit
                },
                formatter: (value, context) => {
                    // Show percentage instead of label + value for cleaner look
                    const total = context.dataset.data.reduce((a, b) => a + b, 0);
                    const percentage = ((value / total) * 100).toFixed(1);
                    return `${percentage}%`;
                },
                display: function (context) {
                    // Only show labels for slices larger than 5%
                    const value = context.parsed;
                    const total = context.dataset.data.reduce((a, b) => a + b, 0);
                    const percentage = (value / total) * 100;
                    return percentage > 5;
                }
            },
            tooltip: {
                callbacks: {
                    label: function (tooltipItem) {
                        const value = tooltipItem.raw || 0;
                        const total = tooltipItem.dataset.data.reduce((a, b) => a + b, 0);
                        const percentage = ((value / total) * 100).toFixed(1);
                        const label = tooltipItem.label || '';
                        return `${label}: ${value.toLocaleString()} (${percentage}%)`;
                    },
                },
            },
        },
        layout: {
            padding: {
                top: 10,
                bottom: 10,
                left: 10,
                right: 10
            }
        }
    };

    return { data, options }

}


export function patientPerHospital(patientHospital) {
    const entries = Object.entries(patientHospital).filter(([key]) => key !== 'total');

    const labels = entries.map(([location]) => location);
    const dataValues = entries.map(([, volume]) => volume);
    // Generate dynamic colors based on the number of data points
    const dynamicColors = generateColors(dataValues.length);
    const data = {
        labels,
        datasets: [
            {
                label: 'Volume',
                data: dataValues,
                backgroundColor: dynamicColors,
                borderWidth: 1,
            },
        ],
    };
    const options = {
        responsive: true,
        maintainAspectRatio: false,
        plugins: {
            legend: {
                display: true,
                position: 'right', // Changed from 'left' to 'right' for better space utilization
                labels: {
                    boxWidth: 20, // Reduced from 40 for more chart space
                    padding: 15, // Increased padding for better spacing
                    usePointStyle: true,
                    font: {
                        size: 12 // Added font size for better readability
                    }
                }
            },
            datalabels: {
                color: '#000',
                font: {
                    weight: 'semibold',
                    size: 12, // Reduced from 14 for better fit
                },
                formatter: (value, context) => {
                    // Show percentage instead of label + value for cleaner look
                    const total = context.dataset.data.reduce((a, b) => a + b, 0);
                    const percentage = ((value / total) * 100).toFixed(1);
                    return `${percentage}%`;
                },
                display: function (context) {
                    // Only show labels for slices larger than 5%
                    const value = context.parsed;
                    const total = context.dataset.data.reduce((a, b) => a + b, 0);
                    const percentage = (value / total) * 100;
                    return percentage > 5;
                }
            },
            tooltip: {
                callbacks: {
                    label: function (tooltipItem) {
                        const value = tooltipItem.raw || 0;
                        const total = tooltipItem.dataset.data.reduce((a, b) => a + b, 0);
                        const percentage = ((value / total) * 100).toFixed(1);
                        const label = tooltipItem.label || '';
                        return `${label}: ${value.toLocaleString()} (${percentage}%)`;
                    },
                },
            },
        },
        layout: {
            padding: {
                top: 10,
                bottom: 10,
                left: 10,
                right: 10
            }
        }
    };

    return { data, options }

}

export function donationHistory(volumeByDate) {
    if (!volumeByDate || typeof volumeByDate !== 'object') {
        return { data: null, options: null };
    }

    const labels = Object.keys(volumeByDate);
    const dataPoints = Object.values(volumeByDate);

    const data = {
        labels,
        datasets: [
            {
                label: 'Total Volume',
                data: dataPoints,
                borderColor: 'white',
                backgroundColor: 'rgba(255, 255, 255, 0.2)',
                tension: 0.3,
                fill: true,
            },
        ],
    };

    const options = {
        responsive: true,
        plugins: {
            legend: {
                position: 'top',
                labels: { color: 'white' },
            },
            title: {
                display: true,
                text: 'Milk Letting Volume by Date',
                color: 'white',
            },
        },
        scales: {
            x: {
                ticks: { color: 'white' },
                grid: { color: 'rgba(255, 255, 255, 0.1)' },
            },
            y: {
                ticks: { color: 'white' },
                grid: { color: 'rgba(255, 255, 255, 0.1)' },
            },
        },
    };

    return { data, options };
}

export function donorAgeDemographic(donorAge) {
    const labels = Object.keys(donorAge).filter(key => key !== 'total');
    const dataCounts = labels.map(age => donorAge[age]);
    const data = {
        labels: labels,
        datasets: [
            {
                label: 'Number of Donors',
                data: dataCounts,
                borderColor: 'rgba(240, 99, 149, 1)',
                backgroundColor: 'rgba(240, 99, 149, 0.5)',
                borderWidth: 2,
                borderRadius: 5,
                borderSkipped: false
            }
        ]
    };

    const options = {
        responsive: true,
        plugins: {
            datalabels: {
                color: "#000"
            },
            legend: {
                display: false,
            },
            tooltip: {
                callbacks: {
                    label: function (context) {
                        return `Donors: ${context.formattedValue}`;
                    }
                }
            },
            title: {
                display: true,
                text: 'Donor Age Distribution'
            }
        },
        scales: {
            x: {
                title: {
                    display: true,
                    text: 'Age'
                }
            },
            y: {
                beginAtZero: true,
                title: {
                    display: true,
                    text: 'Number of Donors'
                }
            }
        }
    };


    return { data, options }
}