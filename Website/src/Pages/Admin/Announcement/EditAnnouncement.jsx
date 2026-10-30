import React, { useEffect, useRef, useState } from "react";
import "react-quill/dist/quill.snow.css";
import { Button, Input, Textarea, Typography } from "@material-tailwind/react"; // Import Textarea component
import { useDispatch, useSelector } from "react-redux";

import Loader from "../../../Components/Loader/Loader";
import { useNavigate, useParams } from "react-router-dom";
import { resetUpdate } from "../../../redux/slices/announcementSlice";
import { getAnnouncementDetails, updateHTMLAnnouncement } from "../../../redux/actions/announcementActions";
import { FilePond, registerPlugin } from 'react-filepond';

import FilePondPluginFileEncode from 'filepond-plugin-file-encode';
import FilePondPluginFileValidateType from 'filepond-plugin-file-validate-type';
import { useBreadcrumb } from "../../../Components/Breadcrumb/BreadcrumbContext";
registerPlugin(FilePondPluginFileEncode, FilePondPluginFileValidateType);

const EditAnnouncement = () => {
    const {setBreadcrumb} = useBreadcrumb();
    const pondRef = useRef(null);
    const { id } = useParams();
    const dispatch = useDispatch();
    const navigate = useNavigate();
    const { loading, isUpdated, announcementDetails } = useSelector((state) => state.announcements);


    const [title, setTitle] = useState("");
    const [description, setDescription] = useState("");
    const [images, setImages] = useState([]);
    const [imagePreview, setImagePreview] = useState([]);



    const handleRemoveImage = (index, isNew) => {
        console.log("Remove:", index, "Is new:", isNew);
        if (isNew) {
            // Remove from new uploads
            setImages(prev => {
                const updated = [...prev];
                updated.splice(index - imagePreview.length, 1);

                // Sync with FilePond instance
                const pond = pondRef.current;
                if (pond) {
                    pond.removeFile(index - imagePreview.length); // Adjust index
                }

                return updated;
            });
        } else {
            // Remove from existing images
            setImagePreview(prev => prev.filter((_, i) => i !== index));
        }
    };
    const handleFilePondUpdate = (fileItems) => {
        const base64Images = fileItems.map(fileItem => {
            const encoded = fileItem.getFileEncodeBase64String?.();
            if (!encoded) return null;

            return {
                local: true,
                url: `data:${fileItem.fileType};base64,${encoded}`
            };
        }).filter(Boolean);

        setImages(base64Images);
    };
    const allImages = [...imagePreview, ...images];
    const onSave = () => {
        const req = {
            title: title,
            description: description,
            id: id,
            images: allImages
        };
        dispatch(updateHTMLAnnouncement(req));
    };

    useEffect(() => {
        if (isUpdated) {
            dispatch(resetUpdate());
            navigate('/dashboard/announcement');
        }
    }, [isUpdated, navigate, dispatch])

    useEffect(() => {
        dispatch(getAnnouncementDetails(id));
    }, [dispatch])

    useEffect(() => {
        if (announcementDetails) {
            console.log("Article Details: ", announcementDetails);
            setTitle(announcementDetails.title);
            setDescription(announcementDetails.description);
            setImagePreview(announcementDetails.images || []);
        }
    }, [announcementDetails])
    useEffect(()=>{
        setBreadcrumb([
            { name: "Dashboard", path: "/dashboard" },
            { name: "Announcement", path: "/dashboard/announcement" },
            { name: "Edit Announcement" }
        ]);
    },[])
    return (
        <div className="p-4 space-y-4">

            <h1 className="text-2xl font-bold">Edit Announcement</h1>

            {/* Title Input */}
            <Input
                label="Announcement Title"
                value={title}
                onChange={(e) => setTitle(e.target.value)}
                className="w-full p-2 border border-gray-300 rounded"
            />

            {/* Description Input */}
            <Textarea
                label="Announcement Description"
                value={description}
                onChange={(e) => setDescription(e.target.value)}
                className="w-full p-2 border border-gray-300 rounded"
                rows={3} // Adjust the number of rows as needed
            />
            <Typography variant="h6" color="blue-gray" className="">
                Upload Image
            </Typography>

            <FilePond
                ref={pondRef}
                allowImagePreview={false}
                allowMultiple={true}
                allowFileEncode={true}
                acceptedFileTypes={["image/png", "image/jpeg", "image/jpg"]}
                onupdatefiles={handleFilePondUpdate}
                labelIdle='Drag & Drop your files or <span class="filepond--label-action">Browse</span>'
            />
            <div className="flex items-center flex-wrap gap-4 mt-4">
                {allImages.map((image, index) => (
                    <div key={image.url} className="relative w-max">
                        <button
                            onClick={() => handleRemoveImage(index, !!image.local)}
                            className="absolute top-1 right-1 bg-red-500 text-white rounded-full w-6 h-6 flex items-center justify-center z-10"
                        >
                            &times;
                        </button>
                        <img src={image.url} alt="preview" className="w-72 h-52 object-cover rounded shadow" />
                    </div>
                ))}
            </div>
          
            {/* Save Button */}
            {loading ? (
                <Loader />
            ) : <Button className="bg-secondary mt-4" size="sm" onClick={onSave}>
                Save Announcement
            </Button>}




        </div>
    );
};

export default EditAnnouncement;
