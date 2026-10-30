import { createSlice } from '@reduxjs/toolkit';
import { getMilkPerMonth, getDonorsPerMonth, getDispensedMilkPerMonth, getPatientsPerMonth, getVolumePerLocation, getRequestsPerMonth, getDonorLocation, getPatientHospital, getPasteurizedMilkPerMonth, getDonorAgeDemographic, getAvailableMilk, getExpiringMilk } from '../actions/metricActions';
export const metricSlice = createSlice({
    name: 'metric',
    initialState: {
        statsLoading: false,
        monthlyDonorsLoading: false,
        pastPerMonthLoading: false,
        volumePerLocationLoading: false,
        donorLocationLoading: false,
        dispensedMilkLoading: false,
        monthlyPatientsLoading: false,
        monthlyRequestsLoading: false,
        patientHospitalLoading: false,
        availableLoading: false,
        expiringLoading: false,
        donorAgeLoading: false,
        error: null,
        donorAge: {},
        stats: {},
        available: 0,
        expiring: 0,
        pastPerMonth: {},
        volumePerLocation: {},
        donorLocation: {},
        monthlyDonors: {},
        dispensedMilk: {},
        monthlyPatients: {},
        monthlyRequests: {},
        patientHospital: {},
    },
    reducers: {
    },
    extraReducers: (builder) => {
        builder
            .addCase(getMilkPerMonth.pending, (state) => {
                state.statsLoading = true;
            })
            .addCase(getMilkPerMonth.fulfilled, (state, action) => {
                state.statsLoading = false;
                state.stats = action.payload.stats;
            })
            .addCase(getMilkPerMonth.rejected, (state, action) => {
                state.statsLoading = false;
                state.error = action.payload;
            })

            .addCase(getDonorsPerMonth.pending, (state) => {
                state.monthlyDonorsLoading = true;
            })
            .addCase(getDonorsPerMonth.fulfilled, (state, action) => {
                state.monthlyDonorsLoading = false;
                state.monthlyDonors = action.payload.result;
            })
            .addCase(getDonorsPerMonth.rejected, (state, action) => {
                state.monthlyDonorsLoading = false;
                state.error = action.payload;
            })

            .addCase(getDispensedMilkPerMonth.pending, (state) => {
                state.dispensedMilkLoading = true;
            })
            .addCase(getDispensedMilkPerMonth.fulfilled, (state, action) => {
                state.dispensedMilkLoading = false;
                state.dispensedMilk = action.payload.dispensedMilk;
            })
            .addCase(getDispensedMilkPerMonth.rejected, (state, action) => {
                state.dispensedMilkLoading = false;
                state.error = action.payload;
            })

            .addCase(getPatientsPerMonth.pending, (state) => {
                state.monthlyPatientsLoading = true;
            })
            .addCase(getPatientsPerMonth.fulfilled, (state, action) => {
                state.monthlyPatientsLoading = false;
                state.monthlyPatients = action.payload.recipients;
            })
            .addCase(getPatientsPerMonth.rejected, (state, action) => {
                state.monthlyPatientsLoading = false;
                state.error = action.payload;
            })

            .addCase(getRequestsPerMonth.pending, (state) => {
                state.monthlyRequestsLoading = true;
            })
            .addCase(getRequestsPerMonth.fulfilled, (state, action) => {
                state.monthlyRequestsLoading = false;
                state.monthlyRequests = action.payload.requests;
            })
            .addCase(getRequestsPerMonth.rejected, (state, action) => {
                state.monthlyRequestsLoading = false;
                state.error = action.payload;
            })

            .addCase(getAvailableMilk.pending, (state) => {
                state.availableLoading = true;
            })
            .addCase(getAvailableMilk.fulfilled, (state, action) => {
                state.availableLoading = false;
                state.available = action.payload.availableMilk;
            })
            .addCase(getAvailableMilk.rejected, (state, action) => {
                state.availableLoading = false;
                state.error = action.payload;
            })

            .addCase(getExpiringMilk.pending, (state) => {
                state.expiringLoading = true;
            })
            .addCase(getExpiringMilk.fulfilled, (state, action) => {
                state.expiringLoading = false;
                state.expiring = action.payload.expiringMilk;
            })
            .addCase(getExpiringMilk.rejected, (state, action) => {
                state.expiringLoading = false;
                state.error = action.payload;
            })

            .addCase(getVolumePerLocation.pending, (state) => {
                state.volumePerLocationLoading = true;
            })
            .addCase(getVolumePerLocation.fulfilled, (state, action) => {
                state.volumePerLocationLoading = false;
                state.volumePerLocation = action.payload.volumePerLocation;
            })
            .addCase(getVolumePerLocation.rejected, (state, action) => {
                state.volumePerLocationLoading = false;
                state.error = action.payload;
            })

            .addCase(getDonorLocation.pending, (state) => {
                state.donorLocationLoading = true;
            })
            .addCase(getDonorLocation.fulfilled, (state, action) => {
                state.donorLocationLoading = false;
                state.donorLocation = action.payload.donors;
            })
            .addCase(getDonorLocation.rejected, (state, action) => {
                state.donorLocationLoading = false;
                state.error = action.payload;
            })

            .addCase(getPatientHospital.pending, (state) => {
                state.patientHospitalLoading = true;
            })
            .addCase(getPatientHospital.fulfilled, (state, action) => {
                state.patientHospitalLoading = false;
                state.patientHospital = action.payload.hospitals;
            })
            .addCase(getPatientHospital.rejected, (state, action) => {
                state.patientHospitalLoading = false;
                state.error = action.payload;
            })
            .addCase(getPasteurizedMilkPerMonth.pending, (state) => {
                state.pastPerMonthLoading = true;
            })
            .addCase(getPasteurizedMilkPerMonth.fulfilled, (state, action) => {
                state.pastPerMonthLoading = false;
                state.pastPerMonth = action.payload.monthlyVolumes;
            })
            .addCase(getPasteurizedMilkPerMonth.rejected, (state, action) => {
                state.pastPerMonthLoading = false;
                state.error = action.payload;
            })
            .addCase(getDonorAgeDemographic.pending, (state) => {
                state.donorAgeLoading = true;
            })
            .addCase(getDonorAgeDemographic.fulfilled, (state, action) => {
                state.donorAgeLoading = false;
                state.donorAge = action.payload.donorAge;
            })
            .addCase(getDonorAgeDemographic.rejected, (state, action) => {
                state.donorAgeLoading = false;
                state.error = action.payload;
            })
    },
});

export default metricSlice.reducer;