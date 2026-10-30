import { createSlice } from "@reduxjs/toolkit";
import {
  createLetting,
  deleteAttendance,
  deleteLetting,
  finalizeSession,
  getAverageLettingVolume,
  getLettingDetails,
  getLettings,
  getUpcomingLettings,
  markAttendance,
  newPublicDonor,
  updateAttendance,
  updateLetting,
} from "../actions/lettingActions";

export const lettingSlice = createSlice({
  name: "letting",
  initialState: {
    lettings: [],
    message: "",
    newDonor: {},
    average: 0,
    lettingDetails: {},
    loading: false,
    error: null,
    success: false,
    isUpdated: false,
    isDeleted: false,
  },
  reducers: {
    resetSuccess: (state) => {
      state.success = false;
    },
    resetUpdate: (state) => {
      state.isUpdated = false;
    },
    resetError: (state) => {
      state.error = null;
    },
    resetDelete: (state) => {
      state.isDeleted = false;
    }
  },
  extraReducers: (builder) => {
    builder
      .addCase(createLetting.pending, (state) => {
        state.loading = true;
      })
      .addCase(createLetting.fulfilled, (state, action) => {
        state.loading = false;
        state.success = action.payload.success;
        state.message = action.payload.message;
      })
      .addCase(createLetting.rejected, (state, action) => {
        state.loading = false;
        state.error = action.payload;
      })

      .addCase(newPublicDonor.pending, (state) => {
        state.loading = true;
      })
      .addCase(newPublicDonor.fulfilled, (state, action) => {
        state.loading = false;
        state.success = action.payload.success;
        state.message = action.payload.message;
        state.newDonor = action.payload.donor;
      })
      .addCase(newPublicDonor.rejected, (state, action) => {
        state.loading = false;
        state.error = action.payload;
      })

      .addCase(markAttendance.pending, (state) => {
        state.loading = true;
      })
      .addCase(markAttendance.fulfilled, (state, action) => {
        state.loading = false;
        state.success = action.payload.success;
        state.message = action.payload.message;
      })
      .addCase(markAttendance.rejected, (state, action) => {
        state.loading = false;
        state.error = action.payload;
      })

      .addCase(finalizeSession.pending, (state) => {
        state.loading = true;
      })
      .addCase(finalizeSession.fulfilled, (state, action) => {
        state.loading = false;
        state.success = action.payload.success;
        state.message = action.payload.message;
      })
      .addCase(finalizeSession.rejected, (state, action) => {
        state.loading = false;
        state.error = action.payload;
      })

      .addCase(getLettings.pending, (state) => {
        state.loading = true;
      })
      .addCase(getLettings.fulfilled, (state, action) => {
        state.loading = false;
        state.lettings = action.payload.lettings;
      })
      .addCase(getLettings.rejected, (state, action) => {
        state.loading = false;
        state.error = action.payload;
      })
      .addCase(getUpcomingLettings.pending, (state) => {
        state.loading = true;
      })
      .addCase(getUpcomingLettings.fulfilled, (state, action) => {
        state.loading = false;
        state.lettings = action.payload.events;
      })
      .addCase(getUpcomingLettings.rejected, (state, action) => {
        state.loading = false;
        state.error = action.payload;
      })
      .addCase(getLettingDetails.pending, (state) => {
        state.loading = true;
      })
      .addCase(getLettingDetails.fulfilled, (state, action) => {
        state.loading = false;
        state.lettingDetails = action.payload.letting;
      })
      .addCase(getLettingDetails.rejected, (state, action) => {
        state.loading = false;
        state.error = action.payload;
      })

      .addCase(deleteLetting.pending, (state) => {
        state.loading = true;
      })
      .addCase(deleteLetting.fulfilled, (state, action) => {
        state.loading = false;
        state.isDeleted = action.payload.success;
      })
      .addCase(deleteLetting.rejected, (state, action) => {
        state.loading = false;
        state.error = action.payload;
      })

      .addCase(updateLetting.pending, (state) => {
        state.loading = true;
      })
      .addCase(updateLetting.fulfilled, (state, action) => {
        state.loading = false;
        state.isUpdated = action.payload.success;
      })
      .addCase(updateLetting.rejected, (state, action) => {
        state.loading = false;
        state.error = action.payload;
      })
      .addCase(updateAttendance.pending, (state) => {
        state.loading = true;
      })
      .addCase(updateAttendance.fulfilled, (state, action) => {
        state.loading = false;
        state.success = action.payload.success;
        state.message = action.payload.message;
      })
      .addCase(updateAttendance.rejected, (state, action) => {
        state.loading = false;
        state.error = action.payload;
      })
      .addCase(getAverageLettingVolume.pending, (state) => {
        state.loading = true;
      })
      .addCase(getAverageLettingVolume.fulfilled, (state, action) => {
        state.loading = false;
        state.average = action.payload.averageVolume;
      })
      .addCase(getAverageLettingVolume.rejected, (state, action) => {
        state.loading = false;
        state.error = action.payload
      })
      .addCase(deleteAttendance.pending, (state) => {
        state.loading = false;
      })
      .addCase(deleteAttendance.fulfilled, (state) => {
        state.success = true,
        state.loading = false;
      })
      .addCase(deleteAttendance.rejected, (state, action) => {
        state.loading = false;
        state.error = action.payload;
      })
  },
});
export const { resetSuccess, resetError, resetDelete, resetUpdate } = lettingSlice.actions;
export default lettingSlice.reducer;
