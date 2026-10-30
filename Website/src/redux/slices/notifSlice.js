import { createSlice } from "@reduxjs/toolkit";
import {
  deleteNotif,
  getUserNotifications,
  markAsSeen,
  notifChecker,
  sendNotifications,
  sendSingleUserNotif,
} from "../actions/notifActions";

const notifSlice = createSlice({
  name: "notifications",
  initialState: {
    notifDetails: null,
    notifications: [],
    unseen: 0,
    count: 0,
    message: null,
    loading: false,
    error: null,
  },
  reducers: {
  },
  extraReducers: (builder) => {
    builder
      .addCase(notifChecker.pending, (state) => {
        state.loading = true;
        state.error = null;
      })
      .addCase(notifChecker.fulfilled, (state, action) => {
        state.loading = false;
        state.notifDetails = action.payload.notification;
      })
      .addCase(notifChecker.rejected, (state, action) => {
        state.loading = false;
        state.error = action.payload;
      })

      .addCase(getUserNotifications.pending, (state) => {
        state.loading = true;
        state.error = null;
      })
      .addCase(getUserNotifications.fulfilled, (state, action) => {
        state.loading = false;
        state.notifications = action.payload.notifications;
        state.count = action.payload.count;
        state.unseen = action.payload.unseen;
      })
      .addCase(getUserNotifications.rejected, (state, action) => {
        state.loading = false;
        state.error = action.payload;
      })

      .addCase(sendNotifications.pending, (state) => {
        state.loading = true;
        state.error = null;
      })
      .addCase(sendNotifications.fulfilled, (state, action) => {
        state.loading = false;
        state.message = action.payload.message;
      })
      .addCase(sendNotifications.rejected, (state, action) => {
        state.loading = false;
        state.error = action.payload;
      })

      .addCase(sendSingleUserNotif.pending, (state) => {
        state.loading = true;
        state.error = null;
      })
      .addCase(sendSingleUserNotif.fulfilled, (state, action) => {
        state.loading = false;
        state.message = action.payload.message;
      })
      .addCase(sendSingleUserNotif.rejected, (state, action) => {
        state.loading = false;
        state.error = action.payload;
      })

      .addCase(markAsSeen.pending, (state) => {
        state.loading = true;
        state.error = null;
      })
      .addCase(markAsSeen.fulfilled, (state, action) => {
        state.loading = false;
        state.message = action.payload.message;
      })
      .addCase(markAsSeen.rejected, (state, action) => {
        state.loading = false;
        state.error = action.payload;
      })

      .addCase(deleteNotif.pending, (state) => {
        state.loading = true;
        state.error = null;
      })
      .addCase(deleteNotif.fulfilled, (state, action) => {
        state.loading = false;
        state.message = action.payload.message;
      })
      .addCase(deleteNotif.rejected, (state, action) => {
        state.loading = false;
        state.error = action.payload;
      });
  },
});
export default notifSlice.reducer;
