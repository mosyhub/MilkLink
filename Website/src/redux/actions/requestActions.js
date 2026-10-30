import { createAsyncThunk } from '@reduxjs/toolkit';
import api from '../../api/axiosInstance'
const VITE_APP_URL = import.meta.env.VITE_APP_URL;
// Get All Request
export const getRequests = createAsyncThunk(
    'request/getRequests',
    async (query, thunkAPI) => {



        const config = {
            headers: {
                'Content-Type': 'application/json',

            },
            withCredentials: true
        }
        try {
            let urlString = ''
            if (query) {
                urlString = `${VITE_APP_URL}/api/v1/requests?search=${query}`
            }
            else {
                urlString = `${VITE_APP_URL}/api/v1/requests`
            }

            const response = await api.get(urlString, config);

            return response.data;

        } catch (error) {
            return thunkAPI.rejectWithValue(error.message);
        }
    }
)

// Add Request
export const addRequest = createAsyncThunk(
    'request/addRequest',
    async (req, thunkAPI) => {



        const config = {
            headers: {
                'Content-Type': 'application/json',

            },
            withCredentials: true
        }
        try {

            const response = await api.post(`${VITE_APP_URL}/api/v1/requests`, req, config)

            return response.data;

        } catch (error) {

            return thunkAPI.rejectWithValue(error.message);
        }
    }
)

// Update request
export const updateRequest = createAsyncThunk(
    'request/updateRequest',
    async (req, thunkAPI) => {



        const config = {
            headers: {
                'Content-Type': 'application/json',

            },
            withCredentials: true
        }
        try {
            const response = await api.put(`${VITE_APP_URL}/api/v1/request/${req.id}`, req, config)

            return response.data;

        } catch (error) {

            return thunkAPI.rejectWithValue(error.message);
        }
    }
)

// Update request
export const updateRequestStatus = createAsyncThunk(
    'request/updateRequestStatus',
    async (req, thunkAPI) => {



        const config = {
            headers: {
                'Content-Type': 'application/json',

            },
            withCredentials: true
        }
        try {
            const response = await api.put(`${VITE_APP_URL}/api/v1/request-status/${req.id}`, req, config)

            return response.data;

        } catch (error) {

            return thunkAPI.rejectWithValue(error.message);
        }
    }
)
// Delete request
export const deleteRequest = createAsyncThunk(
    'request/deleteRequest',
    async (id, thunkAPI) => {



        const config = {
            headers: {
                'Content-Type': 'application/json',

            },
            withCredentials: true
        }
        try {
            const response = await api.delete(`${VITE_APP_URL}/api/v1/request/${id}`, config)

            return response.data;

        } catch (error) {

            return thunkAPI.rejectWithValue(error.message);
        }
    }
)

// Get request Details
export const getRequestDetails = createAsyncThunk(
    'request/getRequestDetails',
    async (id, thunkAPI) => {



        const config = {
            headers: {
                'Content-Type': 'application/json',

            },
            withCredentials: true
        }
        try {

            const response = await api.get(`${VITE_APP_URL}/api/v1/request/${id}`, config)
            console.log("Response: ", response.data)
            return response.data;

        } catch (error) {

            return thunkAPI.rejectWithValue(error.message);
        }
    }
)

// Get request Details
export const getStaffRequests = createAsyncThunk(
    'request/getStaffRequests',
    async (id, thunkAPI) => {



        const config = {
            headers: {
                'Content-Type': 'application/json',

            },
            withCredentials: true
        }
        try {

            const response = await api.get(`${VITE_APP_URL}/api/v1/staff/${id}/requests`, config)
            console.log("Response: ", response.data)
            return response.data;

        } catch (error) {

            return thunkAPI.rejectWithValue(error.message);
        }
    }
)

// Update request
export const updateVolumeRequested = createAsyncThunk(
    'request/updateVolumeRequested',
    async (req, thunkAPI) => {



        const config = {
            headers: {
                'Content-Type': 'application/json',

            },
            withCredentials: true
        }
        try {
            const response = await api.put(`${VITE_APP_URL}/api/v1/request/${req.id}/volume`, req, config)

            return response.data;

        } catch (error) {

            return thunkAPI.rejectWithValue(error.message);
        }
    }
)

// Dispense inpatient request bottles
export const inpatientDispense = createAsyncThunk(
    'request/inpatientDispense',
    async (req, thunkAPI) => {


        const config = {
            headers: {
                'Content-Type': 'application/json',

            },
            withCredentials: true
        }
        try {
            const response = await api.put(`${VITE_APP_URL}/api/v1/inpatient-dispense`, req, config)

            return response.data;

        } catch (error) {
            console.log("Error: ", error.message)
            return thunkAPI.rejectWithValue(error.response?.data?.message);
        }
    }
)

export const outpatientDispense = createAsyncThunk(
    'request/outpatientDispense',
    async (req, thunkAPI) => {



        const config = {
            headers: {
                'Content-Type': 'application/json',

            },
            withCredentials: true
        }
        try {
            const response = await api.put(`${VITE_APP_URL}/api/v1/outpatient-dispense`, req, config)

            return response.data;

        } catch (error) {

            return thunkAPI.rejectWithValue(error.message);
        }
    }
)
