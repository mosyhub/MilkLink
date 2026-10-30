import { Typography } from '@material-tailwind/react'
import React from 'react'
import StickyNavbar from '../Components/Navbar'
import blob from '../assets/image/background-blob.svg'
const AboutUs = () => {
    return (
        <>
            <StickyNavbar />
            <div className="grid grid-rows-[1fr_1fr_1fr] items-center justify-items-center min-h-screen p-20 pb-20 gap-16 sm:p-20">
                <div className="flex items-center gap-4 w-full max-w-2xl">
                    <Typography variant="h1">Taguig-Pateros District Hospital Center for Women and Children</Typography>
                    
                </div>
                <div className="flex items-center gap-4 w-full max-w-2xl">
                    <Typography variant="h1">Taguig City Human Milk Bank</Typography>
                </div>
                <div className="flex items-center gap-4 w-full max-w-2xl">
                    <Typography variant="h1">TCHMB Portal's Development Team</Typography>
                </div>
            </div>
        </>
    )
}

export default AboutUs