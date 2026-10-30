import { createSlice } from '@reduxjs/toolkit';
import { addRequest, getRequests, getRequestDetails, updateRequest, deleteRequest, getStaffRequests, updateVolumeRequested, inpatientDispense, outpatientDispense } from '../actions/requestActions';

export const requestSlice = createSlice({
  name: 'request',
  initialState: {
    request: [],
    loading: false,
    error: null,
    count: 0,
    requestDetails: {},
    isUpdated: false,
    isDeleted: false,
    message: null,
    success: false
  },
  reducers: {
    resetRequestDetails: (state) => {
      state.requestDetails = {};
    },
    resetMessage: (state) => {
      state.message = null;
      state.error = null;
    },
    resetSuccess: (state) => {
      state.success = false;
    },
    resetUpdate: (state) => {
      state.isUpdated = false;
    },
    resetDelete: (state) => {
      state.isDeleted = false;
    }
  },
  extraReducers: (builder) => {
    builder

      .addCase(getRequests.pending, (state) => {
        state.loading = true;
      })
      .addCase(getRequests.fulfilled, (state, action) => {
        state.loading = false;
        state.request = action.payload.requests;
        state.count = action.payload.count;
        state.pageSize = action.payload.pageSize;
      })
      .addCase(getRequests.rejected, (state, action) => {
        state.loading = false;
        state.error = action.payload;
      })

      .addCase(addRequest.pending, (state) => {
        state.loading = true;
      })
      .addCase(addRequest.fulfilled, (state, action) => {
        state.loading = false;
        state.success = action.payload.success;
      })
      .addCase(addRequest.rejected, (state, action) => {
        state.loading = false;
        state.error = action.payload;
      })

      .addCase(updateRequest.pending, (state) => {
        state.loading = true;
      })
      .addCase(updateRequest.fulfilled, (state, action) => {
        state.loading = false;
        state.isUpdated = action.payload.success;
      })
      .addCase(updateRequest.rejected, (state, action) => {
        state.loading = false;
        state.error = action.payload;
      })

      .addCase(getRequestDetails.pending, (state) => {
        state.loading = true;
      })
      .addCase(getRequestDetails.fulfilled, (state, action) => {
        state.loading = false;
        state.requestDetails = action.payload.request;
      })
      .addCase(getRequestDetails.rejected, (state, action) => {
        state.loading = false;
        state.error = action.payload
      })

      .addCase(deleteRequest.pending, (state) => {
        state.loading = true;
      })
      .addCase(deleteRequest.fulfilled, (state, action) => {
        state.loading = false;
        state.isDeleted = action.payload.success;
      })
      .addCase(deleteRequest.rejected, (state, action) => {
        state.loading = false;
        state.error = action.payload;
      })

      .addCase(getStaffRequests.pending, (state) => {
        state.loading = true;
      })
      .addCase(getStaffRequests.fulfilled, (state, action) => {
        state.loading = false;
        state.request = action.payload.requests;
        state.count = action.payload.count;
      })
      .addCase(getStaffRequests.rejected, (state, action) => {
        state.loading = false;
        state.error = action.payload;
      })

      .addCase(updateVolumeRequested.pending, (state) => {
        state.loading = true;
      })
      .addCase(updateVolumeRequested.fulfilled, (state, action) => {
        state.loading = false;
        state.requestDetails = action.payload.request;
      })
      .addCase(updateVolumeRequested.rejected, (state, action) => {
        state.loading = false;
        state.error = action.payload;
      })

      .addCase(inpatientDispense.pending, (state) => {
        state.loading = true;
      })
      .addCase(inpatientDispense.fulfilled, (state, action) => {
        state.loading = false;
        state.message = action.payload.message;
      })
      .addCase(inpatientDispense.rejected, (state, action) => {
        state.loading = false;
        state.error = action.payload;
      })

      .addCase(outpatientDispense.pending, (state) => {
        state.loading = true;
      })
      .addCase(outpatientDispense.fulfilled, (state, action) => {
        state.loading = false;
        state.message = action.payload.message;
      })
      .addCase(outpatientDispense.rejected, (state, action) => {
        state.loading = false;
        state.error = action.payload;
      });

  },
});
export const { resetRequestDetails, resetMessage, resetSuccess, resetUpdate, resetDelete } = requestSlice.actions;
export default requestSlice.reducer;
