import { createAsyncThunk } from '@reduxjs/toolkit';
import axios from 'axios';
const VITE_APP_URL = import.meta.env.VITE_APP_URL;
const VITE_PYTHON_URL = import.meta.env.VITE_PYTHON_URL;
import api from '../../api/axiosInstance'
export const getDonors = createAsyncThunk(
    'donor/getDonors',
    async ({ search = "", brgy = "", type = "" }, thunkAPI) => {
        const config = {
            headers: {
                'Content-Type': 'application/json'

            },
            withCredentials: true
        };

        try {
            let urlString = `${VITE_APP_URL}/api/v1/donors?`;
            if (search !== "") {
                urlString += `&search=${encodeURIComponent(search)}`;
            }
            if (brgy !== "") {
                urlString += `&brgy=${encodeURIComponent(brgy)}`;
            }
            if (type !== "") {
                urlString += `&type=${encodeURIComponent(type)}`;
            }

            const response = await api.get(urlString, config);

            return response.data;
        } catch (error) {
            return thunkAPI.rejectWithValue(error.message);
        }
    }
);

// Update donor
export const updateDonor = createAsyncThunk(
    'donor/updateDonor',
    async (req, thunkAPI) => {
        const config = {
            headers: {
                'Content-Type': 'application/json'
            },
            withCredentials: true
        }

        try {
            const response = await api.put(`${VITE_APP_URL}/api/v1/donor/${req.id}`, req, config)

            return response.data;

        } catch (error) {

            return thunkAPI.rejectWithValue(error.message);
        }
    }
)

export const getSingleDonor = createAsyncThunk(
    'donor/getSingleDonor',
    async (req, thunkAPI) => {
        const config = {
            headers: {
                'Content-Type': 'application/json'
            },
            withCredentials: true
        }

        try {
            const response = await api.get(`${VITE_APP_URL}/api/v1/donor/${req}`, config)

            return response.data;

        } catch (error) {

            return thunkAPI.rejectWithValue(error.message);
        }
    }
)


export const checkEligibility = createAsyncThunk(
    'donor/checkEligibility',
    async (req, thunkAPI) => {
        const config = {
            headers: {
                'Content-Type': 'application/json'
            },
            withCredentials: true
        }

        try {
            const response = await api.get(`${VITE_APP_URL}/api/v1/check-eligibility/${req}`, config)

            return response.data;

        } catch (error) {

            return thunkAPI.rejectWithValue(error.message);
        }
    }
)


export const getSubmissions = createAsyncThunk(
    'donor/getSubmissions',
    async (req, thunkAPI) => {
        const config = {
            headers: {
                'Content-Type': 'application/json'
            },
            withCredentials: true
        }

        try {
            const response = await api.get(`${VITE_APP_URL}/api/v1/donor/submissions`, config)

            return response.data;

        } catch (error) {

            return thunkAPI.rejectWithValue(error.message);
        }
    }
)

export const getModelReport = createAsyncThunk(
    'donor/getModelReport',
    async (req, thunkAPI) => {
       

        try {
            const response = await axios.get(`${VITE_PYTHON_URL}/model_report`)

            return response.data;

        } catch (error) {

            return thunkAPI.rejectWithValue(error.message);
        }
    }
)