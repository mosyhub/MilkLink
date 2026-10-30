import { createSlice } from '@reduxjs/toolkit';
import { checkEligibility, getDonors, getModelReport, getSingleDonor, getSubmissions, updateDonor } from '../actions/donorActions';
export const donorSlice = createSlice({
  name: 'donor',
  initialState: {
    donors: [],
    loading: false,
    pythonLoading: false,
    error: null,
    pageSize: 0,
    totalDonors: 0,
    totalPages: 0,
    isUpdated: false,
    donorDetails: {},
    isEligible: false,
    submissions: [],
    model: {}
  },
  reducers: {
    resetUpdate: (state) => {
      state.isUpdated = false;
    },
    resetDelete: (state) => {
      state.isDeleted = false;
    }
  },
  extraReducers: (builder) => {
    builder

      .addCase(getDonors.pending, (state) => {
        state.loading = true;
      })
      .addCase(getDonors.fulfilled, (state, action) => {
        state.loading = false;
        state.donors = action.payload.donors;
        state.pageSize = action.payload.pageSize;
        state.totalDonors = action.payload.totalDonors;
        state.totalPages = action.payload.totalPages;
      })
      .addCase(getDonors.rejected, (state, action) => {
        state.loading = false;
        state.error = action.payload;
      })

      .addCase(updateDonor.pending, (state) => {
        state.loading = true;
      })
      .addCase(updateDonor.fulfilled, (state, action) => {
        state.loading = false;
        state.isUpdated = action.payload.success;
      })
      .addCase(updateDonor.rejected, (state, action) => {
        state.loading = false;
        state.error = action.payload;
      })
      .addCase(getSingleDonor.pending, (state) => {
        state.loading = true;
      })
      .addCase(getSingleDonor.fulfilled, (state, action) => {
        state.loading = false;
        state.donorDetails = action.payload.donor;
      })
      .addCase(getSingleDonor.rejected, (state, action) => {
        state.loading = false;
        state.error = action.payload;
      })
      .addCase(checkEligibility.pending, (state) => {
        state.loading = true;
        state.isEligible = false;
      })
      .addCase(checkEligibility.fulfilled, (state, action) => {
        state.loading = false;
        state.isEligible = action.payload.success;
      })
      .addCase(checkEligibility.rejected, (state, action) => {
        state.loading = false;
        state.error = action.payload;
      })
      .addCase(getSubmissions.pending, (state) => {
        state.loading = true;
      })
      .addCase(getSubmissions.fulfilled, (state, action) => {
        state.loading = false;
        state.submissions = action.payload.donors;
      })
      .addCase(getSubmissions.rejected, (state, action) => {
        state.loading = false;
        state.error = action.payload;
      })
      .addCase(getModelReport.pending, (state) => {
        state.pythonLoading = true;
      })
      .addCase(getModelReport.fulfilled, (state, action) => {
        state.pythonLoading = false;
        state.model = action.payload;
      })
      .addCase(getModelReport.rejected, (state, action) => {
        state.pythonLoading = false;
        state.error = action.payload;
      });
  },
});
export const { resetUpdate, resetDelete } = donorSlice.actions;
export default donorSlice.reducer;
