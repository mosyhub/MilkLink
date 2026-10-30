import { createAsyncThunk } from '@reduxjs/toolkit';
import api from '../../api/axiosInstance'
const VITE_APP_URL = import.meta.env.VITE_APP_URL;

export const getEvents = createAsyncThunk(
    'event/getEvents',
    async (req, thunkAPI) => {
        const config = {
            headers: {
                'Content-Type': 'application/json',
            },
            withCredentials: true
        }
        try {

            const response = await api.get(`${VITE_APP_URL}/api/v1/events`, config)

            return response.data;

        } catch (error) {

            return thunkAPI.rejectWithValue(error.message);
        }
    }
)

export const getUpcomingEvents = createAsyncThunk(
    'event/getUpcomingEvents',
    async (req, thunkAPI) => {
        console.log("Getting upcoming events")

        try {

            const response = await api.get(`${VITE_APP_URL}/api/v1/events/upcoming`, {withCredentials: true})

            return response.data;

        } catch (error) {

            return thunkAPI.rejectWithValue(error.message);
        }
    }
)


export const addEvents = createAsyncThunk(
    'event/addEvents',
    async (req, thunkAPI) => {

       

        const config = {
            headers: {
                'Content-Type': 'application/json',
                
            },
            withCredentials: true
        }
        try {


            const response = await api.post(`${VITE_APP_URL}/api/v1/events`, req, config)

            return response.data;

        } catch (error) {

            return thunkAPI.rejectWithValue(error.message);
        }
    }
)

export const editEvents = createAsyncThunk(
    'event/editEvents',
    async (req, thunkAPI) => {

        

        const config = {
            headers: {
                'Content-Type': 'application/json',
                
            },
            withCredentials: true
        }
        try {
            console.log("Request: ", req)
            const response = await api.put(`${VITE_APP_URL}/api/v1/event/${req.get("id")}`, req, config)

            return response.data;

        } catch (error) {

            return thunkAPI.rejectWithValue(error.message);
        }
    }
)

export const deleteEvents = createAsyncThunk(
    'event/deleteEvents',
    async (id, thunkAPI) => {

        

        const config = {
            headers: {
                'Content-Type': 'application/json',
                
            },
            withCredentials: true
        }
        try {
            const response = await api.delete(`${VITE_APP_URL}/api/v1/event/${id}`, config)

            return response.data;

        } catch (error) {

            return thunkAPI.rejectWithValue(error.message);
        }
    }
)

export const getEventDetails = createAsyncThunk(
    'event/getEventDetails',
    async (id, thunkAPI) => {

        

        const config = {
            headers: {
                'Content-Type': 'application/json',
                
            },
            withCredentials: true
        }
        try {

            const response = await api.get(`${VITE_APP_URL}/api/v1/event/${id}`, config)

            return response.data;

        } catch (error) {

            return thunkAPI.rejectWithValue(error.message);
        }
    }
)