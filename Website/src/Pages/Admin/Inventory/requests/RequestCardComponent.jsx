import React, { useState } from 'react'
import {
    Button,
    Dialog,
    DialogBody,
    Typography,
    Card,
    CardFooter,
    Carousel,
} from "@material-tailwind/react";
import { formatDate } from '../../../../utils/helper';
import PropTypes from 'prop-types';
const RequestCardComponent = ({ request }) => {
    const [open, setOpen] = useState(false);
    const [selectedImage, setSelectedImage] = useState(null);

    const handleOpen = (imgUrl) => {
        setSelectedImage(imgUrl);
        setOpen(true);
    };
    return (
        <Card className="p-4 h-max border-2 shadow-lg w-80 rounded-lg border-l-warning border-l-8">
            <Typography color="black" variant="h3" className="font-varela">Status: {request.status}</Typography>
            <ul>
                <li>Date: {formatDate(request.date, "full")}</li>
                <li>Patient: {request.patient?.name}</li>
                <li>Type: {request.patient?.patientType}</li>
                <li>Requested Volume: {request.volumeRequested.volume} ml</li>
                <li>Days: {request.volumeRequested.days}</li>
                <li>Prescribed by: {request.doctor}</li>
            </ul>
            <Carousel>
                {request.images.map((image) => (
                    <Card
                        key={image.url}
                        className="mt-4 cursor-pointer overflow-hidden transition-opacity hover:opacity-90"
                        onClick={()=> handleOpen(image.url)}
                    >
                        <img src={image.url} alt="prescription" className="w-80 h-40" />
                    </Card>
                ))}
               
            </Carousel>
            <Dialog size="xl" open={open} handler={()=>setOpen(false)}>
                <DialogBody>
                {selectedImage && (
                        <img src={selectedImage} alt="prescription" className="w-full h-[48rem]" />
                    )}
                </DialogBody>
            </Dialog>
            <CardFooter className="p-2 flex justify-between items-center">
                <Button className="bg-secondary" onClick={handleOpen}>Approve</Button>
                <Button className="bg-secondary">Reject</Button>
            </CardFooter>
        </Card>
    )
}
RequestCardComponent.propTypes = {
    request: PropTypes.object
}
export default RequestCardComponent