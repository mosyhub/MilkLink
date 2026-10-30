import { createSlice } from '@reduxjs/toolkit';
import { getAllCollections, recordPrivateRecord, recordPublicRecord } from '../actions/collectionActions';

export const collectionSlice = createSlice({
  name: 'collection',
  initialState: {
    collections: [],
    collectionDetails: {},
    message: '',
    loading: false,
    error: null,
    success: false,
  },
  reducers: {
  },
  extraReducers: (builder) => {
    builder
      .addCase(recordPublicRecord.pending, (state) => {
        state.loading = true;
      })
      .addCase(recordPublicRecord.fulfilled, (state, action) => {
        state.loading = false;
        state.success = true;
        state.message = action.payload.message;
      })
      .addCase(recordPublicRecord.rejected, (state, action) => {
        state.loading = false;
        state.error = action.payload;
      })

      .addCase(recordPrivateRecord.pending, (state) => {
        state.loading = true;
      })
      .addCase(recordPrivateRecord.fulfilled, (state, action) => {
        state.loading = false;
        state.success = true;
        state.message = action.payload.message;
      })
      .addCase(recordPrivateRecord.rejected, (state, action) => {
        state.loading = false;
        state.error = action.payload;
      })
      .addCase(getAllCollections.pending, (state) => {
        state.loading = true;
        state.error = null;
      })
      .addCase(getAllCollections.fulfilled, (state, action) => {
        state.loading = false;
        state.collections = action.payload.collections;
      })
      .addCase(getAllCollections.rejected, (state, action) => {
        state.loading = false;
        state.error = action.payload;
      })
  },
});

export default collectionSlice.reducer;