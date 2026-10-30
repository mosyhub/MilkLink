import { createAsyncThunk } from '@reduxjs/toolkit';
import api from '../../api/axiosInstance'
const VITE_APP_URL = import.meta.env.VITE_APP_URL;

// Request Milk schedule
export const getSignatories = createAsyncThunk(
    'sign/getSignatories',
    async (req, thunkAPI) => {
        const config = {
            headers: {
                'Content-Type': 'application/json',
            },
            withCredentials: true
        }
        try {
            const response = await api.get(`${VITE_APP_URL}/api/v1/signatories`, req, config)
            return response.data;
        } catch (error) {
            return thunkAPI.rejectWithValue(error.message);
        }
    }
)

export const updateSignatories = createAsyncThunk(
    'sign/updateSignatories',
    async (req, thunkAPI) => {
        const config = {
            headers: {
                'Content-Type': 'application/json',
            },
            withCredentials: true
        }
        try {
            const response = await api.put(`${VITE_APP_URL}/api/v1/update/signatories/${req.id}`, req, config)
            return response.data;
        } catch (error) {
            return thunkAPI.rejectWithValue(error.message);
        }
    }
)