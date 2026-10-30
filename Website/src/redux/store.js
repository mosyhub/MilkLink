// src/store.js
import { configureStore } from '@reduxjs/toolkit';
import userReducer from './slices/userSlice';
import articleReducer from './slices/articleSlice';
import donorReducer from './slices/donorSlice';
import recipientReducer from './slices/recipientSlice';
import eventReducer from './slices/eventSlice';
import inventoryReducer from './slices/inventorySlice';
import fridgeReducer from './slices/fridgeSlice';
import scheduleReducer from './slices/scheduleSlice'
import collectionReducer from './slices/collectionSlice';
import lettingReducer from './slices/lettingSlice';
import bagReducer from './slices/bagSlice';
import requestReducer from './slices/requestSlice';
import notifReducer from './slices/notifSlice';
import metricReducer from './slices/metricSlice';
import announcementReducer from './slices/announcementSlice';
import signReducer from './slices/signSlice';
const store = configureStore({
  reducer: {
    users: userReducer,// Add your reducers here
    articles: articleReducer,
    donors: donorReducer,
    recipients: recipientReducer,
    events: eventReducer,
    inventories: inventoryReducer,
    fridges: fridgeReducer,
    schedules: scheduleReducer,
    collections: collectionReducer,
    lettings: lettingReducer,
    bags: bagReducer,
    requests: requestReducer,
    devices: notifReducer,
    metrics: metricReducer,
    announcements: announcementReducer,
    signs: signReducer
  },
});

export default store;
