import { createAsyncThunk } from '@reduxjs/toolkit';
import api from '../../api/axiosInstance'
const VITE_APP_URL = import.meta.env.VITE_APP_URL;

// Request Milk schedule
export const requestSchedule = createAsyncThunk(
    'schedule/requestSchedule',
    async (req, thunkAPI) => {

      
        const config = {
            headers: {
                'Content-Type': 'application/json',
               
            },
            withCredentials: true
        }
        try {

            const response = await api.post(`${VITE_APP_URL}/api/v1/request-schedule`, req, config)
            console.log("request schedule: ", response.data)
            return response.data;

        } catch (error) {

            return thunkAPI.rejectWithValue(error.message);
        }
    }
)

// Mark Attendance of donors
export const approveSchedule = createAsyncThunk(
    'schedule/approveSchedule',
    async (req, thunkAPI) => {

      
        const config = {
            headers: {
                'Content-Type': 'application/json',
               
            },
            withCredentials: true
        }
        try {

            const response = await api.post(`${VITE_APP_URL}/api/v1/approve-schedule`, req, config)
            console.log("approve schedule: ", response.data)
            return response.data;

        } catch (error) {

            return thunkAPI.rejectWithValue(error.message);
        }
    }
)


export const getAllSchedules = createAsyncThunk(
    'schedule/getAllSchedules',
    async (req, thunkAPI) => {

      
        const config = {
            headers: {
                'Content-Type': 'application/json',
               
            },
            withCredentials: true
        }
        try {

            const response = await api.get(`${VITE_APP_URL}/api/v1/schedules`, config)
            
            return response.data;

        } catch (error) {

            return thunkAPI.rejectWithValue(error.message);
        }
    }
)

export const getDonorSchedules = createAsyncThunk(
    'schedule/getDonorSchedules',
    async (req, thunkAPI) => {

      
        const config = {
            headers: {
                'Content-Type': 'application/json',
               
            },
            withCredentials: true
        }
        try {

            const response = await api.get(`${VITE_APP_URL}/api/v1/me/schedules/${req}`, config)
            
            return response.data;

        } catch (error) {

            return thunkAPI.rejectWithValue(error.message);
        }
    }
)

export const getSingleSchedule = createAsyncThunk(
    'schedule/getSingleSchedule',
    async (req, thunkAPI) => {

      
        const config = {
            headers: {
                'Content-Type': 'application/json',
               
            },
            withCredentials: true
        }
        try {

            const response = await api.get(`${VITE_APP_URL}/api/v1/schedule/${req}`, config)
            
            return response.data;

        } catch (error) {

            return thunkAPI.rejectWithValue(error.message);
        }
    }
)

export const updateSchedule = createAsyncThunk(
    'schedule/updateSchedule',
    async (req, thunkAPI) => {

      
        const config = {
            headers: {
                'Content-Type': 'application/json',
               
            },
            withCredentials: true
        }
        try {

            const response = await api.put(`${VITE_APP_URL}/api/v1/schedule/${req.id}`, req, config)
            
            return response.data;

        } catch (error) {

            return thunkAPI.rejectWithValue(error.message);
        }
    }
)