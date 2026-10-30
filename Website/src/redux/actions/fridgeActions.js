import { createAsyncThunk } from '@reduxjs/toolkit';
import api from '../../api/axiosInstance'

const VITE_APP_URL = import.meta.env.VITE_APP_URL;
// Get All Fridge
export const getFridges = createAsyncThunk(
    'fridge/getFridge',
    async (query, thunkAPI) => {
        
        

        const config = {
            headers: {
                'Content-Type': 'application/json',
               
            },
            withCredentials: true
        }
        try {
            let urlString = ''
            if (query){
                urlString = `${VITE_APP_URL}/api/v1/fridges?search=${query}`
            }
            else {
                urlString = `${VITE_APP_URL}/api/v1/fridges`
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

// Add Fridge 
export const addFridges = createAsyncThunk(
    'fridge/addFridges',
    async (req, thunkAPI) => {

        

        const config = {
            headers: {
                'Content-Type': 'application/json',
               
            },
            withCredentials: true
        }
        try {

            const response = await api.post(`${VITE_APP_URL}/api/v1/fridges`, req, config)

            return response.data;

        } catch (error) {

            return thunkAPI.rejectWithValue(error.message);
        }
    }
)

// Update Fridge
export const updateFridge = createAsyncThunk(
    'fridge/updateFridge',
    async (req, thunkAPI) => {

        

        const config = {
            headers: {
                'Content-Type': 'application/json',
               
            },
            withCredentials: true
        }
        try {
            const response = await api.put(`${VITE_APP_URL}/api/v1/fridge/${req.id}`, req, config)
            console.log(response)
            return response.data;

        } catch (error) {

            return thunkAPI.rejectWithValue(error.message);
        }
    }
)

// Delete Fridge
export const deleteFridges = createAsyncThunk(
    'fridge/deleteFridges',
    async (id, thunkAPI) => {

        

        const config = {
            headers: {
                'Content-Type': 'application/json',
               
            },
            withCredentials: true
        }
        try {
            const response = await api.delete(`${VITE_APP_URL}/api/v1/fridge/${id}`, config)

            return response.data;

        } catch (error) {

            return thunkAPI.rejectWithValue(error.message);
        }
    }
)

// Get Fridge Details
export const getFridgeDetails = createAsyncThunk(
    'fridge/getFridgeDetails',
    async (id, thunkAPI) => {

        

        const config = {
            headers: {
                'Content-Type': 'application/json',
               
            },
            withCredentials: true
        }
        try {

            const response = await api.get(`${VITE_APP_URL}/api/v1/fridge/${id}`, config)
            console.log("Response: ", response.data)
            return response.data;

        } catch (error) {

            return thunkAPI.rejectWithValue(error.message);
        }
    }
)
// Get Fridge Details
export const openFridge = createAsyncThunk(
    'fridge/openFridge',
    async (id, thunkAPI) => {

        

        const config = {
            headers: {
                'Content-Type': 'application/json',
               
            },
            withCredentials: true
        }
        try {

            const response = await api.get(`${VITE_APP_URL}/api/v1/fridge/open/${id}`, config)
            console.log("Response: ", response.data)
            return response.data;

        } catch (error) {

            return thunkAPI.rejectWithValue(error.message);
        }
    }
)
