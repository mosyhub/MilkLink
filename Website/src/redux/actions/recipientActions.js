import { createAsyncThunk } from '@reduxjs/toolkit';
import api from '../../api/axiosInstance'
const VITE_APP_URL = import.meta.env.VITE_APP_URL;

// Get All Patient
export const getRecipients = createAsyncThunk(
    'recipient/getRecipients',
    async ({ search = "", page = 1, pageSize = 10, brgy = "", type = "" }, thunkAPI) => {
        const config = {
            headers: {
                'Content-Type': 'application/json',
            },
            withCredentials: true
        }
        try {
            let urlString = `${VITE_APP_URL}/api/v1/patients?page=${page}&pageSize=${pageSize}`;
            if (search) {
                urlString += `&search=${encodeURIComponent(search)}`;
            }
            if (brgy) {
                urlString += `&brgy=${encodeURIComponent(brgy)}`;
            }
            if (type) {
                urlString += `&type=${encodeURIComponent(type)}`;
            }

            const response = await api.get(urlString, config);

            console.log("Response", response.data)
            console.log("URL: ", urlString)

            return response.data;

        } catch (error) {

            return thunkAPI.rejectWithValue(error.message);
        }
    }
)

// Add Patient 
export const addPatient = createAsyncThunk(
    'Patient/addPatients',
    async (req, thunkAPI) => {

        const config = {
            headers: {
                'Content-Type': 'application/json',
            },
            withCredentials: true
        }
        try {

            const response = await api.post(`${VITE_APP_URL}/api/v1/patients`, req, config)

            return response.data;

        } catch (error) {

            return thunkAPI.rejectWithValue(error.message);
        }
    }
)

// Update Patient
export const updatePatient = createAsyncThunk(
    'Patient/updatePatient',
    async (req, thunkAPI) => {
        const config = {
            headers: {
                'Content-Type': 'application/json',
            },
            withCredentials: true
        }
        try {
            const response = await api.put(`${VITE_APP_URL}/api/v1/patient/${req.id}`, req, config)

            return response.data;

        } catch (error) {

            return thunkAPI.rejectWithValue(error.message);
        }
    }
)

// Delete Patient
export const deletePatient = createAsyncThunk(
    'Patient/deletePatients',
    async (id, thunkAPI) => {
        const config = {
            headers: {
                'Content-Type': 'application/json',            
            },
            withCredentials: true
        }
        try {
            const response = await api.delete(`${VITE_APP_URL}/api/v1/patient/${id}`, config)

            return response.data;

        } catch (error) {

            return thunkAPI.rejectWithValue(error.message);
        }
    }
)

// Get Patient Details
export const getPatientDetails = createAsyncThunk(
    'Patient/getPatientDetails',
    async (id, thunkAPI) => {
        const config = {
            headers: {
                'Content-Type': 'application/json',
            },
            withCredentials: true
        }
        try {

            const response = await api.get(`${VITE_APP_URL}/api/v1/patient/${id}`, config)
            console.log("Response: ", response.data)
            return response.data;

        } catch (error) {

            return thunkAPI.rejectWithValue(error.message);
        }
    }
)
