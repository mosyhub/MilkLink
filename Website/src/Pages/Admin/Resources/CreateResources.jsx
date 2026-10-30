import React, { useEffect, useRef, useState } from "react";
import ReactQuill from "react-quill";
import "react-quill/dist/quill.snow.css";
import { Button, Input, Textarea, Typography } from "@material-tailwind/react"; // Import Textarea component
import { useDispatch, useSelector } from "react-redux";
import { addHTMLArticles } from "../../../redux/actions/articleActions";
import Loader from "../../../Components/Loader/Loader";
import { useNavigate } from "react-router-dom";
import { resetSuccess } from "../../../redux/slices/articleSlice";
import { FilePond, registerPlugin } from 'react-filepond';

import FilePondPluginFileEncode from 'filepond-plugin-file-encode';
import FilePondPluginFileValidateType from 'filepond-plugin-file-validate-type';
import { useBreadcrumb } from "../../../Components/Breadcrumb/BreadcrumbContext";
registerPlugin(FilePondPluginFileEncode, FilePondPluginFileValidateType);
const modules = {
    toolbar: {
        container: [
            [{ header: [1, 2, 3, false] }],
            [{ color: [] }, { background: [] }],
            [{ align: [] }],
            ["bold", "italic", "underline"],
            [{ list: "ordered" }, { list: "bullet" }],
            ["link"],

            [{ indent: "-1" }, { indent: "+1" }],
            ["blockquote"]
        ],
    },
};

const formats = [
    "header",
    "align",
    "bold",
    "italic",
    "underline",
    "list",
    "bullet",
    "link",
    "color",
    "background",
    "indent",
    "blockquote"
];

const CreateResources = () => {
    const { setBreadcrumb } = useBreadcrumb();
    const pondRef = useRef(null);
    const dispatch = useDispatch();
    const navigate = useNavigate();
    const { loading, success } = useSelector((state) => state.articles);

    const [title, setTitle] = useState(""); 
    const [description, setDescription] = useState(""); 
    const [content, setContent] = useState("");
    const [images, setImages] = useState([]);
    const handleRemoveImage = (index) => {
        setImages((prev) => {
            const updated = [...prev];
            updated.splice(index, 1); // Remove image at the given index

            // Sync with FilePond instance
            const pond = pondRef.current;
            if (pond) {
                const file = pond.getFiles()[index];
                if (file) {
                    pond.removeFile(file.id);
                }
            }

            return updated;
        });
    };

    const onSave = () => {
        const imageUrls = images.map(image => image.url);
        const req = {
            title: title,
            description: description,
            content: content,
            images: imageUrls
        };
        dispatch(addHTMLArticles(req));
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

    useEffect(() => {
        if (success) {
            console.log("Success");
            navigate('/dashboard/resources');
            dispatch(resetSuccess());
        }
    }, [success, navigate, dispatch])
    useEffect(()=>{
        setBreadcrumb([
            { name: "Dashboard", path: "/dashboard" },
            { name: "Articles", path: "/dashboard/resources" },
            { name: "Create Article", path: "/dashboard/resources/create" }
        ]);
    },[])
    return (
        <div className="p-4 space-y-4">

            <h1 className="text-2xl font-bold">Create New Article</h1>

            {/* Title Input */}
            <Input
                label="Article Title"
                value={title}
                onChange={(e) => setTitle(e.target.value)}
                className="w-full p-2 border border-gray-300 rounded"
            />

            {/* Description Input */}
            <Textarea
                label="Article Description"
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
                {images.map((image, index) => (
                    <div key={image.url} className="relative w-max">
                        <button
                            onClick={() => handleRemoveImage(index)}
                            className="absolute top-1 right-1 bg-red-500 text-white rounded-full w-6 h-6 flex items-center justify-center z-10"
                        >
                            &times;
                        </button>
                        <img src={image.url} alt="preview" className="w-72 h-52 object-cover rounded shadow" />
                    </div>
                ))}
            </div>
            {/* ReactQuill Editor */}
            <ReactQuill value={content} onChange={setContent} modules={modules} formats={formats} />
            {/* Save Button */}
            {loading ? (
                <Loader />
            ) : <Button className="bg-secondary mt-4" size="sm" onClick={onSave}>
                Save Article
            </Button>}




        </div>
    );
};

export default CreateResources;
