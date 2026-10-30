import React, { useState, useEffect } from 'react'
import { Link } from 'react-router-dom';
import {
    Card,
    Typography,
    Button,
} from "@material-tailwind/react";

const Announcement = () => {
    const [IsLargeScreen, setIsLargeScreen] = useState(false);
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
        <Card className="h-[calc(100vh-2rem)] w-full p-4" color="transparent">
            <Typography variant="h2" className="text-primary mb-4">Announcements</Typography>
            <div className="overflow-y-auto gap-2 flex flex-col">
                <div className="max-h-96 w-72 bg-white border border-primary-dark p-4 rounded-lg flex flex-col">
                    <img src="https://plus.unsplash.com/premium_photo-1682090496470-6eec9f5bcc89?q=80&w=2070&auto=format&fit=crop&ixlib=rb-4.0.3&ixid=M3wxMjA3fDB8MHxwaG90by1wYWdlfHx8fGVufDB8fHx8fA%3D%3D" alt="" className="object-cover w-full" />
                    <Typography variant={IsLargeScreen ? "h3" : "h4"} className="mt-2 text-primary">
                        Article title #1
                    </Typography>
                    <Typography variant="small" className="italic">
                        Published on January 15, 2025
                    </Typography>
                    <Typography variant="paragraph" className='overflow-hidden text-ellipsis line-clamp-2 my-2'>
                        Lorem ipsum dolor sit amet consectetur adipisicing elit. Magnam tempore aspernatur soluta fugit quasi corporis perspiciatis ab inventore, beatae voluptas laborum est vitae. Perferendis delectus ea, quae voluptas hic similique. Repellat, aperiam impedit nemo dicta unde illum reiciendis amet nostrum iure quam soluta aspernatur itaque, dignissimos consequuntur! Debitis, velit magnam.
                    </Typography>
                    <Link to="/article/id" className="w-full"><Button className="bg-secondary w-full">See more</Button></Link>
                </div>
                
            </div>
        </Card>
    )
}

export default Announcement