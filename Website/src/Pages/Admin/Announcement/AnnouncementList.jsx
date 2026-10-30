import React, { useState, useEffect } from 'react'
import { Typography, Button, Dialog, DialogHeader, DialogBody, DialogFooter, Carousel } from '@material-tailwind/react';
import { EyeIcon } from 'lucide-react';
import PropTypes from 'prop-types';
const AnnouncementList = ({ announcements }) => {
    const [open, setOpen] = useState(false);
    const [selectedAnnouncement, setSelectedAnnouncement] = useState(null);
    const handleOpen = (announcement) => {
        setOpen(!open)
        setSelectedAnnouncement(announcement)
    };
    useEffect(() => {
        if (announcements) {
            console.log(announcements);
        }
    }, [announcements])
    return (
        <>
            {announcements.map(announcement => {
                const formattedDate = new Date(announcement.createdAt).toLocaleDateString('en-US', {
                    weekday: 'short', // "Mon"
                    year: 'numeric', // "2025"
                    month: 'short', // "Jan"
                    day: 'numeric', // "21"
                });
                return (
                    <div key={announcement._id} className="bg-white shadow-lg border border-primary-dark p-4 rounded-lg flex flex-col justify-between w-[300px] h-96">
                        <Carousel className="rounded-xl my-4 bg-gray-400/75 h-max overflow-hidden z-0">
                            {announcement?.images?.map((image, index) => (
                                <div key={image.url} className="relative h-40 w-full">
                                    <img
                                        src={image.url}
                                        alt={`Announcement Image ${index + 1}`}
                                        className="w-1/2 h-full object-cover mx-auto"
                                    />
                                </div>
                            ))}
                        </Carousel>

                        <Typography className="text-primary line-clamp-2 overflow-hidden text-base sm:text-lg md:text-xl mt-2 font-bold">
                            {announcement.title}
                        </Typography>

                        <Typography variant="small" className="italic">
                            Published on {formattedDate}
                        </Typography>

                        <Typography
                            variant="paragraph"
                            className="text-sm my-2 break-words"
                        >
                            {announcement.description}
                        </Typography>

                        <div className="flex justify-end items-center gap-4 mt-auto">
                            <Button size="sm" className="bg-secondary flex items-center justify-center gap-2" onClick={() => handleOpen(announcement)}>
                                <EyeIcon size={20} className="text-white" />
                                <span className="font-sofia font-bold text-white">View</span>
                            </Button>

                        </div>
                    </div>

                )
            })}
            <Dialog open={open} handler={handleOpen} className="bg-white p-6 rounded-lg shadow-lg">
                <DialogHeader className="text-primary font-bold p-0">
                    <Typography variant="h2" className="font-parkinsans">
                        {selectedAnnouncement && selectedAnnouncement.title}
                    </Typography>
                </DialogHeader>
                <DialogBody className="overflow-y-auto max-h-[70vh]">
                    <Carousel className="rounded-xl my-4 bg-gray-400/75 h-max">
                        {selectedAnnouncement?.images?.map((image, index) => (
                            <div key={image.url} className="relative h-96 w-full">
                                <img
                                    src={image.url}
                                    alt={`Article Image ${index + 1}`}
                                    className="w-full h-full object-contain rounded-xl"
                                />
                            </div>
                        ))}
                    </Carousel>
                    <Typography variant="paragraph" className="text-primary">
                        {selectedAnnouncement ? selectedAnnouncement.description : 'No description available.'}
                    </Typography>
                </DialogBody>
                <DialogFooter className="space-x-2">
                    <Button variant="filled" color="blue-gray" onClick={() => setOpen(!open)}>
                        close
                    </Button>
                </DialogFooter>
            </Dialog>
        </>
    )
}
AnnouncementList.propTypes = {
    announcements: PropTypes.array.isRequired
}
export default AnnouncementList