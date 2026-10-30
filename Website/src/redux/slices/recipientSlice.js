import { createSlice } from '@reduxjs/toolkit';
import { 
  addPatient, 
  deletePatient, 
  getPatientDetails, 
  getRecipients, 
  updatePatient 
} from '../actions/recipientActions';

export const recipientSlice = createSlice({
  name: 'recipient',
  initialState: {
    recipients: [],
    newPatient: {},
    patientDetails: {},
    isUpdated: false,
    isDeleted: false,
    loading: false, 
    error: null, 
    totalPatients: 0,
    totalPages: 0,
    pageSize: 0,
  },
  reducers: {
  },
  extraReducers: (builder) => {
    builder
      
      .addCase(getRecipients.pending, (state) => {
        state.loading = true;
      })
      .addCase(getRecipients.fulfilled, (state, action) => {
        state.loading = false;
        state.recipients = action.payload.patients;
        state.totalPatients = action.payload.totalPatients;
        state.pageSize = action.payload.pageSize;
        state.totalPages = action.payload.totalPages;
      })
      .addCase(getRecipients.rejected, (state, action) => {
        state.loading = false;
        state.error = action.payload; // The error message passed in rejectWithValue
      })

      .addCase(addPatient.pending, (state) => {
        state.loading = true;
      })
      .addCase(addPatient.fulfilled, (state, action) => {
        state.loading = false;
        state.success = action.payload.success;
        state.newPatient = action.payload.patient;
      })
      .addCase(addPatient.rejected, (state, action) => {
        state.loading = false;
        state.error = action.payload;
      })

       .addCase(updatePatient.pending, (state) => {
        state.loading = true;
      })
      .addCase(updatePatient.fulfilled, (state, action) => {
        state.loading = false;
        state.isUpdated = action.payload.success;
      })
      .addCase(updatePatient.rejected, (state, action) => {
        state.loading = false;
        state.error = action.payload;
      })

      .addCase(getPatientDetails.pending, (state) => {
        state.loading = true;
      })
      .addCase(getPatientDetails.fulfilled, (state, action) => {
        state.loading = false;
        state.patientDetails = action.payload.patient;
      })
      .addCase(getPatientDetails.rejected, (state, action) => {
        state.loading = false;
        state.error = action.payload
      })

      .addCase(deletePatient.pending, (state) => {
        state.loading = true;
      })
      .addCase(deletePatient.fulfilled, (state, action) => {
        state.loading = false;
        state.isDeleted = action.payload.success;
      })
      .addCase(deletePatient.rejected, (state, action) => {
        state.loading = false;
        state.error = action.payload;
      });
      
      
  },
});

export default recipientSlice.reducer;
