import { createSlice } from '@reduxjs/toolkit';
import { addInventory, deleteInventory, getInventories, getInventoryDetails, updateInventory } from '../actions/inventoryActions';

export const inventorySlice = createSlice({
  name: 'inventory',
  initialState: {
    inventory: [],
    loading: false, // Useful for async actions like login/signup
    error: null, // To handle errors
    count: 0,
    inventoryDetails: {},
    isUpdated: false,
    isDeleted: false,
  },
  reducers: {
  },
  extraReducers: (builder) => {
    builder
      
      .addCase(getInventories.pending, (state) => {
        state.loading = true;
      })
      .addCase(getInventories.fulfilled, (state, action) => {
        state.loading = false;
        state.inventory = action.payload.inventories;
        state.count = action.payload.count;
        state.pageSize = action.payload.pageSize;
      })
      .addCase(getInventories.rejected, (state, action) => {
        state.loading = false;
        state.error = action.payload; 
      })

      .addCase(addInventory.pending, (state) => {
        state.loading = true;
      })
      .addCase(addInventory.fulfilled, (state, action) => {
        state.loading = false;
        state.success = action.payload.success;
      })
      .addCase(addInventory.rejected, (state, action) => {
        state.loading = false;
        state.error = action.payload;
      })

       .addCase(updateInventory.pending, (state) => {
        state.loading = true;
      })
      .addCase(updateInventory.fulfilled, (state, action) => {
        state.loading = false;
        state.isUpdated = action.payload.success;
      })
      .addCase(updateInventory.rejected, (state, action) => {
        state.loading = false;
        state.error = action.payload;
      })

      .addCase(getInventoryDetails.pending, (state) => {
        state.loading = true;
      })
      .addCase(getInventoryDetails.fulfilled, (state, action) => {
        state.loading = false;
        state.inventoryDetails = action.payload.inventory;
      })
      .addCase(getInventoryDetails.rejected, (state, action) => {
        state.loading = false;
        state.error = action.payload
      })

      .addCase(deleteInventory.pending, (state) => {
        state.loading = true;
      })
      .addCase(deleteInventory.fulfilled, (state, action) => {
        state.loading = false;
        state.isDeleted = action.payload.success;
      })
      .addCase(deleteInventory.rejected, (state, action) => {
        state.loading = false;
        state.error = action.payload;
      });
      
  },
});

export default inventorySlice.reducer;
