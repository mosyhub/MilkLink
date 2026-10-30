import React from 'react'
import { Outlet } from 'react-router-dom'

const ReportsLayout = () => {
    return (
        <div className="h-[calc(100vh-3rem)] p-4">
            <Outlet />
        </div>
    )
}

export default ReportsLayout