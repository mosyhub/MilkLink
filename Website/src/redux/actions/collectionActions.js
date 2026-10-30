import { createAsyncThunk } from '@reduxjs/toolkit';
import api from '../../api/axiosInstance'
const VITE_APP_URL = import.meta.env.VITE_APP_URL;

// Record Record Public Collection
export const recordPublicRecord = createAsyncThunk(
    'collection/recordPublicRecord',
    async (req, thunkAPI) => {
        const config = {
            headers: {
                'Content-Type': 'application/json',
            },
            withCredentials: true
        }
        try {

            const response = await api.post(`${VITE_APP_URL}/api/v1/record-public`, req, config)
            console.log("record public: ", response.data)
            return response.data;

        } catch (error) {

            return thunkAPI.rejectWithValue(error.message);
        }
    }
)

// Mark Attendance of donors
export const recordPrivateRecord = createAsyncThunk(
    'collection/recordPrivateRecord',
    async (req, thunkAPI) => {



        const config = {
            headers: {
                'Content-Type': 'application/json',

            },
            withCredentials: true
        }
        try {

            const response = await api.post(`${VITE_APP_URL}/api/v1/record-private`, req, config)
            console.log("record private: ", response.data)
            return response.data;

        } catch (error) {

            return thunkAPI.rejectWithValue(error.message);
        }
    }
)


// Mark Attendance of donors
export const getAllCollections = createAsyncThunk(
    'collection/getAllCollections',
    async ({ search = "", type = "", }, thunkAPI) => {



        const config = {
            headers: {
                'Content-Type': 'application/json',

            },
            withCredentials: true
        }
        try {
            let urlString = `${VITE_APP_URL}/api/v1/collections/?`;
            if (search) {
                urlString += `&search=${encodeURIComponent(search)}`;
            }
            if (type) {
                urlString += `&type=${encodeURIComponent(type)}`;
            }

            const response = await api.get(urlString, config)

            return response.data;

        } catch (error) {

            return thunkAPI.rejectWithValue(error.message);
        }
    }
)
