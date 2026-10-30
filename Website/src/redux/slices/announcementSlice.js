import { createSlice } from '@reduxjs/toolkit';
import { addAnnouncements, addHTMLAnnouncements, deleteAnnouncement, getAnnouncement, getAnnouncementDetails, getArchivedAnnouncements, restoreAnnouncement, softDeleteAnnouncement, updateAnnouncements, updateHTMLAnnouncement } from '../actions/announcementActions';


export const announcementSlice = createSlice({
    name: 'announcement',
    initialState: {
        announcements: [],
        loading: false,
        error: null,
        announcementDetails: {},
        isUpdated: false,
        isDeleted: false,
    },
    reducers: {
        resetUpdate: (state) => {
            state.isUpdated = false;
        },
        resetDelete: (state) => {
            state.isDeleted = false;
        },
        resetError: (state) => {
            state.error = null
        },
        resetSuccess: (state) => {
            state.success = false;
        }
    },
    extraReducers: (builder) => {
        builder
            .addCase(getAnnouncement.pending, (state) => {
                state.loading = true;
            })
            .addCase(getAnnouncement.fulfilled, (state, action) => {
                state.loading = false;
                state.announcements = action.payload.articles;
            })
            .addCase(getAnnouncement.rejected, (state, action) => {
                state.loading = false;
                state.error = action.payload;
            })
            .addCase(getArchivedAnnouncements.pending, (state) => {
                state.loading = true;
            })
            .addCase(getArchivedAnnouncements.fulfilled, (state, action) => {
                state.loading = false;
                state.announcements = action.payload.articles;
            })
            .addCase(getArchivedAnnouncements.rejected, (state, action) => {
                state.loading = false;
                state.error = action.payload;
            })
            .addCase(addAnnouncements.pending, (state) => {
                state.loading = true;
            })
            .addCase(addAnnouncements.fulfilled, (state, action) => {
                state.loading = false;
                state.success = action.payload.success;
            })
            .addCase(addAnnouncements.rejected, (state, action) => {
                state.loading = false;
                state.error = action.payload;
            })
            .addCase(updateAnnouncements.pending, (state) => {
                state.loading = true;
            })
            .addCase(updateAnnouncements.fulfilled, (state, action) => {
                state.loading = false;
                state.isUpdated = action.payload.success;
            })
            .addCase(updateAnnouncements.rejected, (state, action) => {
                state.loading = false;
                state.error = action.payload;
            })
            .addCase(getAnnouncementDetails.pending, (state) => {
                state.loading = true;
            })
            .addCase(getAnnouncementDetails.fulfilled, (state, action) => {
                state.loading = false;
                state.announcementDetails = action.payload.article;
            })
            .addCase(getAnnouncementDetails.rejected, (state, action) => {
                state.loading = false;
                state.error = action.payload;
            })
            .addCase(deleteAnnouncement.pending, (state) => {
                state.loading = true;
            })
            .addCase(deleteAnnouncement.fulfilled, (state, action) => {
                state.loading = false;
                state.isDeleted = action.payload.success;
            })
            .addCase(deleteAnnouncement.rejected, (state, action) => {
                state.loading = false;
                state.error = action.payload;
            })
            .addCase(addHTMLAnnouncements.pending, (state) => {
                state.loading = true;
            })
            .addCase(addHTMLAnnouncements.fulfilled, (state, action) => {
                state.loading = false;
                state.success = action.payload.success;
            })
            .addCase(addHTMLAnnouncements.rejected, (state, action) => {
                state.loading = false;
                state.error = action.payload;
            })
            .addCase(updateHTMLAnnouncement.pending, (state) => {
                state.loading = true;
            })
            .addCase(updateHTMLAnnouncement.fulfilled, (state, action) => {
                state.loading = false;
                state.isUpdated = action.payload.success;
            })
            .addCase(updateHTMLAnnouncement.rejected, (state, action) => {
                state.loading = false;
                state.error = action.payload;
            })
            .addCase(softDeleteAnnouncement.pending, (state) => {
                state.loading = true;
            })
            .addCase(softDeleteAnnouncement.fulfilled, (state, action) => {
                state.loading = false;
                state.isDeleted = action.payload.success;
            })
            .addCase(softDeleteAnnouncement.rejected, (state, action) => {
                state.loading = false;
                state.error = action.payload;
            })
            .addCase(restoreAnnouncement.pending, (state) => {
                state.loading = true;
            })
            .addCase(restoreAnnouncement.fulfilled, (state, action) => {
                state.loading = false;
                state.success = action.payload.success;
            })
            .addCase(restoreAnnouncement.rejected, (state, action) => {
                state.loading = false;
                state.error = action.payload;
            })
    }
})
export const { resetUpdate, resetDelete, resetError, resetSuccess } = announcementSlice.actions;
export default announcementSlice.reducer;