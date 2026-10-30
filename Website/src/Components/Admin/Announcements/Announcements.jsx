import React, { useEffect, useState } from 'react'

import { Chip } from '@material-tailwind/react'
import { useDispatch, useSelector } from 'react-redux'
import { deleteAnnouncement, getAnnouncement } from '../../../redux/actions/announcementActions'
import AnnouncementList from '../../../Pages/Admin/Announcement/AnnouncementList'

const Announcements = () => {
    const dispatch = useDispatch();
    const { announcements } = useSelector((state) => state.announcements);
    useEffect(() => {
        dispatch(getAnnouncement());

    }, [dispatch])
    useEffect(() => {
        if (announcements) {
            console.log("Announcements: ", announcements);
        }
    }, [announcements])
    const [IsLargeScreen, setIsLargeScreen] = useState(false);
    const handleDelete = (id) => {
        dispatch(deleteAnnouncement(id));
    }
    useEffect(() => {

        const handleResize = () => {
            setIsLargeScreen(window.innerWidth >= 768); // Tailwind's md breakpoint is 768px
        };

        // Set initial screen size and add event listener
        handleResize();
        window.addEventListener("resize", handleResize);

        return () => window.removeEventListener("resize", handleResize);
    }, [])
    
    return (
        <>
            <span className="flex items-center w-full mb-4">
                <span className="pr-2 font-dm text-3xl text-primary">Announcements</span>
                <Chip value={announcements?.length} color="pink" className="rounded-full mr-4" />
                <span className="h-px flex-1 bg-black"></span>
            </span>
            <div className="flex flex-col flex-wrap items-center justify-center md:flex-row lg:justify-start gap-4">
                {announcements && announcements.length > 0 ? <AnnouncementList announcements={announcements} IsLargeScreen={IsLargeScreen} handleDelete={handleDelete} /> : <span className="text-gray-500">No Announcements</span>}
            </div>

        </>
    )
}

export default Announcements