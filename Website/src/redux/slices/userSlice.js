import { createSlice } from '@reduxjs/toolkit';
import { loginUser, logoutUser, getUserDetails, registerUser, getUser, getAllUsers, sendResetPasswordEmail} from '../actions/userActions';
export const userSlice = createSlice({
  name: 'user',
  initialState: {
    isLoggedIn: false,
    userDetails: null, // Store user information (e.g., name, email)
    token: null, // Store authentication token
    loading: false, // Useful for async actions like login/signup
    error: null, // To handle errors
    isRegistered: false,
    users: [],
    pageSize: 0,
    totalUsers: 0,
    totalPages: 0,
  },
  reducers: {
    resetRegister: (state) => {
      state.isRegistered = false;
    },
    resetError: (state) => {
      state.error = false;
    }
  },
  extraReducers: (builder) => {
    builder
      // Pending: When the async action starts
      .addCase(loginUser.pending, (state) => {
        state.loading = true;
        state.error = null;
      })
      // Fulfilled: When the async action succeeds
      .addCase(loginUser.fulfilled, (state, action) => {
        state.loading = false;
        state.isLoggedIn = true;
        state.userDetails = action.payload.user;
        state.token = action.payload.token;
      })
      // Rejected: When the async action fails
      .addCase(loginUser.rejected, (state, action) => {
        state.loading = false;
        state.error = action.payload; // The error message passed in rejectWithValue
      })
      .addCase(logoutUser.fulfilled, (state) => {
        state.isLoggedIn = false;
        state.userDetails = null;
        state.token = null;
      })
      .addCase(logoutUser.rejected, (state, action) => {
        console.log('Logout error:', action.payload);
        state.error = action.payload;
      })
      .addCase(getUserDetails.pending, (state) => {
        state.loading = true;
        state.error = null;
      })
      .addCase(getUserDetails.fulfilled, (state, action) => {
        state.userDetails = action.payload.user;
        state.loading = false;
      })
      .addCase(getUserDetails.rejected, (state, action) => {
        state.error = action.payload;
        state.loading = false;
      })
      .addCase(registerUser.pending, (state) => {
        state.loading = true;
        state.error = null;
      })
      .addCase(registerUser.fulfilled, (state) => {
        
        state.loading = false;
        state.isRegistered = true;
      })
      .addCase(registerUser.rejected, (state, action) => {
        state.loading = false;
        state.error = action.payload;
      })
      .addCase(getUser.pending, (state)=>{
        state.loading = true;
        state.error = null;
      })
      .addCase(getUser.fulfilled, (state, action)=>{
        state.loading = false;
        state.userDetails = action.payload;
      })
      .addCase(getUser.rejected, (state, action)=>{
        state.loading = false;
        state.error = action.payload;
      })

      .addCase(getAllUsers.pending, (state)=>{
        state.loading = true;
        state.error = null;
      })
      .addCase(getAllUsers.fulfilled, (state, action)=>{
        state.users = action.payload.users;
        state.totalUsers = action.payload.totalUsers;
        state.totalPages = action.payload.totalPages;
        state.pageSize = action.payload.pageSize;
        state.loading = false;
      })
      .addCase(getAllUsers.rejected, (state, action)=>{
        state.loading = false;
        state.error = action.payload;
      })
      .addCase(sendResetPasswordEmail.pending, (state) => {
        state.loading = true;
      })
      .addCase(sendResetPasswordEmail.fulfilled, (state) => {
        state.loading = false;
      })
      .addCase(sendResetPasswordEmail.rejected, (state, action) => {
        state.loading = false;
        state.error = action.payload; // Handle error message
      })
  },
});

export const {resetRegister, resetError} = userSlice.actions;
export default userSlice.reducer;
