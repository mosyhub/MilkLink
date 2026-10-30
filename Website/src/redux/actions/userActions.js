import { createAsyncThunk } from '@reduxjs/toolkit';
import { authenticate, logout } from '../../utils/helper';
import api from '../../api/axiosInstance'
const VITE_APP_URL = import.meta.env.VITE_APP_URL;
import axios from 'axios';
export const loginUser = createAsyncThunk(
  'user/loginUser',
  async (credentials, thunkAPI) => {

    const config = {
      withCredentials: true,
      headers: {
        "Content-Type": "application/json",
      },
      skipAuthInterceptor: true
    };
    try {
      console.log(credentials.get('isEmp'));
      let url = `${VITE_APP_URL}/api/v1/login`
      if (credentials.get('isEmp')) {
        url = `${VITE_APP_URL}/api/v1/login/?emp=true`
      }
      const response = await axios.post(url, credentials, config);

      authenticate(response.data, () => { });
      return response.data;

    } catch (error) {
      console.log('Error:', error.response.data.message);
      return thunkAPI.rejectWithValue(error.response.data.message);
    }
  }
)

export const sendResetPasswordEmail = createAsyncThunk(
  'user/sendResetPasswordEmail',
  async (email, thunkAPI) => {
    const config = {
      withCredentials: true,
      headers: {
        "Content-Type": "application/json",
      }
    };
    try {

      let url = `${VITE_APP_URL}/api/v1/password/reset`
      const response = await axios.post(url, email, config);
      return response.data; // Return the response data if needed
    } catch (error) {
      console.log('Error:', error.message);
      return thunkAPI.rejectWithValue(error.message);
    }
  });

export const resetPassword = createAsyncThunk(
  'user/resetPassword',
  async ({ token, req }, thunkAPI) => {
    const config = {
      headers: {
        "Content-Type": "application/json",
      },
      withCredentials: true
    };
    try {
      const response = await axios.put(`${VITE_APP_URL}/api/v1/password/reset/${token}`, req, config);
      return response.data;
    } catch (error) {
      console.log('Error:', error.message);
      return thunkAPI.rejectWithValue(error.message);
    }
  }
);

export const logoutUser = createAsyncThunk(
  'user/logoutUser',
  async (msg, thunkAPI) => {
    try {
      console.log("Logging out");
      const response = await axios.get(
        `${VITE_APP_URL}/api/v1/logout`,
        {
          headers: {
            "Content-Type": "application/json",
          },
          withCredentials: true,
          skipAuthInterceptor: true,
        }
      );
      logout(msg);
      return response.data;
    } catch (error) {
      return thunkAPI.rejectWithValue(error.message);
    }
  }
);

export const getUserDetails = createAsyncThunk(
  'user/getUserDetails',
  async (_, thunkAPI) => {


    const config = {
      headers: {
        'Content-Type': 'application/json',

      },
      withCredentials: true
    }
    try {
      console.log("Getting user details");
      const response = await api.get(
        `${VITE_APP_URL}/api/v1/me`,
        config
      );

      return response.data; // Optionally return the response if necessary for further actions

    } catch (error) {
      return thunkAPI.rejectWithValue(error.message);
    }
  }
);


export const registerUser = createAsyncThunk(
  'user/registerUser',

  async (userData, thunkAPI) => {
    console.log("Registering User");
    const config = {
      headers: {
        "Content-Type": "application/json",
      },
      withCredentials: true
    };
    try {

      const response = await axios.post(`${VITE_APP_URL}/api/v1/register`, userData, config);

      return response.data;

    } catch (error) {
      return thunkAPI.rejectWithValue(error.message);
    }
  }
)


export const getUser = createAsyncThunk(
  'user/getUser', // Action type prefix
  async (_, thunkAPI) => {
    try {
      if (typeof window !== 'undefined') {
        const user = sessionStorage.getItem('user');
        if (user) {
          // Parse and return the user data
          return JSON.parse(user);
        } else {
          // Reject if user data is not found
          return thunkAPI.rejectWithValue('No user found in session storage');
        }
      }
    } catch (error) {
      return thunkAPI.rejectWithValue(error.message);
    }
  }
);

export const getAllUsers = createAsyncThunk(
  'user/getAllUsers',
  async ({ search = "", sortBy = "", order = "", role = "", page = 1, pageSize = 12 }, thunkAPI) => {


    const config = {
      headers: {
        'Content-Type': 'application/json',

      },
      withCredentials: true
    }
    try {
      let urlString = `${VITE_APP_URL}/api/v1/super/users?page=${page}&pageSize=${pageSize}`;
      if (search) {
        urlString += `&search=${encodeURIComponent(search)}`;
      }
      if (sortBy) {
        urlString += `&sortBy=${encodeURIComponent(sortBy)}`;
      }
      if (order) {
        urlString += `&order=${encodeURIComponent(order)}`;
      }
      if (role) {
        urlString += `&role=${encodeURIComponent(role)}`;
      }
      const response = await api.get(urlString, config);


      return response.data;

    } catch (error) {
      console.log('Error:', error.message);
      return thunkAPI.rejectWithValue(error.message);
    }
  }
)