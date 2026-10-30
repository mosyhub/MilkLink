import React from 'react'
import { Outlet } from 'react-router-dom'

const ArchiveLayout = () => {
    return (
        <div className="h-[calc(100vh-3rem)] p-4">
            <Outlet />
        </div>
    )
}

export default ArchiveLayout