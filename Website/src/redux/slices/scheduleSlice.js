import { createSlice } from '@reduxjs/toolkit';
import { approveSchedule, getDonorSchedules, requestSchedule, updateSchedule, getAllSchedules, getSingleSchedule } from '../actions/scheduleActions';

export const lettingSlice = createSlice({
    name: 'schedule',
    initialState: {
        message: '',
        loading: false,
        error: null,
        success: false,
        schedules: [],
        schedule: {},
        count: 0,
    },
    reducers: {
        resetSuccess: (state) => {
            state.success = false;
        }
    },
    extraReducers: (builder) => {
        builder
            .addCase(requestSchedule.pending, (state) => {
                state.loading = true;
            })
            .addCase(requestSchedule.fulfilled, (state, action) => {
                state.loading = false;
                state.success = true;
                state.message = action.payload.message;
            })
            .addCase(requestSchedule.rejected, (state, action) => {
                state.loading = false;
                state.error = action.payload;
            })

            .addCase(approveSchedule.pending, (state) => {
                state.loading = true;
            })
            .addCase(approveSchedule.fulfilled, (state, action) => {
                state.loading = false;
                state.success = true;
                state.message = action.payload.message;
            })
            .addCase(approveSchedule.rejected, (state, action) => {
                state.loading = false;
                state.error = action.payload;
            })
            .addCase(getDonorSchedules.pending, (state) => {
                state.loading = true;
            })
            .addCase(getDonorSchedules.fulfilled, (state, action) => {
                state.loading = false;
                state.schedules = action.payload.schedules;
                state.count = action.payload.count;
            })
            .addCase(getDonorSchedules.rejected, (state, action) => {
                state.loading = false;
                state.error = action.payload;
            })
            .addCase(getAllSchedules.pending, (state) => {
                state.loading = true;
            })
            .addCase(getAllSchedules.fulfilled, (state, action) => {
                state.loading = false;
                state.schedules = action.payload.schedules;
                state.count = action.payload.count;
            })
            .addCase(getAllSchedules.rejected, (state, action) => {
                state.loading = false;
                state.error = action.payload;
            })
            .addCase(getSingleSchedule.pending, (state) => {
                state.loading = true;
            })
            .addCase(getSingleSchedule.fulfilled, (state, action) => {
                state.loading = false;
                state.schedule = action.payload.schedule;
                state.count = action.payload.count;
            })
            .addCase(getSingleSchedule.rejected, (state, action) => {
                state.loading = false;
                state.error = action.payload;
            })
            .addCase(updateSchedule.pending, (state) => {
                state.loading = true;
            })
            .addCase(updateSchedule.fulfilled, (state, action) => {
                state.loading = false;
                state.success = true;
                state.message = action.payload.message;
            })
            .addCase(updateSchedule.rejected, (state, action) => {
                state.loading = false;
                state.error = action.payload;
            })
    },
});
export const { resetSuccess } = lettingSlice.actions;
export default lettingSlice.reducer;