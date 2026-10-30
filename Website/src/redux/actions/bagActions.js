import { createAsyncThunk } from '@reduxjs/toolkit';
import api from '../../api/axiosInstance'
const VITE_APP_URL = import.meta.env.VITE_APP_URL;

export const createBag = createAsyncThunk(
    'bag/createBag',
    async (req, thunkAPI) => {
        

        const config = {
            headers: {
                'Content-Type': 'application/json',
                
            },
            withCredentials: true
        };

        try {
            let urlString = `${VITE_APP_URL}/api/v1/bag`;
           

            const response = await api.post(urlString, req, config);

            return response.data;
        } catch (error) {
            return thunkAPI.rejectWithValue(error.message);
        }
    }
);
export const getBags = createAsyncThunk(
    'bag/getBags',
    async (req, thunkAPI) => {
        

        const config = {
            headers: {
                'Content-Type': 'application/json',
                
            },
            withCredentials: true
        };

        try {
            let urlString = `${VITE_APP_URL}/api/v1/bag/donor/${req}`;
           

            const response = await api.get(urlString, config);

            return response.data;
        } catch (error) {
            return thunkAPI.rejectWithValue(error.message);
        }
    }
);
export const getSingleBag = createAsyncThunk(
    'bag/getSingleBag',
    async (req, thunkAPI) => {
        

        const config = {
            headers: {
                'Content-Type': 'application/json',
                
            },
            withCredentials: true
        };

        try {
            let urlString = `${VITE_APP_URL}/api/v1/bag/${req}`;
           

            const response = await api.get(urlString, config);

            return response.data;
        } catch (error) {
            return thunkAPI.rejectWithValue(error.message);
        }
    }
);

export const updateBag = createAsyncThunk(
    'bag/updateBag',
    async (req, thunkAPI) => {
        

        const config = {
            headers: {
                'Content-Type': 'application/json',
                
            },
            withCredentials: true
        };

        try {
            let urlString = `${VITE_APP_URL}/api/v1/bag/${req.id}`;
           

            const response = await api.put(urlString, req, config);

            return response.data;
        } catch (error) {
            return thunkAPI.rejectWithValue(error.message);
        }
    }
);

export const deleteBag = createAsyncThunk(
    'bag/deleteBag',
    async (req, thunkAPI) => {
        

        const config = {
            headers: {
                'Content-Type': 'application/json',
                
            },
            withCredentials: true
        };

        try {
            let urlString = `${VITE_APP_URL}/api/v1/bag/${req}`;
           

            const response = await api.delete(urlString, config);

            return response.data;
        } catch (error) {
            return thunkAPI.rejectWithValue(error.message);
        }
    }
);


export const getAllBags = createAsyncThunk(
    'bag/getAllBags',
    async (req, thunkAPI) => {
        

        const config = {
            headers: {
                'Content-Type': 'application/json',
                
            },
            withCredentials: true
        };

        try {
            const urlString = `${VITE_APP_URL}/api/v1/bags`;

            const response = await api.get(urlString, config);

            return response.data;
        } catch (error) {
            return thunkAPI.rejectWithValue(error.message);
        }
    }
);