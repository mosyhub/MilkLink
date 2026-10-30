import { createSlice } from "@reduxjs/toolkit";

import { getSignatories, updateSignatories } from "../actions/signActions";
export const signSlice = createSlice({
    name: "sign",
    initialState: {
        signs: [],
        loading: false,
        error: null,
        isUpdated: false,
    },
    reducers: {
        resetUpdate: (state) => {
            state.isUpdated = false;
        }
    },
    extraReducers: (builder) => {
        builder
            .addCase(getSignatories.pending, (state) => {
                state.loading = true;
            })
            .addCase(getSignatories.fulfilled, (state, action) => {
                state.loading = false;
                state.signs = action.payload.signs;
            })
            .addCase(getSignatories.rejected, (state, action) => {
                state.loading = false;
                state.error = action.payload;
            })
            .addCase(updateSignatories.pending, (state) => {
                state.loading = true;
            })
            .addCase(updateSignatories.fulfilled, (state) => {
                state.loading = false;
                state.isUpdated = true;
            })
            .addCase(updateSignatories.rejected, (state, action) => {
                state.loading = false;
                state.error = action.payload;
            });
    },
});
export const { resetUpdate } = signSlice.actions;
export default signSlice.reducer;
