import { createAsyncThunk } from '@reduxjs/toolkit';
import axios from 'axios';
import api from '../../api/axiosInstance'
const VITE_APP_URL = import.meta.env.VITE_APP_URL;

// Create Milk Letting
export const createLetting = createAsyncThunk(
    'letting/createLetting',
    async (req, thunkAPI) => {



        const config = {
            headers: {
                'Content-Type': 'application/json',

            },
            withCredentials: true
        }
        try {

            const response = await api.post(`${VITE_APP_URL}/api/v1/create-letting`, req, config)
            console.log("Create Letting: ", response.data)
            return response.data;

        } catch (error) {
            console.log("Error: ", error)
            return thunkAPI.rejectWithValue(error.message);
        }
    }
)

// Create Milk Letting
export const newPublicDonor = createAsyncThunk(
    'letting/newPublicDonor',
    async (req, thunkAPI) => {



        const config = {
            headers: {
                'Content-Type': 'application/json',

            },
            withCredentials: true
        }
        try {

            const response = await api.post(`${VITE_APP_URL}/api/v1/letting-newDonor`, req, config)
            return response.data;

        } catch (error) {
            console.log("Error: ", error)
            return thunkAPI.rejectWithValue(error.message);
        }
    }
)

// Mark Attendance of donors
export const markAttendance = createAsyncThunk(
    'letting/markAttendance',
    async (req, thunkAPI) => {
        const config = {
            headers: {
                'Content-Type': 'application/json',
            },
            withCredentials: true
        }
        try {

            const response = await api.post(`${VITE_APP_URL}/api/v1/mark-attendance`, req, config)
            console.log("Mark Attendance: ", response.data)
            return response.data;

        } catch (error) {

            return thunkAPI.rejectWithValue(error.message);
        }
    }
)

// Mark Attendance of donors
export const finalizeSession = createAsyncThunk(
    'letting/finalizeSession',
    async (req, thunkAPI) => {
        const config = {
            headers: {
                'Content-Type': 'application/json',

            },
            withCredentials: true
        }
        try {

            const response = await api.post(`${VITE_APP_URL}/api/v1/finalize-session`, req, config)
            console.log("Finalize Session: ", response.data)
            return response.data;

        } catch (error) {

            return thunkAPI.rejectWithValue(error.message);
        }
    }
)

// Get all Milk Letting Event
export const getLettings = createAsyncThunk(
    'letting/getLettings',
    async (query, thunkAPI) => {


        const config = {
            headers: {
                'Content-Type': 'application/json',

            },
            withCredentials: true
        }
        console.log("Config: ", config)
        try {
            let urlString = ''
            if (query) {
                urlString = `${VITE_APP_URL}/api/v1/lettings?search=${query}`
            }
            else {
                urlString = `${VITE_APP_URL}/api/v1/lettings`
            }
            console.log("URL: ", urlString)
            const response = await api.get(urlString, config);
            return response.data;

        } catch (error) {
            console.log("Error: ", error)
            return thunkAPI.rejectWithValue(error.response.data.error);
        }
    }
)

// Get all Milk Letting Event
export const getUpcomingLettings = createAsyncThunk(
    'letting/getUpcomingLettings',
    async (query, thunkAPI) => {


        const config = {
            headers: {
                'Content-Type': 'application/json',

            },
            withCredentials: true
        }
        console.log("Config: ", config)
        try {

            const response = await axios.get(`${VITE_APP_URL}/api/v1/upcoming/lettings`, config);
            return response.data;

        } catch (error) {
            console.log("Error: ", error)
            return thunkAPI.rejectWithValue(error.response.data.error);
        }
    }
)

// Get Letting Details
export const getLettingDetails = createAsyncThunk(
    'letting/getLettingDetails',
    async (id, thunkAPI) => {



        const config = {
            headers: {
                'Content-Type': 'application/json',

            },
            withCredentials: true
        }
        try {

            const response = await api.get(`${VITE_APP_URL}/api/v1/letting/${id}`, config)
            return response.data;

        } catch (error) {

            return thunkAPI.rejectWithValue(error.message);
        }
    }
)

// Delete Milk Letting
export const deleteLetting = createAsyncThunk(
    'letting/deleteLetting',
    async (id, thunkAPI) => {



        const config = {
            headers: {
                'Content-Type': 'application/json',

            },
            withCredentials: true
        }
        try {
            const response = await api.delete(`${VITE_APP_URL}/api/v1/letting/${id}`, config)

            return response.data;

        } catch (error) {

            return thunkAPI.rejectWithValue(error.message);
        }
    }
)

// Update Milk Letting
export const updateLetting = createAsyncThunk(
    'letting/updateLetting',
    async (req, thunkAPI) => {


        console.log("Update Lettings: ", req)

        const config = {
            headers: {
                'Content-Type': 'application/json',

            },
            withCredentials: true
        }
        try {
            const response = await api.put(`${VITE_APP_URL}/api/v1/letting/${req.id}`, req, config)

            return response.data;

        } catch (error) {

            return thunkAPI.rejectWithValue(error.message);
        }
    }
)

export const updateAttendance = createAsyncThunk(
    'letting/updateAttendance',
    async (req, thunkAPI) => {


        console.log("Update Lettings: ", req)

        const config = {
            headers: {
                'Content-Type': 'application/json',

            },
            withCredentials: true
        }
        try {
            const response = await api.put(`${VITE_APP_URL}/api/v1/additional-bags/${req.lettingId}`, req, config)

            return response.data;

        } catch (error) {

            return thunkAPI.rejectWithValue(error.message);
        }
    }
)

// Get all Milk Letting Event
export const getAverageLettingVolume = createAsyncThunk(
    'letting/getAverageLettingVolume',
    async (query, thunkAPI) => {


        const config = {
            headers: {
                'Content-Type': 'application/json',

            },
            withCredentials: true
        }
        console.log("Config: ", config)
        try {
            
            const response = await api.get(`/api/v1/lettings/average`, config);
            return response.data;

        } catch (error) {
            console.log("Error: ", error)
            return thunkAPI.rejectWithValue(error.response.data.error);
        }
    }
)


// Get all Milk Letting Event
export const deleteAttendance = createAsyncThunk(
    'letting/deleteAttendance',
    async ({lettingId, attendanceId}, thunkAPI) => {
        const config = {
            headers: {
                'Content-Type': 'application/json',
            },
            withCredentials: true
        }
        console.log("Config: ", config)
        try {
            
            const response = await api.delete(`/api/v1/lettings/${lettingId}/attendance/${attendanceId}`, config);
            return response.data;

        } catch (error) {
            console.log("Error: ", error)
            return thunkAPI.rejectWithValue(error.response.data.error);
        }
    }
)