import { createSlice } from '@reduxjs/toolkit';
import { addEvents, getEvents, editEvents, getEventDetails, deleteEvents, getUpcomingEvents } from '../actions/eventActions';
export const eventSlice = createSlice({
  name: 'event',
  initialState: {
    events: [],
    loading: false, // Useful for async actions like login/signup
    error: null, // To handle errors
    eventDetails: {},
    isUpdated: false,
    isDeleted: false,
    success: false,
  },
  reducers: {
    resetUpdate: (state) => {
      state.isUpdated = false;
    },
    resetDelete: (state) => {
      state.isDeleted = false;
    },
    resetSuccess: (state) => {
      state.success = false;
    }
  },
  extraReducers: (builder) => {
    builder
      .addCase(addEvents.pending, (state) => {
        state.loading = true;
      })
      .addCase(addEvents.fulfilled, (state, action) => {
        state.loading = false;
        state.success = action.payload.success;
        
      })
      .addCase(addEvents.rejected, (state, action) => {
        state.loading = false;
        state.error = action.payload;
      })
      .addCase(getEvents.pending, (state) => {
        state.loading = true;
      })
      .addCase(getEvents.fulfilled, (state, action) => {
        state.loading = false;
        state.events = action.payload.events;
      })
      .addCase(getEvents.rejected, (state, action) => {
        state.loading = false;
        state.error = action.payload;
      })
      .addCase(editEvents.pending, (state) => {
        state.loading = true;
      })
      .addCase(editEvents.fulfilled, (state, action) => {
        state.loading = false;
        state.isUpdated = action.payload.success;
      })
      .addCase(editEvents.rejected, (state, action) => {
        state.loading = false;
        state.error = action.payload;
      })
      .addCase(getEventDetails.pending, (state) => {
        state.loading = true;
      })
      .addCase(getEventDetails.fulfilled, (state, action) => {
        state.loading = false;
        state.eventDetails = action.payload.event;
        
      })
      .addCase(getEventDetails.rejected, (state, action) => {
        state.loading = false;
        state.error = action.payload
      })
      .addCase(deleteEvents.pending, (state) => {
        state.loading = true;
      })
      .addCase(deleteEvents.fulfilled, (state, action) => {
        state.loading = false;
        state.isDeleted = action.payload.success;
      })
      .addCase(deleteEvents.rejected, (state, action) => {
        state.loading = false;
        state.error = action.payload;
      })
      .addCase(getUpcomingEvents.pending, (state) => {
        state.loading = true;
      })
      .addCase(getUpcomingEvents.fulfilled, (state, action) => {
        state.loading = false;
        state.events = action.payload.events;
      })
      .addCase(getUpcomingEvents.rejected, (state, action) => {
        state.loading = false;
        state.error = action.payload;
      })
  }
});
export const {resetUpdate, resetDelete, resetSuccess} = eventSlice.actions;
export default eventSlice.reducer;
