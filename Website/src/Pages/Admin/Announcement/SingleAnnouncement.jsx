import React, { useState, useEffect } from 'react'
import StickyNavbar from '../../../Components/Navbar'
import { Typography } from '@material-tailwind/react'
import { useParams } from 'react-router-dom'
import { useDispatch, useSelector } from 'react-redux';
import { getAnnouncementDetails, getAnnouncement } from '../../../redux/actions/announcementActions'
import AnnouncementList from './AnnouncementList'
const SingleAnnouncement = () => {
    const dispatch = useDispatch();
    const { announcements, announcementDetails } = useSelector((state) => state.announcements);
    const { id } = useParams();
    const [IsLargeScreen, setIsLargeScreen] = useState(false);
    const formattedDate = new Date(announcementDetails.createdAt).toLocaleDateString('en-US', {
        weekday: 'short', // "Mon"
        year: 'numeric', // "2025"
        month: 'short', // "Jan"
        day: 'numeric', // "21"
    });

    useEffect(() => {
        dispatch(getAnnouncementDetails(id));
        dispatch(getAnnouncement());
    }, [dispatch, id]);


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
            <StickyNavbar />
            <section
                className="p-4 bg-lightbg"
            >
                <div className="mt-4 p-4 border border-gray-200 rounded">

                    <div className="article-content" dangerouslySetInnerHTML={{ __html: announcementDetails.content }} />
                    <span className="article-content font-parkinsans text-primary italic">Published on {formattedDate}</span>
                    
                </div>

            </section>

            <section className="relative p-4">
                <div className="custom-shape-divider-top-1741406764">
                    <svg data-name="Layer 1" xmlns="http://www.w3.org/2000/svg" viewBox="0 0 1200 120" preserveAspectRatio="none">
                        <path d="M600,112.77C268.63,112.77,0,65.52,0,7.23V120H1200V7.23C1200,65.52,931.37,112.77,600,112.77Z" className="shape-fill"></path>
                    </svg>
                </div>
                <div className="mt-20 ">

                    <Typography variant="h2" className="text-center font-parkinsans">Other Announcements</Typography>
                    <div className="grid md:grid-cols-3 lg:grid-cols-4 xl:grid-cols-6 gap-4">
                        <AnnouncementList announcements={announcements} isLargeScreen={IsLargeScreen} />
                    </div>
                </div>

            </section>
        </>
    )
}

export default SingleAnnouncement